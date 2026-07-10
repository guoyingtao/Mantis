//
//  CropBoxPullBackCalculator.swift
//  Mantis
//
//  Created by Yingtao Guo on 7/10/26.
//

import UIKit

/**
 Computes the "pull back" applied while the user keeps dragging a crop box
 edge outward after the crop box has reached the content bounds.

 Instead of stopping, the image zooms out (anchored at the edge/corner
 opposite to the dragged one) so more of the image is revealed, until the
 image edge meets the dragged crop box edge — similar to the Photos app.

 The crop region (in image points) is the source of truth:
 - Finger movement is converted into crop region growth at the zoom scale
   captured when the gesture began, so the mapping stays stable and the
   pull back is fully reversible within one gesture.
 - The zoom scale is then whatever is needed to display that region inside
   the available space between the anchored edge and the content bounds.
 - The axis that is not being dragged keeps its crop region length, so its
   crop box length shrinks together with the zoom scale.
 */
enum CropBoxPullBackCalculator {
    struct Input {
        var tappedEdge: CropViewAuxiliaryIndicatorHandleType
        var desiredFrame: CGRect
        var cropOriginFrame: CGRect
        var contentBounds: CGRect
        var imageFrameInView: CGRect
        var startZoomScale: CGFloat
        var currentZoomScale: CGFloat
        var minimumCropBoxSize: CGFloat
    }

    struct Result: Equatable {
        var zoomScale: CGFloat
        var cropBoxFrame: CGRect
    }

    private struct Axis {
        var direction: Int // 1: max edge dragged, -1: min edge dragged, 0: not dragged
        var originMin: CGFloat
        var originMax: CGFloat
        var desiredLength: CGFloat
        var boundsMin: CGFloat
        var boundsMax: CGFloat
        var imageMin: CGFloat
        var imageMax: CGFloat
    }

    private struct AxisPlan {
        var cropRegionLength: CGFloat // in image points
        var zoomCap: CGFloat // pins the dragged edge at the content bounds
        var zoomFloor: CGFloat // protects minimumCropBoxSize
        var availableLength: CGFloat // in view points
    }

    private static let epsilon: CGFloat = 1e-5

    /// Returns nil when no pull back is needed, in which case the regular
    /// crop box update path should be used.
    static func calculate(_ input: Input) -> Result? {
        let origin = input.cropOriginFrame

        guard input.startZoomScale > 0, input.currentZoomScale > 0,
              origin.width > 0, origin.height > 0 else {
            return nil
        }

        let xDirection = horizontalDragDirection(of: input.tappedEdge)
        let yDirection = verticalDragDirection(of: input.tappedEdge)

        guard xDirection != 0 || yDirection != 0 else {
            return nil
        }

        let xAxis = Axis(direction: xDirection,
                         originMin: origin.minX,
                         originMax: origin.maxX,
                         desiredLength: input.desiredFrame.width,
                         boundsMin: input.contentBounds.minX,
                         boundsMax: input.contentBounds.maxX,
                         imageMin: input.imageFrameInView.minX,
                         imageMax: input.imageFrameInView.maxX)
        let yAxis = Axis(direction: yDirection,
                         originMin: origin.minY,
                         originMax: origin.maxY,
                         desiredLength: input.desiredFrame.height,
                         boundsMin: input.contentBounds.minY,
                         boundsMax: input.contentBounds.maxY,
                         imageMin: input.imageFrameInView.minY,
                         imageMax: input.imageFrameInView.maxY)

        guard let xPlan = makeAxisPlan(for: xAxis, with: input),
              let yPlan = makeAxisPlan(for: yAxis, with: input) else {
            return nil
        }

        var zoomScale = min(input.startZoomScale, xPlan.zoomCap, yPlan.zoomCap)
        zoomScale = max(zoomScale, xPlan.zoomFloor, yPlan.zoomFloor)
        zoomScale = min(zoomScale, input.startZoomScale)

        let needsPullBack = zoomScale < input.startZoomScale - epsilon
        let needsRestore = input.currentZoomScale < input.startZoomScale - epsilon

        guard needsPullBack || needsRestore else {
            return nil
        }

        let width = min(xPlan.cropRegionLength * zoomScale, xPlan.availableLength)
        let height = min(yPlan.cropRegionLength * zoomScale, yPlan.availableLength)

        let cropBoxFrame = CGRect(x: anchoredPosition(for: xAxis, length: width),
                                  y: anchoredPosition(for: yAxis, length: height),
                                  width: width,
                                  height: height)

        return Result(zoomScale: zoomScale, cropBoxFrame: cropBoxFrame)
    }

    private static func makeAxisPlan(for axis: Axis, with input: Input) -> AxisPlan? {
        if axis.direction == 0 {
            // The crop region length stays fixed on this axis, so the crop
            // box length shrinks proportionally with the zoom scale
            let regionLength = (axis.originMax - axis.originMin) / input.startZoomScale

            guard regionLength > 0 else {
                return nil
            }

            return AxisPlan(cropRegionLength: regionLength,
                            zoomCap: .greatestFiniteMagnitude,
                            zoomFloor: input.minimumCropBoxSize / regionLength,
                            availableLength: .greatestFiniteMagnitude)
        }

        let desiredLength = max(axis.desiredLength, input.minimumCropBoxSize)
        let availableLength = axis.direction > 0
            ? axis.boundsMax - axis.originMin
            : axis.originMax - axis.boundsMin
        let imageAvailableLength = (axis.direction > 0
            ? axis.imageMax - axis.originMin
            : axis.originMax - axis.imageMin) / input.currentZoomScale

        guard availableLength > 0, imageAvailableLength > 0 else {
            return nil
        }

        let regionLength = min(desiredLength / input.startZoomScale, imageAvailableLength)

        guard regionLength > 0 else {
            return nil
        }

        return AxisPlan(cropRegionLength: regionLength,
                        zoomCap: availableLength / regionLength,
                        zoomFloor: input.minimumCropBoxSize / regionLength,
                        availableLength: availableLength)
    }

    private static func anchoredPosition(for axis: Axis, length: CGFloat) -> CGFloat {
        switch axis.direction {
        case 1:
            return axis.originMin
        case -1:
            return axis.originMax - length
        default:
            return (axis.originMin + axis.originMax - length) / 2
        }
    }

    static func horizontalDragDirection(of tappedEdge: CropViewAuxiliaryIndicatorHandleType) -> Int {
        switch tappedEdge {
        case .right, .topRight, .bottomRight:
            return 1
        case .left, .topLeft, .bottomLeft:
            return -1
        default:
            return 0
        }
    }

    static func verticalDragDirection(of tappedEdge: CropViewAuxiliaryIndicatorHandleType) -> Int {
        switch tappedEdge {
        case .bottom, .bottomLeft, .bottomRight:
            return 1
        case .top, .topLeft, .topRight:
            return -1
        default:
            return 0
        }
    }

    /// The view point of the edge/corner opposite to the dragged one. The
    /// image point under it stays fixed at this view point during pull back.
    static func anchorPoint(for tappedEdge: CropViewAuxiliaryIndicatorHandleType, in frame: CGRect) -> CGPoint {
        let xPosition: CGFloat
        switch horizontalDragDirection(of: tappedEdge) {
        case 1:
            xPosition = frame.minX
        case -1:
            xPosition = frame.maxX
        default:
            xPosition = frame.midX
        }

        let yPosition: CGFloat
        switch verticalDragDirection(of: tappedEdge) {
        case 1:
            yPosition = frame.minY
        case -1:
            yPosition = frame.maxY
        default:
            yPosition = frame.midY
        }

        return CGPoint(x: xPosition, y: yPosition)
    }
}
