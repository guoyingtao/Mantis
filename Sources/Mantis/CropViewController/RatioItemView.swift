//
//  RatioItemView.swift
//  Mantis
//
//  Created by iBinh on 9/24/20.
//

import UIKit
class RatioItemView: UIView {
    var didGetRatio: ((RatioItemType)->Void) = { _ in }
    var selected = false {
        didSet {            
            UIView.animate(withDuration: 0.2) {
                self.backgroundColor = self.selected ? UIColor.lightGray.withAlphaComponent(0.7) : .black
                self.titleLabel.textColor = self.selected ? .white : .gray
            }
        }
    }

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        let titleSize: CGFloat = (UIDevice.current.userInterfaceIdiom == .pad) ? 20 : 14
        label.font = .systemFont(ofSize: titleSize, weight: .medium)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    var ratio: RatioItemType!
    init(item: RatioItemType) {
        super.init(frame: .zero)
        ratio = item
        setup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        titleLabel.text = ratio.nameV
        addSubview(titleLabel)
        translatesAutoresizingMaskIntoConstraints = false
        titleLabel.topAnchor.constraint(equalTo: topAnchor).isActive = true
        titleLabel.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        titleLabel.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
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
