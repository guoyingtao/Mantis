//
//  CropAuxiliaryIndicatorView.swift
//  Mantis
//
//  Created by Echo on 10/19/18.
//  Copyright © 2018 Echo. All rights reserved.
//

import UIKit

final class CropAuxiliaryIndicatorView: UIView, CropAuxiliaryIndicatorViewProtocol {
    private var boarderNormalColor = UIColor.white
    private var boarderHintColor = UIColor.white
    private let cornerHandleLength = CGFloat(20.0)
    private let edgeLineHandleLength = CGFloat(30.0)
    private let handleThickness = CGFloat(3.0)
    private let borderThickness = CGFloat(1.0)
    private let hintLineThickness = CGFloat(2.0)

    private var hintLine = UIView()
    private var tappedEdge: CropViewAuxiliaryIndicatorHandleType = .none
    private var gridMainColor = UIColor.white
    private var gridSecondaryColor = UIColor.lightGray
    private var disableCropBoxDeformation = false
    
    var cropBoxHotAreaUnit: CGFloat = 42
    
    var gridHidden = true {
        didSet {
            setNeedsDisplay()
        }
    }

    var gridLineNumberType: GridLineNumberType = .crop
    
    private var borderLine: UIView = UIView()
    private var cornerHandles: [UIView] = []
    private var edgeLineHandles: [UIView] = []
    
    var accessibilityHelperViews: [UIView] = []
    
    override var frame: CGRect {
        didSet {
            if !cornerHandles.isEmpty {
                layoutLines()
                handleIndicatorHandleTouched(with: tappedEdge)
            }
        }
    }
    
    init(frame: CGRect, cropBoxHotAreaUnit: CGFloat, disableCropBoxDeformation: Bool = false) {
        super.init(frame: frame)
        clipsToBounds = false
        backgroundColor = .clear
        self.cropBoxHotAreaUnit = cropBoxHotAreaUnit
        self.disableCropBoxDeformation = disableCropBoxDeformation
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        backgroundColor = .clear
    }
    
    private func createNewLine() -> UIView {
        let view = UIView()
        view.frame = .zero
        view.backgroundColor = .white
        addSubview(view)
        return view
    }
    
    private func setup() {
        borderLine = createNewLine()
        borderLine.layer.backgroundColor = UIColor.clear.cgColor
        borderLine.layer.borderWidth = borderThickness
        borderLine.layer.borderColor = boarderNormalColor.cgColor
        
        for _ in 0..<8 {
            cornerHandles.append(createNewLine())
        }
        
        for _ in 0..<4 {
            edgeLineHandles.append(createNewLine())
        }
        
        hintLine.backgroundColor = boarderHintColor
        
        setupAccessibilityHelperViews()
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        if !cornerHandles.isEmpty {
            layoutLines()
        }
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        var result = false
        
        accessibilityHelperViews.forEach {
            let convertedPoint = $0.convert(point, from: self)
            result = result || $0.point(inside: convertedPoint, with: event)
        }
        
        return result
    }
    
    override func draw(_ rect: CGRect) {
        if !gridHidden {
            let indicatorLineNumber = gridLineNumberType.getIndicatorLineNumber()
            
            for index in 0..<indicatorLineNumber {
                if gridLineNumberType == .rotate && (index + 1) % 3 != 0 {
                    gridSecondaryColor.setStroke()
                } else {
                    gridMainColor.setStroke()
                }
                
                let indicatorLinePath = UIBezierPath()
                indicatorLinePath.lineWidth = 1
                
                let horizontalY = CGFloat(index + 1) * frame.height / CGFloat(indicatorLineNumber + 1)
                indicatorLinePath.move(to: CGPoint(x: 0, y: horizontalY))
                indicatorLinePath.addLine(to: CGPoint(x: frame.width, y: horizontalY))
                
                let horizontalX = CGFloat(index + 1) * frame.width / CGFloat(indicatorLineNumber + 1)
                indicatorLinePath.move(to: CGPoint(x: horizontalX, y: 0))
                indicatorLinePath.addLine(to: CGPoint(x: horizontalX, y: frame.height))
                
                indicatorLinePath.stroke()
            }
        }
    }
    
    private func layoutLines() {
        guard bounds.isEmpty == false else {
            return
        }
        
        layoutOuterLines()
        
        guard !disableCropBoxDeformation else {
            return
        }
        
        layoutCornerHandles()
        layoutEdgeLineHandles()
        layoutAccessibilityHelperViews()
    }
        
    private func layoutOuterLines() {
        borderLine.frame = CGRect(x: -borderThickness,
                                  y: -borderThickness,
                                  width: bounds.width + 2 * borderThickness,
                                  height: bounds.height + 2 * borderThickness)
        borderLine.layer.backgroundColor = UIColor.clear.cgColor
        borderLine.layer.borderWidth = borderThickness
        borderLine.layer.borderColor = boarderNormalColor.cgColor
    }
    
    private func layoutCornerHandles() {
        let topLeftHorizontalLayerFrame = CGRect(x: -handleThickness, y: -handleThickness, width: cornerHandleLength, height: handleThickness)
        let topLeftVerticalLayerFrame = CGRect(x: -handleThickness, y: -handleThickness, width: handleThickness, height: cornerHandleLength)
        
        let horizontalDistanceForHCorner = bounds.width + 2 * handleThickness - cornerHandleLength
        let verticalDistanceForHCorner = bounds.height + handleThickness
        let horizontalDistanceForVCorner = bounds.width + handleThickness
        let verticalDistanceForVCorner = bounds.height + 2 * handleThickness - cornerHandleLength
        
        for (index, line) in cornerHandles.enumerated() {
            guard let lineType = CropAuxiliaryIndicatorView.CornerHandleType(rawValue: index) else {
                continue
            }
            switch lineType {
            case .topLeftHorizontal:
                line.frame = topLeftHorizontalLayerFrame
            case .topLeftVertical:
                line.frame = topLeftVerticalLayerFrame
            case .topRightHorizontal:
                line.frame = topLeftHorizontalLayerFrame.offsetBy(dx: horizontalDistanceForHCorner, dy: 0)
            case .topRightVertical:
                line.frame = topLeftVerticalLayerFrame.offsetBy(dx: horizontalDistanceForVCorner, dy: 0)
            case .bottomRightHorizontal:
                line.frame = topLeftHorizontalLayerFrame.offsetBy(dx: horizontalDistanceForHCorner, dy: verticalDistanceForHCorner)
            case .bottomRightVertical:
                line.frame = topLeftVerticalLayerFrame.offsetBy(dx: horizontalDistanceForVCorner, dy: verticalDistanceForVCorner)
            case .bottomLeftHorizontal:
                line.frame = topLeftHorizontalLayerFrame.offsetBy(dx: 0, dy: verticalDistanceForHCorner)
            case .bottomLeftVertical:
                line.frame = topLeftVerticalLayerFrame.offsetBy(dx: 0, dy: verticalDistanceForVCorner)
            }
        }
    }
    
    private func layoutEdgeLineHandles() {
        for (index, line) in edgeLineHandles.enumerated() {
            guard let lineType = CropAuxiliaryIndicatorView.EdgeLineHandleType(rawValue: index) else {
                continue
            }
            
            switch lineType {
            case .top:
                line.frame = CGRect(x: bounds.width / 2 - edgeLineHandleLength / 2,
                                    y: -handleThickness,
                                    width: edgeLineHandleLength,
                                    height: handleThickness)
            case .right:
                line.frame = CGRect(x: bounds.width,
                                    y: bounds.height / 2 - edgeLineHandleLength / 2,
                                    width: handleThickness,
                                    height: edgeLineHandleLength)
            case .bottom:
                line.frame = CGRect(x: bounds.width / 2 - edgeLineHandleLength / 2,
                                    y: bounds.height,
                                    width: edgeLineHandleLength,
                                    height: handleThickness)
            case .left:
                line.frame = CGRect(x: -handleThickness,
                                    y: bounds.height / 2 - edgeLineHandleLength / 2,
                                    width: handleThickness,
                                    height: edgeLineHandleLength)
            }
        }
    }
            
    func handleIndicatorHandleTouched(with tappedEdge: CropViewAuxiliaryIndicatorHandleType) {
        guard tappedEdge != .none  else {
            return
        }
        
        self.tappedEdge = tappedEdge
        
        gridHidden = false
        gridLineNumberType = .crop
        
        func handleHintLine() {
            guard [.top, .bottom, .left, .right].contains(tappedEdge) else {
                return
            }
            
            if hintLine.superview == nil {
                addSubview(hintLine)
            }
            
            switch tappedEdge {
            case .top:
                hintLine.frame = CGRect(x: borderLine.frame.minX,
                                        y: borderLine.frame.minY,
                                        width: borderLine.frame.width,
                                        height: hintLineThickness)
            case .bottom:
                hintLine.frame = CGRect(x: borderLine.frame.minX,
                                        y: borderLine.frame.maxY - hintLineThickness,
                                        width: borderLine.frame.width,
                                        height: hintLineThickness)
            case .left:
                hintLine.frame = CGRect(x: borderLine.frame.minX,
                                        y: borderLine.frame.minY,
                                        width: hintLineThickness,
                                        height: borderLine.frame.height)
            case .right:
                hintLine.frame = CGRect(x: borderLine.frame.maxX - hintLineThickness,
                                        y: borderLine.frame.minY,
                                        width: hintLineThickness,
                                        height: borderLine.frame.height)
            default:
                break
            }
        }
        
        handleHintLine()
    }
    
    func handleEdgeUntouched() {
        gridHidden = true
        hintLine.removeFromSuperview()
        tappedEdge = .none
    }
}

extension CropAuxiliaryIndicatorView {
    private enum CornerHandleType: Int {
        case topLeftVertical = 0
        case topLeftHorizontal
        case topRightVertical
        case topRightHorizontal
        case bottomRightVertical
        case bottomRightHorizontal
        case bottomLeftVertical
        case bottomLeftHorizontal
    }
    
    private enum EdgeLineHandleType: Int {
        case top = 0
        case right
        case bottom
        case left
    }
}
