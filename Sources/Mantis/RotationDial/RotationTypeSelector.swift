//
//  RotationTypeSelector.swift
//  Mantis
//
//  A segmented control that allows users to switch between
//  Straighten, Horizontal Skew, and Vertical Skew modes.
//  Mimics the Apple Photos app rotation mode selector.
//

import UIKit

protocol RotationTypeSelectorDelegate: AnyObject {
    func rotationTypeSelector(_ selector: RotationTypeSelector,
                              didSelectType type: RotationAdjustmentType)
}

final class RotationTypeSelector: UIView {
    weak var delegate: RotationTypeSelectorDelegate?
    
    private(set) var selectedType: RotationAdjustmentType = .straighten
    
    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.alignment = .center
        stack.spacing = 0
        return stack
    }()
    
    private var buttons: [UIButton] = []
    private let indicatorView = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        backgroundColor = .clear
        
        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        for type in RotationAdjustmentType.allCases {
            let button = UIButton(type: .system)
            button.tag = type.rawValue
            button.setTitle(type.localizedTitle, for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .medium)
            button.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
            buttons.append(button)
            stackView.addArrangedSubview(button)
        }
        
        // Add indicator dot below selected item
        addSubview(indicatorView)
        indicatorView.backgroundColor = .white
        indicatorView.layer.cornerRadius = 2
        
        updateButtonAppearance()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateIndicatorPosition(animated: false)
    }
    
    @objc private func buttonTapped(_ sender: UIButton) {
        guard let type = RotationAdjustmentType(rawValue: sender.tag) else { return }
        guard type != selectedType else { return }
        
        selectedType = type
        updateButtonAppearance()
        updateIndicatorPosition(animated: true)
        delegate?.rotationTypeSelector(self, didSelectType: type)
    }
    
    func select(type: RotationAdjustmentType, notify: Bool = true) {
        guard type != selectedType else { return }
        selectedType = type
        updateButtonAppearance()
        updateIndicatorPosition(animated: true)
        if notify {
            delegate?.rotationTypeSelector(self, didSelectType: type)
        }
    }
    
    private func updateButtonAppearance() {
        for button in buttons {
            let isSelected = button.tag == selectedType.rawValue
            button.setTitleColor(isSelected ? .white : .gray, for: .normal)
            button.titleLabel?.font = UIFont.systemFont(
                ofSize: 12,
                weight: isSelected ? .semibold : .regular
            )
        }
    }
    
    private func updateIndicatorPosition(animated: Bool) {
        guard selectedType.rawValue < buttons.count else { return }
        let selectedButton = buttons[selectedType.rawValue]
        
        let indicatorSize: CGFloat = 4
        let targetCenter = CGPoint(
            x: selectedButton.center.x,
            y: bounds.maxY - indicatorSize
        )
        
        indicatorView.bounds = CGRect(x: 0, y: 0, width: indicatorSize, height: indicatorSize)
        
        if animated {
            UIView.animate(withDuration: 0.25) {
                self.indicatorView.center = targetCenter
            }
        } else {
            indicatorView.center = targetCenter
        }
    }
    
    func reset() {
        selectedType = .straighten
        updateButtonAppearance()
        updateIndicatorPosition(animated: false)
    }
}
