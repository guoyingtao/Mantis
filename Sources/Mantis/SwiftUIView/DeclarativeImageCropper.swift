//
//  DeclarativeImageCropper.swift
//  Mantis
//
//  Created for Mantis 3.0.
//

#if canImport(SwiftUI)
import SwiftUI

/// The output of a successful crop performed through ``ImageCropper``.
public struct CropResult {
    public let croppedImage: UIImage
    public let transformation: Transformation
    public let cropInfo: CropInfo
}

/// A declarative SwiftUI cropper.
///
/// ```swift
/// ImageCropper(image: image)
///     .cropShape(.circle)
///     .aspectRatio(.fixed(16/9))
///     .onCrop { result in
///         croppedImage = result.croppedImage
///     }
/// ```
///
/// Pass a ``CropSession`` to drive the cropper from your own controls
/// (`session.rotate()`, `session.crop()`, ...) and to observe `canUndo`,
/// `canRedo`, `isResettable` and the live `transformation`.
///
/// - Important: The configuration produced by the modifiers is applied once,
///   when the underlying crop view controller is created; changing modifier
///   values on later view updates has no effect. Use
///   ``CropSession/setAspectRatio(_:)`` to change the ratio at runtime.
///   The `image` is the exception: passing a different image instance updates
///   the running cropper in place.
public struct ImageCropper: View {
    private let image: UIImage
    private let session: CropSession?

    private(set) var config: Mantis.Config
    private var onCropHandler: ((CropResult) -> Void)?
    private var onCancelHandler: (() -> Void)?
    private var onCropFailedHandler: ((UIImage) -> Void)?

    /// Creates a cropper for `image`.
    ///
    /// - Parameters:
    ///   - image: The image to crop.
    ///   - session: An optional ``CropSession`` used to control the cropper and
    ///     observe its state. Attaching a session enables undo/redo support.
    ///   - config: An optional base configuration; the declarative modifiers are
    ///     applied on top of it.
    public init(image: UIImage, session: CropSession? = nil, config: Mantis.Config = Mantis.Config()) {
        self.image = image
        self.session = session
        self.config = config
    }

    public var body: some View {
        var resolvedConfig = config
        if session != nil {
            // Undo/redo state is part of the session contract.
            resolvedConfig.enableUndoRedo = true
        }
        return ImageCropperBridge(image: image,
                                  config: resolvedConfig,
                                  session: session,
                                  onCrop: onCropHandler,
                                  onCancel: onCancelHandler,
                                  onCropFailed: onCropFailedHandler)
    }

    // MARK: - Modifiers

    /// Sets the crop shape, e.g. `.circle`, `.square` or `.roundedRect(radiusToShortSide: 0.1)`.
    public func cropShape(_ shape: CropShapeType) -> ImageCropper {
        var copy = self
        copy.config.cropViewConfig.cropShapeType = shape
        switch shape {
        case .circle, .square, .heart:
            copy.config.presetFixedRatioType = .alwaysUsingOnePresetFixedRatio(ratio: 1)
        default:
            break
        }
        return copy
    }

    /// Sets the crop box aspect ratio: `.free` or `.fixed(16/9)`.
    public func aspectRatio(_ ratio: CropAspectRatio) -> ImageCropper {
        var copy = self
        switch ratio {
        case .free:
            copy.config.presetFixedRatioType = .canUseMultiplePresetFixedRatio()
        case .fixed(let value):
            copy.config.presetFixedRatioType = .alwaysUsingOnePresetFixedRatio(ratio: Double(value))
        }
        return copy
    }

    /// Shows or hides Mantis's built-in crop toolbar. Hide it when you build
    /// your own controls on top of a ``CropSession``.
    public func builtInToolbarVisible(_ visible: Bool) -> ImageCropper {
        var copy = self
        copy.config.showAttachedCropToolbar = visible
        return copy
    }

    /// Sets the appearance (`.forceDark`, `.forceLight` or `.system`).
    public func appearance(_ mode: AppearanceMode) -> ImageCropper {
        var copy = self
        copy.config.appearanceMode = mode
        return copy
    }

    /// Escape hatch for settings without a dedicated modifier.
    public func configure(_ transform: (inout Mantis.Config) -> Void) -> ImageCropper {
        var copy = self
        transform(&copy.config)
        return copy
    }

    /// Called with the cropped image after ``CropSession/crop()`` or the
    /// built-in toolbar's crop button succeeds.
    public func onCrop(_ handler: @escaping (CropResult) -> Void) -> ImageCropper {
        var copy = self
        copy.onCropHandler = handler
        return copy
    }

    /// Called when the user cancels from the built-in toolbar.
    public func onCancel(_ handler: @escaping () -> Void) -> ImageCropper {
        var copy = self
        copy.onCancelHandler = handler
        return copy
    }

    /// Called with the original image when cropping fails.
    public func onCropFailed(_ handler: @escaping (UIImage) -> Void) -> ImageCropper {
        var copy = self
        copy.onCropFailedHandler = handler
        return copy
    }
}

// MARK: - UIKit bridge

private struct ImageCropperBridge: UIViewControllerRepresentable {
    let image: UIImage
    let config: Mantis.Config
    let session: CropSession?

    let onCrop: ((CropResult) -> Void)?
    let onCancel: (() -> Void)?
    let onCropFailed: ((UIImage) -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> CropViewController {
        let cropViewController = Mantis.cropViewController(image: image, config: config)
        cropViewController.delegate = context.coordinator
        context.coordinator.appliedImage = image
        session?.attach(to: cropViewController)
        return cropViewController
    }

    func updateUIViewController(_ uiViewController: CropViewController, context: Context) {
        // The configuration is applied once in makeUIViewController; only the
        // callbacks and the image track the latest view value.
        context.coordinator.parent = self
        if context.coordinator.appliedImage !== image {
            context.coordinator.appliedImage = image
            uiViewController.update(image)
        }
    }

    final class Coordinator: CropViewControllerDelegate {
        var parent: ImageCropperBridge
        var appliedImage: UIImage?

        init(_ parent: ImageCropperBridge) {
            self.parent = parent
        }

        func cropViewControllerDidCrop(_ cropViewController: CropViewController,
                                       cropped: UIImage,
                                       transformation: Transformation,
                                       cropInfo: CropInfo) {
            parent.session?.transformation = transformation
            parent.onCrop?(CropResult(croppedImage: cropped,
                                      transformation: transformation,
                                      cropInfo: cropInfo))
        }

        func cropViewControllerDidFailToCrop(_ cropViewController: CropViewController, original: UIImage) {
            parent.onCropFailed?(original)
        }

        func cropViewControllerDidCancel(_ cropViewController: CropViewController, original: UIImage) {
            parent.onCancel?()
        }

        func cropViewControllerDidImageTransformed(_ cropViewController: CropViewController, transformation: Transformation) {
            parent.session?.transformation = transformation
        }

        func cropViewController(_ cropViewController: CropViewController, didBecomeResettable resettable: Bool) {
            parent.session?.isResettable = resettable
        }

        func cropViewController(_ cropViewController: CropViewController, didUpdateEnableStateForUndo enable: Bool) {
            parent.session?.canUndo = enable
        }

        func cropViewController(_ cropViewController: CropViewController, didUpdateEnableStateForRedo enable: Bool) {
            parent.session?.canRedo = enable
        }
    }
}

// MARK: - Bare-case shape conveniences

// Let call sites write `.cropShape(.circle)` instead of `.circle()` for the
// cases whose associated values all have defaults.
public extension CropShapeType {
    static var circle: CropShapeType { .circle() }
    static var ellipse: CropShapeType { .ellipse() }
    static var diamond: CropShapeType { .diamond() }
    static var heart: CropShapeType { .heart() }
}
#endif
