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
    
    fileprivate var horizontalGridLines: [UIView] = []
    fileprivate var verticalGridLines: [UIView] = []
    fileprivate var borderLine: UIView = UIView()
    fileprivate var corner: [UIView] = []
    fileprivate let borderThickness = CGFloat(1.0)
    
    var displayHorizontalGridLine = true {
        didSet {
            horizontalGridLines.forEach { $0.removeFromSuperview() }
            
            if displayHorizontalGridLine {
                horizontalGridLines = Array(repeating: createNewLine(), count: gridLineNumberType.rawValue)

            } else {
                horizontalGridLines = []
            }
            
            setNeedsDisplay()
        }
    }
    
    var displayVerticalGridLines = true {
        didSet {
            verticalGridLines.forEach { $0.removeFromSuperview() }
            
            if displayVerticalGridLines {
                verticalGridLines = Array(repeating: createNewLine(), count:  gridLineNumberType.rawValue)
            } else {
                verticalGridLines = []
            }
            
            setNeedsDisplay()
        }
    }
    
    override var frame: CGRect {
        didSet {
            if corner.count > 0 {
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
    
    fileprivate func createNewLine() -> UIView {
        let view = UIView()
        view.frame = CGRect.zero
        view.backgroundColor = .white
        addSubview(view)
        return view
    }
    
    fileprivate func setup() {
        gridHidden = false
        
        borderLine = createNewLine()
        borderLine.layer.backgroundColor = UIColor.clear.cgColor
        borderLine.layer.borderWidth = borderThickness
        borderLine.layer.borderColor = UIColor.white.cgColor
        
        for _ in 0..<8 {
            corner.append(createNewLine())
        }
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        if corner.count > 0 {
            layoutLines()
        }
    }
    
    fileprivate func layoutLines() {
        guard bounds.isEmpty == false else {
            return
        }
        
        layoutOuterLines()
        layoutCornerLines()
    }
    
    fileprivate func layoutOuterLines() {
        borderLine.frame = CGRect(x: -borderThickness, y: -borderThickness, width: bounds.width + 2 * borderThickness, height: bounds.height + 2 * borderThickness)
        borderLine.layer.backgroundColor = UIColor.clear.cgColor
        borderLine.layer.borderWidth = borderThickness
        borderLine.layer.borderColor = UIColor.white.cgColor
    }
    
    fileprivate func layoutCornerLines() {
        let borderThickness = CGFloat(3.0)
        
        let topLeftHorizonalLayerFrame = CGRect(x: -borderThickness, y: -borderThickness, width: cropOverLayerCornerWidth, height: borderThickness)
        let topLeftVerticalLayerFrame = CGRect(x: -borderThickness, y: -borderThickness, width: borderThickness, height: cropOverLayerCornerWidth)
                
        let horizontalDistanceForHCorner = bounds.width + 2 * borderThickness - cropOverLayerCornerWidth
        let verticalDistanceForHCorner = bounds.height + borderThickness
        let horizontalDistanceForVCorner = bounds.width + borderThickness
        let veticalDistanceForVCorner = bounds.height + 2 * borderThickness - cropOverLayerCornerWidth
        
        for (i, line) in corner.enumerated() {
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
            horizontalGridLines.forEach { $0.alpha = hidden ? 0 : 1 }
            verticalGridLines.forEach { $0.alpha = hidden ? 0 : 1}
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
