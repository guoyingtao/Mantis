//
//  CropOverlayView.swift
//  Mantis
//
//  Created by Echo on 10/19/18.
//  Copyright © 2018 Echo. All rights reserved.
//

import UIKit

class CropOverlayView: UIView {
    private var boarderNormalColor = UIColor.white
    private var boarderHintColor = UIColor.white
    private var hintLine = UIView()
    private var tappedEdge: CropViewOverlayEdge = .none
    
    var gridHidden = true
    var gridColor = UIColor(white: 0.8, alpha: 1)
    
    private let cropOverLayerCornerWidth = CGFloat(20.0)
    
    var gridLineNumberType: GridLineNumberType = .crop {
        didSet {
            setupGridLines()
            layoutGridLines()
        }
    }
    private var horizontalGridLines: [UIView] = []
    private var verticalGridLines: [UIView] = []
    private var borderLine: UIView = UIView()
    private var corner: [UIView] = []
    private let borderThickness = CGFloat(1.0)
    private let hineLineThickness = CGFloat(2.0)
    
    override var frame: CGRect {
        didSet {
            if corner.count > 0 {
                layoutLines()
                handleEdgeTouched(with: tappedEdge)
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
    
    private func createNewLine() -> UIView {
        let view = UIView()
        view.frame = CGRect.zero
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
            corner.append(createNewLine())
        }
        
        setupGridLines()
        hintLine.backgroundColor = boarderHintColor
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        if corner.count > 0 {
            layoutLines()
        }
    }
    
    private func layoutLines() {
        guard bounds.isEmpty == false else {
            return
        }
        
        layoutOuterLines()
        layoutCornerLines()
        layoutGridLines()
        setGridShowStatus()
    }
    
    private func setGridShowStatus() {
        horizontalGridLines.forEach{ $0.alpha = gridHidden ? 0 : 1}
        verticalGridLines.forEach{ $0.alpha = gridHidden ? 0 : 1}
    }
    
    private func layoutGridLines() {
        for i in 0..<gridLineNumberType.rawValue {
            horizontalGridLines[i].frame = CGRect(x: 0, y: CGFloat(i + 1) * frame.height / CGFloat(gridLineNumberType.rawValue + 1), width: frame.width, height: 1)
            verticalGridLines[i].frame = CGRect(x: CGFloat(i + 1) * frame.width / CGFloat(gridLineNumberType.rawValue + 1), y: 0, width: 1, height: frame.height)
        }
    }
    
    private func setupGridLines() {
        setupVerticalGridLines()
        setupHorizontalGridLines()
    }
    
    private func setupHorizontalGridLines() {
        horizontalGridLines.forEach { $0.removeFromSuperview() }
        horizontalGridLines.removeAll()
        for _ in 0..<gridLineNumberType.rawValue {
            let view = createNewLine()
            view.backgroundColor = gridColor
            horizontalGridLines.append(view)
        }
    }
    
    private func setupVerticalGridLines() {
        verticalGridLines.forEach { $0.removeFromSuperview() }
        verticalGridLines.removeAll()
        for _ in 0..<gridLineNumberType.rawValue {
            let view = createNewLine()
            view.backgroundColor = gridColor
            verticalGridLines.append(view)
        }
    }
    
    private func layoutOuterLines() {
        borderLine.frame = CGRect(x: -borderThickness, y: -borderThickness, width: bounds.width + 2 * borderThickness, height: bounds.height + 2 * borderThickness)
        borderLine.layer.backgroundColor = UIColor.clear.cgColor
        borderLine.layer.borderWidth = borderThickness
        borderLine.layer.borderColor = boarderNormalColor.cgColor
    }
    
    private func layoutCornerLines() {
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
        self.gridHidden = hidden
        
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
    
    func hideGrid() {
        gridLineNumberType = .none
    }
    
    func handleEdgeTouched(with tappedEdge: CropViewOverlayEdge) {
        guard tappedEdge != .none  else {
            return
        }
        
        self.tappedEdge = tappedEdge
        
        setGrid(hidden: false, animated: true)
        gridLineNumberType = .crop
        
        if (hintLine.superview == nil) {
            addSubview(hintLine)
        }
        
        switch tappedEdge {
        case .top:
            hintLine.frame = CGRect(x: borderLine.frame.minX, y: borderLine.frame.minY, width: borderLine.frame.width, height: hineLineThickness)
        case .bottom:
            hintLine.frame = CGRect(x: borderLine.frame.minX, y: borderLine.frame.maxY - hineLineThickness, width: borderLine.frame.width, height: hineLineThickness)
        case .left:
            hintLine.frame = CGRect(x: borderLine.frame.minX, y: borderLine.frame.minY, width: hineLineThickness, height: borderLine.frame.height)
        case .right:
            hintLine.frame = CGRect(x: borderLine.frame.maxX - hineLineThickness, y: borderLine.frame.minY, width: hineLineThickness, height: borderLine.frame.height)
        default:
            hintLine.removeFromSuperview()
        }        
    }
    
    func handleEdgeUntouched() {
        setGrid(hidden: true, animated: true)
        hintLine.removeFromSuperview()
        tappedEdge = .none
    }
}

extension CropOverlayView {
    private enum CornerLineType: Int {
        case topLeftVertical = 0
        case topLeftHorizontal
        case topRightVertical
        case topRightHorizontal
        case bottomRightVertical
        case bottomRightHorizontal
        case bottomLeftVertical
        case bottomLeftHorizontal
    }
    
    enum GridLineNumberType: Int {
        case none = 0
        case crop = 2
        case rotate = 8
    }
}
