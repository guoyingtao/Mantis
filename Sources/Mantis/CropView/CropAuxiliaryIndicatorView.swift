//
//  CropAuxiliaryIndicatorView.swift
//  Mantis
//
//  Created by Echo on 10/19/18.
//  Copyright © 2018 Echo. All rights reserved.
//

import UIKit

class CropAuxiliaryIndicatorView: UIView, CropAuxiliaryIndicatorViewProtocol {
    private var boarderNormalColor = UIColor.white
    private var boarderHintColor = UIColor.white
    private let cornerHandleLength = CGFloat(20.0)
    private let edgeLineHandleLength = CGFloat(30.0)
    private let handleThickness = CGFloat(3.0)
    private let borderThickness = CGFloat(1.0)
    private let hineLineThickness = CGFloat(2.0)

    private var hintLine = UIView()
    private var tappedEdge: CropViewOverlayEdge = .none
    private var gridColor = UIColor(white: 0.8, alpha: 1)
    
    var gridHidden = true

    var gridLineNumberType: GridLineNumberType = .crop {
        didSet {
            setupGridLines()
            layoutGridLines()
        }
    }
    
    private var horizontalGridLines: [UIView] = []
    private var verticalGridLines: [UIView] = []
    private var borderLine: UIView = UIView()
    private var cornerHandles: [UIView] = []
    private var edgeLineHandles: [UIView] = []
    
    override var frame: CGRect {
        didSet {
            if !cornerHandles.isEmpty {
                layoutLines()
                handleCornerHandleTouched(with: tappedEdge)
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
            cornerHandles.append(createNewLine())
        }
        
        for _ in 0..<4 {
            edgeLineHandles.append(createNewLine())
        }
        
        setupGridLines()
        hintLine.backgroundColor = boarderHintColor
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        if !cornerHandles.isEmpty {
            layoutLines()
        }
    }
    
    private func layoutLines() {
        guard bounds.isEmpty == false else {
            return
        }
        
        layoutOuterLines()
        layoutCornerHandles()
        layoutEdgeLineHandles()
        layoutGridLines()
        setGridShowStatus()
    }
    
    private func setGridShowStatus() {
        horizontalGridLines.forEach { $0.alpha = gridHidden ? 0 : 1 }
        verticalGridLines.forEach { $0.alpha = gridHidden ? 0 : 1 }
    }
    
    private func layoutGridLines() {
        let helpLineNumber = gridLineNumberType.getHelpLineNumber()
        for index in 0..<helpLineNumber {
            horizontalGridLines[index].frame = CGRect(x: 0,
                                                      y: CGFloat(index + 1) * frame.height / CGFloat(helpLineNumber + 1),
                                                      width: frame.width,
                                                      height: 1)
            verticalGridLines[index].frame = CGRect(x: CGFloat(index + 1) * frame.width / CGFloat(helpLineNumber + 1),
                                                    y: 0,
                                                    width: 1,
                                                    height: frame.height)
        }
    }
    
    private func setupGridLines() {
        setupVerticalGridLines()
        setupHorizontalGridLines()
    }
    
    private func setupHorizontalGridLines() {
        horizontalGridLines.forEach { $0.removeFromSuperview() }
        horizontalGridLines.removeAll()
        for _ in 0..<gridLineNumberType.getHelpLineNumber() {
            let view = createNewLine()
            view.backgroundColor = gridColor
            horizontalGridLines.append(view)
        }
    }
    
    private func setupVerticalGridLines() {
        verticalGridLines.forEach { $0.removeFromSuperview() }
        verticalGridLines.removeAll()
        for _ in 0..<gridLineNumberType.getHelpLineNumber() {
            let view = createNewLine()
            view.backgroundColor = gridColor
            verticalGridLines.append(view)
        }
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
        let topLeftHorizonalLayerFrame = CGRect(x: -handleThickness, y: -handleThickness, width: cornerHandleLength, height: handleThickness)
        let topLeftVerticalLayerFrame = CGRect(x: -handleThickness, y: -handleThickness, width: handleThickness, height: cornerHandleLength)
        
        let horizontalDistanceForHCorner = bounds.width + 2 * handleThickness - cornerHandleLength
        let verticalDistanceForHCorner = bounds.height + handleThickness
        let horizontalDistanceForVCorner = bounds.width + handleThickness
        let veticalDistanceForVCorner = bounds.height + 2 * handleThickness - cornerHandleLength
        
        for (index, line) in cornerHandles.enumerated() {
            let lineType = CropAuxiliaryIndicatorView.CornerHandleType(rawValue: index) ?? .topLeftVertical
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
    
    private func layoutEdgeLineHandles() {
        for (index, line) in edgeLineHandles.enumerated() {
            let lineType = CropAuxiliaryIndicatorView.EdgeLineHandleType(rawValue: index) ?? .top
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
    
    func handleCornerHandleTouched(with tappedEdge: CropViewOverlayEdge) {
        guard tappedEdge != .none  else {
            return
        }
        
        self.tappedEdge = tappedEdge
        
        setGrid(hidden: false, animated: true)
        gridLineNumberType = .crop
        
        if hintLine.superview == nil {
            addSubview(hintLine)
        }
        
        switch tappedEdge {
        case .top:
            hintLine.frame = CGRect(x: borderLine.frame.minX,
                                    y: borderLine.frame.minY,
                                    width: borderLine.frame.width,
                                    height: hineLineThickness)
        case .bottom:
            hintLine.frame = CGRect(x: borderLine.frame.minX,
                                    y: borderLine.frame.maxY - hineLineThickness,
                                    width: borderLine.frame.width,
                                    height: hineLineThickness)
        case .left:
            hintLine.frame = CGRect(x: borderLine.frame.minX,
                                    y: borderLine.frame.minY,
                                    width: hineLineThickness,
                                    height: borderLine.frame.height)
        case .right:
            hintLine.frame = CGRect(x: borderLine.frame.maxX - hineLineThickness,
                                    y: borderLine.frame.minY,
                                    width: hineLineThickness,
                                    height: borderLine.frame.height)
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
