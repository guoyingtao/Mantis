//
//  ImageCropper.swift
//  Mantis
//
//  Created by Yingtao Guo on 4/5/25.
//

#if canImport(SwiftUI)
import SwiftUI
#endif

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
/// `
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
    
    @Environment(\.presentationMode) var presentationMode
    
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
                cropInfo: Binding<CropInfo?>) {
        self.config = config
        self._image = image
        self._transformation = transformation
        self._cropInfo = cropInfo
    }
    
    public class Coordinator: CropViewControllerDelegate {
        var parent: ImageCropperView
        
        init(_ parent: ImageCropperView) {
            self.parent = parent
        }
        
        public func cropViewControllerDidCrop(_ cropViewController: Mantis.CropViewController, cropped: UIImage, transformation: Transformation, cropInfo: CropInfo) {
            parent.image = cropped
            parent.transformation = transformation
            parent.cropInfo = cropInfo
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        public func cropViewControllerDidCancel(_ cropViewController: Mantis.CropViewController, original: UIImage) {
            parent.presentationMode.wrappedValue.dismiss()
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
        return cropViewController
    }
    
    public func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // No updates needed as we recreate the view controller when necessary
        // If future requirements allow for dynamic updates without recreation (e.g., changing
        // configuration while preserving crop state), this method would need implementation.
    }
}
