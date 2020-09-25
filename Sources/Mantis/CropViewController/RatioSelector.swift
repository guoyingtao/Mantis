//
//  RatioSelector.swift
//  Mantis
//
//  Created by Echo on 11/3/18.
//  Copyright © 2018 Echo. All rights reserved.
//

import UIKit

enum RatioType {
    case horizontal
    case vertical
}
class RatioSelectorConfig {
    
}
class RatioSelector: UIView {
    
    var didGetRatio: ((Double)->Void) = { _ in }
    private var type: RatioType = .vertical
    private var originalRatioH: Double = 0.0
    private var ratios: [RatioItemType] = []
    
    init(type: RatioType, originalRatioH: Double, ratios: [RatioItemType] = []) {
        super.init(frame: .zero)
        self.type = type
        self.originalRatioH = originalRatioH
        self.ratios = ratios
        setupViews()
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()
    
    let stackView: UIStackView = {
        let view = UIStackView()
        view.alignment = .center
        view.distribution = .fillEqually
        view.axis = .horizontal
        view.spacing = 10
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    func reset() {
        for ratioView in stackView.arrangedSubviews as! [RatioItemView] {
            ratioView.selected = self.originalRatioH == ratioView.ratio.ratioH ? true : false
        }
    }
    func addRatioItems() {
        for (index, item) in ratios.enumerated() {
            let itemView = RatioItemView(item: item)
            itemView.selected = index == 0
            itemView.widthAnchor.constraint(equalToConstant: 70).isActive = true
            itemView.heightAnchor.constraint(equalToConstant: 25).isActive = true
            stackView.addArrangedSubview(itemView)
            
            itemView.didGetRatio = {[weak self] ratio in
                let ratioValue = (self?.type == .horizontal) ? ratio.ratioH : ratio.ratioV
                self?.didGetRatio(ratioValue)
                for ratioView in self?.stackView.arrangedSubviews as! [RatioItemView] {
                    ratioView.selected = ratio.nameH == ratioView.ratio.nameH ? true : false
                }
            }
        }
    }
    
    private func setupViews() {
        translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrollView)
        scrollView.addSubview(stackView)
        
        scrollView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        scrollView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        scrollView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        scrollView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        
        stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor).isActive = true
        stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor).isActive = true
        stackView.topAnchor.constraint(equalTo: scrollView.topAnchor).isActive = true
        stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor).isActive = true
        
        stackView.heightAnchor.constraint(equalTo: scrollView.heightAnchor).isActive = true
        scrollView.contentInset = .init(top: 0, left: 30, bottom: 0, right: 30)
        
        addRatioItems()
    }
}
