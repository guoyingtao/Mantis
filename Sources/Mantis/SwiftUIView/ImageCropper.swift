//  ImageCropper.swift
//  Mantis
//
//  Created by Yingtao Guo on 4/5/25.
//

#if canImport(SwiftUI)
import SwiftUI
#endif

@available(iOS 13.0, *)
public enum CropAction {
    case reset
    case rotateLeft
    case rotateRight
    case crop
    case undo
    case redo
    //    case setAspectRatio(CGFloat)
}

@available(iOS 13.0, *)
public enum CropStatus {
    case succeeded
    case failed
}
@available(iOS 13.0, *)
/// A SwiftUI view that wraps the Mantis image cropping functionality.
///
/// Use this view to present a cropping interface to the user. The cropped image,
/// transformation, and crop information will be returned through bindings.
///
/// - Important: Requires importing the Mantis framework.
///
/// ### Example
/// ```swift
/// @State private var image: UIImage?
/// @State private var transformation: Transformation?
/// @State private var cropInfo: CropInfo?
///
/// var body: some View {
///     ImageCropperView(
///         image: $image,
///         transformation: $transformation,
///         cropInfo: $cropInfo
///     )
/// }
/// ```
/// This view handles the `cropViewControllerDidCrop` and `cropViewControllerDidCancel` delegate methods
/// of `Mantis.CropViewController`. These methods are implemented by default in the `Coordinator`.
///
/// If you need to handle more delegate methods (e.g., `cropViewControllerDidBeginResize`,
/// `cropViewControllerDidImageTransformed`, etc.), you will need to implement your own `UIViewControllerRepresentable`
/// and `Coordinator` to manage those delegate methods.
///

public struct ImageCropperView: UIViewControllerRepresentable {
    let config: Mantis.Config
    
    @Binding var image: UIImage?
    @Binding var transformation: Transformation?
    @Binding var cropInfo: CropInfo?
    @Binding var action: CropAction?
    
    let onDismiss: () -> Void
    let onCropCompleted: (_ status: CropStatus) -> Void
    
    /// Creates an `ImageCropper` view with optional custom configuration and required image bindings.
    ///
    /// - Parameters:
    ///   - config: An optional `Mantis.Config` object to customize the cropping behavior. Defaults to `.init()`.
    ///   - image: A binding to the original image to be cropped.
    ///   - transformation: A binding to receive the transformation (rotation, scaling, etc.) applied to the image.
    ///   - cropInfo: A binding to receive information about the selected crop area.
    public init(config: Mantis.Config = Mantis.Config(),
                image: Binding<UIImage?>,
                transformation: Binding<Transformation?>,
                cropInfo: Binding<CropInfo?>,
                action: Binding<CropAction?> = .constant(nil),
                onDismiss: @escaping () -> Void = {},
                onCropCompleted: @escaping (_ status: CropStatus) -> Void = { _  in}) {
        self.config = config
        _image = image
        _transformation = transformation
        _cropInfo = cropInfo
        _action = action
        self.onDismiss = onDismiss
        self.onCropCompleted = onCropCompleted
    }
    
    public class Coordinator: CropViewControllerDelegate {
        var parent: ImageCropperView
        var cropViewController: Mantis.CropViewController?
        
        var actionBinding: Binding<CropAction?>
        
        private var isProcessingAction = false
        private var lastProcessedAction: CropAction?
        
        init(_ parent: ImageCropperView) {
            self.parent = parent
            actionBinding = parent._action
        }
        
        @MainActor
        public func cropViewControllerDidCrop(_ cropViewController: Mantis.CropViewController, cropped: UIImage, transformation: Transformation, cropInfo: CropInfo) {
            parent.image = cropped
            parent.transformation = transformation
            parent.cropInfo = cropInfo
            
            isProcessingAction = false
            lastProcessedAction = nil

            parent.onDismiss()
            parent.onCropCompleted(.succeeded)
        }
        
        @MainActor
        public func cropViewControllerDidCancel(_ cropViewController: Mantis.CropViewController, original: UIImage) {
            parent.onDismiss()
        }
        
        @MainActor
        public func cropViewControllerDidFailToCrop(_ cropViewController: Mantis.CropViewController, original: UIImage) {
            isProcessingAction = false
            lastProcessedAction = nil
            parent.onDismiss()
            parent.onCropCompleted(.failed)
        }
        
        @MainActor
        func handleAction() {
            guard !isProcessingAction else { return }
            
            guard let cropVC = cropViewController else { return }
            
            guard let currentAction = actionBinding.wrappedValue else { return }
            
            if let lastAction = lastProcessedAction, areActionsEqual(lastAction, currentAction) {
                return
            }
            
            isProcessingAction = true
            lastProcessedAction = currentAction
            
            switch currentAction {
            case .crop:
                cropVC.crop()
                actionBinding.wrappedValue = nil
                // Let delegate callbacks handle state cleanup for `.crop`.
                return
            case .reset:
                cropVC.didSelectReset()
            case .rotateLeft:
                cropVC.didSelectCounterClockwiseRotate()
            case .rotateRight:
                cropVC.didSelectClockwiseRotate()
            case .undo:
                cropVC.didSelectUndo()
            case .redo:
                cropVC.didSelectRedo()
            }
            
            isProcessingAction = false
            lastProcessedAction = nil
            actionBinding.wrappedValue = nil
        }
        
        private func areActionsEqual(_ lhs: CropAction, _ rhs: CropAction) -> Bool {
            switch (lhs, rhs) {
            case (.crop, .crop):
                return true
            default:
                return false
            }
        }
        
        func updateParent(_ newParent: ImageCropperView) {
            parent = newParent
            actionBinding = newParent._action
        }
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    public func makeUIViewController(context: Context) -> UIViewController {
        guard let imageToEdit = image else {
            // Return an appropriate fallback view controller or handle the nil case
            let emptyVC = UIViewController()
            // Optionally add a label explaining the error
            let label = UILabel()
            label.text = "No image provided for cropping"
            label.textAlignment = .center
            emptyVC.view.addSubview(label)
            label.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                label.centerXAnchor.constraint(equalTo: emptyVC.view.centerXAnchor),
                label.centerYAnchor.constraint(equalTo: emptyVC.view.centerYAnchor)
            ])
            return emptyVC
        }
        
        let cropViewController = Mantis.cropViewController(
            image: imageToEdit,
            config: config
        )
        cropViewController.delegate = context.coordinator
        context.coordinator.cropViewController = cropViewController
        
        return cropViewController
    }
    
    public func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        context.coordinator.updateParent(self)
        context.coordinator.handleAction()
    }
}

