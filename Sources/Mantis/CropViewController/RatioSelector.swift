//
//  RatioSelector.swift
//  Mantis
//
//  Created by iBinh on 9/27/20.
//

import UIKit

public final class RatioSelector: UIView {    
    var didGetRatio: ((Double) -> Void) = { _ in }
    private var type: RatioType = .vertical
    private var originalRatioH: Double = 0.0
    private var ratios: [RatioItemType] = []
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()

    private let stackView: UIStackView = {
        let view = UIStackView()
        view.alignment = .center
        view.distribution = .equalSpacing
        view.axis = .horizontal
        view.spacing = 10
        view.isLayoutMarginsRelativeArrangement = true
        view.layoutMargins = .init(top: 5, left: 0, bottom: 0, right: 5)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
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
    
    func update(fixedRatioManager: FixedRatioManager?) {
        guard let fixedRatioManager = fixedRatioManager else { return }
        ratios = fixedRatioManager.ratios
        type = fixedRatioManager.type
        originalRatioH = fixedRatioManager.originalRatioH
        
        if let ratioItemViews = stackView.arrangedSubviews as? [RatioItemView] {
            for ratioView in ratioItemViews {
                ratioView.type = type
            }
        }
    }
    
    func reset() {
        if let ratioItemViews = stackView.arrangedSubviews as? [RatioItemView] {
            for ratioView in ratioItemViews {
                ratioView.selected = originalRatioH == ratioView.ratio.ratioH ? true : false
            }
        }
    }
    
    private func addRatioItems() {
        for (index, item) in ratios.enumerated() {
            let itemView = RatioItemView(type: type, item: item)
            itemView.selected = index == 0            
            stackView.addArrangedSubview(itemView)

            itemView.didGetRatio = {[weak self] ratio in
                let ratioValue = (self?.type == .horizontal) ? ratio.ratioH : ratio.ratioV
                self?.didGetRatio(ratioValue)
                
                if let ratioItemViews = self?.stackView.arrangedSubviews as? [RatioItemView] {
                    for ratioView in ratioItemViews {
                        ratioView.selected = ratio.nameH == ratioView.ratio.nameH ? true : false
                    }
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
        stackView.widthAnchor.constraint(greaterThanOrEqualTo: scrollView.widthAnchor).isActive = true
        stackView.heightAnchor.constraint(equalTo: scrollView.heightAnchor).isActive = true
        
        scrollView.contentInset = .init(top: 0, left: 15, bottom: 0, right: 15)

        addRatioItems()
    }
}
