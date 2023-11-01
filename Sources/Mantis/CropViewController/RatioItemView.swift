//
//  RatioItemView.swift
//  Mantis
//
//  Created by iBinh on 9/27/20.
//

import UIKit

final class RatioItemView: UIView {
    var didGetRatio: ((RatioItemType) -> Void) = { _ in }
    
    var selected = false {
        didSet {
            UIView.animate(withDuration: 0.2) {
                self.backgroundColor = self.selected ? UIColor.lightGray.withAlphaComponent(0.7) : .black
                self.titleLabel.textColor = self.selected ? .white : .gray
            }
        }
    }
    
    private lazy var titleLabel: PaddingLabel = {
        let label = PaddingLabel()
        label.textAlignment = .center
        let titleSize: CGFloat = (UIDevice.current.userInterfaceIdiom == .pad) ? 20 : 14
        label.font = .systemFont(ofSize: titleSize, weight: .medium)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    var ratio: RatioItemType!
    
    var type: RatioType! {
        didSet {
            titleLabel.text = type == .vertical ? ratio.nameV : ratio.nameH
        }
    }
    
    init(type: RatioType, item: RatioItemType) {
        super.init(frame: .zero)
        self.ratio = item
        self.type = type
        translatesAutoresizingMaskIntoConstraints = false
        setup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        titleLabel.text = type == .vertical ? ratio.nameV : ratio.nameH
        addSubview(titleLabel)
        titleLabel.topAnchor.constraint(equalTo: topAnchor).isActive = true
        titleLabel.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        titleLabel.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        let gesture = UITapGestureRecognizer(target: self, action: #selector(tap))
        addGestureRecognizer(gesture)
        
        layer.cornerRadius = 10
        clipsToBounds = true
        
    }
    
    @objc private func tap() {
        selected = !selected
        self.didGetRatio(ratio)
    }
}

private class PaddingLabel: UILabel {
    var topInset: CGFloat = 4.0
    var bottomInset: CGFloat = 4.0
    var leftInset: CGFloat = 10.0
    var rightInset: CGFloat = 10.0
    
    override func drawText(in rect: CGRect) {
        let insets = UIEdgeInsets(top: topInset, left: leftInset, bottom: bottomInset, right: rightInset)
        super.drawText(in: rect.inset(by: insets))
    }
    
    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + leftInset + rightInset,
                      height: size.height + topInset + bottomInset)
    }
    
    override var bounds: CGRect {
        didSet {
            // ensures this works within stack views if multi-line
            preferredMaxLayoutWidth = bounds.width - (leftInset + rightInset)
        }
    }
}
