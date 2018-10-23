//
//  CropOverlayView.swift
//  Mantis
//
//  Created by Echo on 10/19/18.
//  Copyright © 2018 Echo. All rights reserved.
//

import UIKit

class CropOverlayView: UIView {
    
    let cropOverLayerCornerWidth = CGFloat(20.0)
    var gridHidden = false
    
    private var gridLineNumberType: GridLineNumberType = .crop
    
    fileprivate var horizontalGridLines: [CALayer] = []
    fileprivate var verticalGridLines: [CALayer] = []
    fileprivate var borderLineLayer: CALayer = CALayer()
    fileprivate var cornerLayers: [CALayer] = []
    
    fileprivate let borderThickness = CGFloat(1.0)
    
    var displayHorizontalGridLine = true {
        didSet {
            horizontalGridLines.forEach { $0.removeFromSuperlayer() }
            
            if displayHorizontalGridLine {
                horizontalGridLines = Array(repeating: createNewLineLayer(), count: gridLineNumberType.rawValue)

            } else {
                horizontalGridLines = []
            }
            
            setNeedsDisplay()
        }
    }
    
    var displayVerticalGridLines = true {
        didSet {
            verticalGridLines.forEach { $0.removeFromSuperlayer() }
            
            if displayVerticalGridLines {
                verticalGridLines = Array(repeating: createNewLineLayer(), count:  gridLineNumberType.rawValue)
            } else {
                verticalGridLines = []
            }
            
            setNeedsDisplay()
        }
    }
    
    override var frame: CGRect {
        didSet {
            if cornerLayers.count > 0 {
                layoutLines()
            }            
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = false
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    fileprivate func createNewLineLayer() -> CALayer {
        let layer = CALayer()
        layer.frame = CGRect.zero
        layer.backgroundColor = UIColor.white.cgColor
        self.layer.addSublayer(layer)
        return layer
    }
    
    fileprivate func setup() {
        gridHidden = false
        
        borderLineLayer = createNewLineLayer()
        borderLineLayer.backgroundColor = UIColor.clear.cgColor
        borderLineLayer.borderWidth = borderThickness
        borderLineLayer.borderColor = UIColor.white.cgColor
        
        for _ in 0..<8 {
            cornerLayers.append(createNewLineLayer())
        }
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        if cornerLayers.count > 0 {
            layoutLines()
        }
    }
    
    fileprivate func layoutLines() {
        guard bounds.isEmpty == false else {
            return
        }
        
        changeLayerWithoutActions {
            layoutOuterLines()
            layoutCornerLines()
        }        
    }
    
    fileprivate func changeLayerWithoutActions(run: ()-> Void ) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        run()
        CATransaction.commit()
    }
    
    fileprivate func layoutOuterLines() {
        borderLineLayer.frame = CGRect(x: -borderThickness, y: -borderThickness, width: bounds.width + 2 * borderThickness, height: bounds.height + 2 * borderThickness)
        borderLineLayer.backgroundColor = UIColor.clear.cgColor
        borderLineLayer.borderWidth = borderThickness
        borderLineLayer.borderColor = UIColor.white.cgColor
    }
    
    fileprivate func layoutCornerLines() {
        let borderThickness = CGFloat(3.0)
        
        let topLeftHorizonalLayerFrame = CGRect(x: -borderThickness, y: -borderThickness, width: cropOverLayerCornerWidth, height: borderThickness)
        let topLeftVerticalLayerFrame = CGRect(x: -borderThickness, y: -borderThickness, width: borderThickness, height: cropOverLayerCornerWidth)
                
        let horizontalDistanceForHCorner = bounds.width + 2 * borderThickness - cropOverLayerCornerWidth
        let verticalDistanceForHCorner = bounds.height + borderThickness
        let horizontalDistanceForVCorner = bounds.width + borderThickness
        let veticalDistanceForVCorner = bounds.height + 2 * borderThickness - cropOverLayerCornerWidth
        
        for (i, line) in cornerLayers.enumerated() {
            let lineType: CornerLineType = CropOverlayView.CornerLineType(rawValue: i) ?? .topLeftVertical
            switch lineType {
            case .topLeftHorizontal:
                line.frame = topLeftHorizonalLayerFrame
            case .topLeftVertical:
                line.frame = topLeftVerticalLayerFrame
            case .topRightHorizontal:
                line.frame = topLeftHorizonalLayerFrame.offsetBy(dx: horizontalDistanceForHCorner, dy: 0)
            case .topRightVertical:
                line.frame = topLeftVerticalLayerFrame.offsetBy(dx: horizontalDistanceForVCorner, dy: 0)
            case .bottomRightHorizontal:
                line.frame = topLeftHorizonalLayerFrame.offsetBy(dx: horizontalDistanceForHCorner, dy: verticalDistanceForHCorner)
            case .bottomRightVertical:
                line.frame = topLeftVerticalLayerFrame.offsetBy(dx: horizontalDistanceForVCorner, dy: veticalDistanceForVCorner)
            case .bottomLeftHorizontal:
                line.frame = topLeftHorizonalLayerFrame.offsetBy(dx: 0, dy: verticalDistanceForHCorner)
            case .bottomLeftVertical:
                line.frame = topLeftVerticalLayerFrame.offsetBy(dx: 0, dy: veticalDistanceForVCorner)
            }
        }
    }
    
    func setGrid(hidden: Bool, animated: Bool = false) {
        gridHidden = hidden
        
        func setGridLinesShowStatus () {
            horizontalGridLines.forEach { $0.opacity = hidden ? 0 : 1 }
            verticalGridLines.forEach { $0.opacity = hidden ? 0 : 1}
        }
        
        if animated {
            let duration = hidden ? 0.35 : 0.2
            UIView.animate(withDuration: duration) {
                setGridLinesShowStatus()
            }
        } else {
            setGridLinesShowStatus()
        }
    }
}

extension CropOverlayView {
    fileprivate enum CornerLineType: Int {
        case topLeftVertical = 0
        case topLeftHorizontal
        case topRightVertical
        case topRightHorizontal
        case bottomRightVertical
        case bottomRightHorizontal
        case bottomLeftVertical
        case bottomLeftHorizontal
    }
    
    fileprivate enum GridLineNumberType: Int {
        case crop = 3
        case rotate = 9
    }
}
