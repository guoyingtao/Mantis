//
//  SunflowerViewController.swift
//  MantisExample
//
//  Created by Yingtao Guo on 6/19/25.
//  Copyright © 2025 Echo. All rights reserved.
//

import UIKit
import Mantis

class DemoViewController: UIViewController {
    var image = UIImage(named: "sunflower.jpg")
    var transformation: Transformation?
    var imagePicker: ImagePicker!
    var cropViewController: CropViewController?
    
    private func createConfigWithPresetTransformation() -> Config {
        var config = Mantis.Config()
        if let transformation = transformation {
            config.cropViewConfig.presetTransformationType = .presetInfo(info: transformation)
        }
        return config
    }
    
    // MARK: - UI Components
    
    private let imageContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.secondarySystemBackground
        return view
    }()
    
    private lazy var croppedImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = image
        return imageView
    }()
    
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = UIColor.systemBackground
        tableView.separatorStyle = .singleLine
        tableView.rowHeight = 50
        return tableView
    }()
    
    // MARK: - Data Source
    private let menuItems = [
        "Normal",
        "Embedded",
        "Transformation",
        "Headless Crop Demo",
        "AlwaysUseOnePresetRatio",
        "Custom View Controller",
        "Custom Toolbar (List)",
        "Custom Toolbar (Buttons)",
        "Clockwise rotation with slide dial",
        "Crop Shapes",
        "Hide Rotation Dial",
        "Dark Background",
        "Light Background",
        "Color Background"
    ]
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker = ImagePicker(presentationController: self, delegate: self)
        setupUI()
        setupConstraints()
        setupTableView()
        loadSunflowerImage()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Select Album",
            style: .plain,
            target: self,
            action: #selector(selectFromAlbumAction)
        )
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    // MARK: - Setup Methods
    private func setupUI() {
        view.backgroundColor = UIColor.systemBackground
        view.addSubview(imageContainerView)
        imageContainerView.addSubview(croppedImageView)
        view.addSubview(tableView)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Container view constraints
            imageContainerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            imageContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imageContainerView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.6),
            
            // Image view inside the container
            croppedImageView.topAnchor.constraint(equalTo: imageContainerView.topAnchor),
            croppedImageView.bottomAnchor.constraint(equalTo: imageContainerView.bottomAnchor),
            croppedImageView.leadingAnchor.constraint(equalTo: imageContainerView.leadingAnchor),
            croppedImageView.trailingAnchor.constraint(equalTo: imageContainerView.trailingAnchor),
            
            // Table view
            tableView.topAnchor.constraint(equalTo: imageContainerView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "MenuCell")
    }
    
    private func loadSunflowerImage() {
        croppedImageView.image = image
    }
    
    // MARK: - Action Methods
    @objc private func selectFromAlbumAction() {
        imagePicker.present(from: view)
    }
    
    @objc private func normalAction() {
        guard let image = image else {
            return
        }
        var config = createConfigWithPresetTransformation()
        config.cropMode = .async
        
        let indicatorFrame = CGRect(origin: .zero, size: config.cropViewConfig.cropActivityIndicatorSize)
        config.cropViewConfig.cropActivityIndicator = CustomWaitingIndicator(frame: indicatorFrame)
        config.cropToolbarConfig.toolbarButtonOptions = [.clockwiseRotate, .reset, .ratio, .autoAdjust, .horizontallyFlip]
        
        if let transformation = transformation {
            config.cropViewConfig.presetTransformationType = .presetInfo(info: transformation)
        }
        
        let cropViewController = Mantis.cropViewController(image: image,
                                                           config: config)
        cropViewController.delegate = self
        
        let navigationController = UINavigationController(rootViewController: cropViewController)
        cropViewController.title = "Demo"
        present(navigationController, animated: true)
    }
    
    @objc private func embeddedAction() {
        guard let image = image else {
            return
        }
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        if let navController = storyboard.instantiateViewController(withIdentifier: "EmbeddedCropViewControllerNav") as? UINavigationController,
           let embeddedCropViewController = navController.viewControllers.first as? EmbeddedCropViewController {
            
            embeddedCropViewController.image = image
            embeddedCropViewController.didGetCroppedImage = { [weak self] image in
                self?.croppedImageView.image = image
                self?.dismiss(animated: true)
            }
            
            self.present(navController, animated: true)
        }
    }
    
    @objc private func transformationAction() {
        guard let image = image else {
            return
        }
        
        var config = Mantis.Config()
        
        let transform = Transformation(offset: CGPoint(x: 169, y: 152),
                                       rotation: -0.46043267846107483,
                                       scale: 2.129973210831677,
                                       isManuallyZoomed: true,
                                       initialMaskFrame: CGRect(x: 14.0, y: 33, width: 402, height: 603),
                                       maskFrame: CGRect(x: 67.90047201716507, y: 14.0, width: 294.19905596566986, height: 641.0),
                                       cropWorkbenchViewBounds: CGRect(x: 169,
                                                                       y: 152,
                                                                       width: 548.380489739444,
                                                                       height: 704.9696330065433),
                                       horizontallyFlipped: true,
                                       verticallyFlipped: false)
        
        config.cropToolbarConfig.toolbarButtonOptions = [.clockwiseRotate, .reset, .ratio, .autoAdjust, .horizontallyFlip]
        config.cropViewConfig.presetTransformationType = .presetInfo(info: transform)
        config.cropViewConfig.builtInRotationControlViewType = .slideDial()
        
        let cropViewController = Mantis.cropViewController(image: image,
                                                           config: config)
        cropViewController.modalPresentationStyle = .fullScreen
        cropViewController.delegate = self
        present(cropViewController, animated: true)
    }
    
    @objc private func headlessCropDemoAction() {
        guard let image = image else {
            return
        }
        
        let config = Mantis.Config()
        cropViewController = Mantis.cropViewController(image: image,
                                                           config: config)
        cropViewController?.delegate = self
        
        let savedCropInfo: CropInfo = (
            translation: CGPoint(x: 84.85873805664153, y: 132.4420855462625),
            rotation: -0.46043267846107483,
            scaleX: -2.3603495751069907,
            scaleY: 2.3603495751069907,
            cropSize: CGSize(width: 334.12934905305406, height: 728.0),
            imageViewSize: CGSize(width: 412.0, height: 618.0),
            cropRegion: CropRegion(
                topLeft: CGPoint(x: 0.5052456597441978, y: 0.11837055989575593),
                topRight: CGPoint(x: 0.19743660955585537, y: 0.22015024333838856),
                bottomLeft: CGPoint(x: 0.8378815525035231, y: 0.5654728356505114),
                bottomRight: CGPoint(x: 0.5300725023151807, y: 0.6672525190931441)
            )
        )
        
        cropViewController?.crop(by: savedCropInfo)
    }
    
    @objc private func alwaysUseOnePresetRatioAction() {
        guard let image = image else {
            return
        }
        
        let config = Mantis.Config()
        
        let cropViewController = Mantis.cropViewController(image: image, config: config)
        cropViewController.delegate = self
        cropViewController.config.presetFixedRatioType = .alwaysUsingOnePresetFixedRatio(ratio: 16.0 / 9.0)
        present(cropViewController, animated: true)
    }
    
    @objc private func customViewControllerAction() {
        guard let image = image else {
            return
        }
        
        var config = Mantis.Config()
        config.cropMode = .async
        config.cropViewConfig.showAttachedRotationControlView = false
        config.showAttachedCropToolbar = false
        let cropViewController: CustomViewController = Mantis.cropViewController(image: image, config: config)
        cropViewController.delegate = self
        
        let navigationController = UINavigationController(rootViewController: cropViewController)
        present(navigationController, animated: true)
    }
    
    @objc private func customToolbarListAction() {
        guard let image = image else {
            return
        }
        var config = Mantis.Config()
        config.cropToolbarConfig = CropToolbarConfig()
        config.cropToolbarConfig.backgroundColor = .red
        config.cropToolbarConfig.foregroundColor = .white
        
        let cropToolbar = CustomizedCropToolbar(frame: .zero)
        
        let cropViewController = Mantis.cropViewController(image: image,
                                                           config: config,
                                                           cropToolbar: cropToolbar)
        cropViewController.modalPresentationStyle = .fullScreen
        cropViewController.delegate = self
        present(cropViewController, animated: true)
    }
    
    @objc private func customToolbarButtonsAction() {
        guard let image = image else {
            return
        }
        var config = Mantis.Config()
        
        config.cropToolbarConfig.heightForVerticalOrientation = 160
        config.cropToolbarConfig.widthForHorizontalOrientation = 80
        
        let cropToolbar = CustomizedCropToolbarWithoutList(frame: .zero)
        
        let cropViewController = Mantis.cropViewController(image: image,
                                                           config: config,
                                                           cropToolbar: cropToolbar)
        cropViewController.modalPresentationStyle = .fullScreen
        cropViewController.delegate = self
        present(cropViewController, animated: true)
    }
    
    @objc private func clockwiseRotationAction() {
        guard let image = image else {
            return
        }
        
        var config = Mantis.Config()
        config.cropToolbarConfig.toolbarButtonOptions = [.clockwiseRotate, .reset, .ratio, .horizontallyFlip, .verticallyFlip]
        config.cropToolbarConfig.backgroundColor = .white
        config.cropToolbarConfig.foregroundColor = .gray
        config.cropToolbarConfig.ratioCandidatesShowType = .alwaysShowRatioList
        config.presetFixedRatioType = .alwaysUsingOnePresetFixedRatio(ratio: 2.0 / 1.0)
        config.cropViewConfig.builtInRotationControlViewType = .slideDial()
        
        let cropViewController = Mantis.cropViewController(image: image,
                                                           config: config)
        cropViewController.modalPresentationStyle = .fullScreen
        cropViewController.delegate = self
        present(cropViewController, animated: true)
    }
    
    @objc private func cropShapesAction() {
        showCropShapeList()
    }
    
    @objc private func hideRotationDialAction() {
        guard let image = image else {
            return
        }
        
        var config = Mantis.Config()
        config.showAttachedCropToolbar = false
        config.cropViewConfig.showAttachedRotationControlView = false
        config.cropViewConfig.minimumZoomScale = 2.0
        config.cropViewConfig.maximumZoomScale = 10.0
        
        let cropToolbar = MyNavigationCropToolbar(frame: .zero)
        let cropViewController = Mantis.cropViewController(image: image, config: config, cropToolbar: cropToolbar)
        cropViewController.delegate = self
        cropViewController.title = "Change Profile Picture"
        let navigationController = UINavigationController(rootViewController: cropViewController)
        
        cropToolbar.cropViewController = cropViewController
        
        present(navigationController, animated: true)
    }
    
    @objc private func darkBackgroundAction() {
        presentWith(backgroundEffect: .dark)
    }
    
    @objc private func lightBackgroundAction() {
        presentWith(backgroundEffect: .light)
    }
    
    @objc private func colorBackgroundAction() {
        guard let image = image else {
            return
        }
        
        var config = Mantis.Config()
        config.cropViewConfig.backgroundColor = .yellow
        let cropViewController = Mantis.cropViewController(image: image,
                                                           config: config)
        cropViewController.modalPresentationStyle = .fullScreen
        cropViewController.delegate = self
        present(cropViewController, animated: true)
    }
    
    // MARK: - Helper Methods
    
    typealias CropShapeItem = (type: Mantis.CropShapeType, title: String)
    
    let cropShapeList: [CropShapeItem] = [
        (.rect, "Rect"),
        (.square, "Square"),
        (.ellipse(), "Ellipse"),
        (.circle(), "Circle"),
        (.polygon(sides: 5), "pentagon"),
        (.polygon(sides: 6), "hexagon"),
        (.roundedRect(radiusToShortSide: 0.1), "Rounded rectangle"),
        (.diamond(), "Diamond"),
        (.heart(), "Heart"),
        (.path(points: [CGPoint(x: 0.5, y: 0),
                        CGPoint(x: 0.6, y: 0.3),
                        CGPoint(x: 1, y: 0.5),
                        CGPoint(x: 0.6, y: 0.8),
                        CGPoint(x: 0.5, y: 1),
                        CGPoint(x: 0.5, y: 0.7),
                        CGPoint(x: 0, y: 0.5)]), "Arbitrary path")
    ]
    
    private func showCropShapeList() {
        guard let image = image else {
            return
        }
        
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        for item in cropShapeList {
            let action = UIAlertAction(title: item.title, style: .default) {[weak self] _ in
                guard let self = self else {return}
                var config = Mantis.Config()
                config.cropViewConfig.cropShapeType = item.type
                config.cropViewConfig.cropBorderWidth = 40
                config.cropViewConfig.cropBorderColor = .red
                
                let cropViewController = Mantis.cropViewController(image: image, config: config)
                cropViewController.modalPresentationStyle = .fullScreen
                cropViewController.delegate = self
                self.present(cropViewController, animated: true)
            }
            actionSheet.addAction(action)
        }
        
        // Handle iPad popover presentation
        if let popover = actionSheet.popoverPresentationController {
            popover.sourceView = self.view
            popover.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        actionSheet.addAction(cancelAction)
        
        present(actionSheet, animated: true)
    }
    
    private func presentWith(backgroundEffect effect: CropMaskVisualEffectType) {
        guard let image = image else {
            return
        }
        
        var config = Mantis.Config()
        config.cropViewConfig.cropMaskVisualEffectType = effect
        let cropViewController = Mantis.cropViewController(image: image,
                                                           config: config)
        cropViewController.modalPresentationStyle = .fullScreen
        cropViewController.delegate = self
        present(cropViewController, animated: true)
    }
    
    private func getActionForIndex(_ index: Int) -> Selector? {
        switch index {
        case 0: return #selector(normalAction)
        case 1: return #selector(embeddedAction)
        case 2: return #selector(transformationAction)
        case 3: return #selector(headlessCropDemoAction)
        case 4: return #selector(alwaysUseOnePresetRatioAction)
        case 5: return #selector(customViewControllerAction)
        case 6: return #selector(customToolbarListAction)
        case 7: return #selector(customToolbarButtonsAction)
        case 8: return #selector(clockwiseRotationAction)
        case 9: return #selector(cropShapesAction)
        case 10: return #selector(hideRotationDialAction)
        case 11: return #selector(darkBackgroundAction)
        case 12: return #selector(lightBackgroundAction)
        case 13: return #selector(colorBackgroundAction)
        default: return nil
        }
    }
}

// MARK: - UITableViewDataSource
extension DemoViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menuItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MenuCell", for: indexPath)
        cell.textLabel?.text = menuItems[indexPath.row]
        cell.textLabel?.textColor = .systemBlue
        cell.textLabel?.textAlignment = .center
        cell.selectionStyle = .default
        cell.textLabel?.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        return cell
    }
}

// MARK: - UITableViewDelegate
extension DemoViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if let action = getActionForIndex(indexPath.row) {
            perform(action)
        }
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.alpha = 0
        UIView.animate(withDuration: 0.3, delay: 0.05 * Double(indexPath.row), options: .curveEaseInOut) {
            cell.alpha = 1
        }
    }
}

extension DemoViewController: CropViewControllerDelegate {
    func cropViewControllerDidCrop(_ cropViewController: CropViewController,
                                   cropped: UIImage,
                                   transformation: Transformation,
                                   cropInfo: CropInfo) {
        print("transformation is \(transformation)")
        print("cropInfo is \(cropInfo)")
        croppedImageView.image = cropped
        self.transformation = transformation
        dismiss(animated: true)
    }
    
    func cropViewControllerDidCancel(_ cropViewController: CropViewController, original: UIImage) {
        dismiss(animated: true)
    }
    
    func cropViewController(_ cropViewController: CropViewController, didBecomeResettable resettable: Bool) {
        print("Is resettable: \(resettable)")
    }
}

// MARK: - ImagePickerDelegate
extension DemoViewController: ImagePickerDelegate {
    func didSelect(image: UIImage?) {
        guard let image = image else { return }
        self.image = image
        croppedImageView.image = image
    }
}
