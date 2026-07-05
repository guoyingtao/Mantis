//
//  CropSession.swift
//  Mantis
//
//  Created for Mantis 3.0.
//

import UIKit
#if canImport(Combine)
import Combine
#endif
#if canImport(Observation)
import Observation
#endif

/// Direction for the 90-degree rotations triggered from a ``CropSession``.
public enum RotationDirection: Sendable {
    case clockwise
    case counterClockwise
}

/// Axis for the flips triggered from a ``CropSession``.
public enum FlipDirection: Sendable {
    case horizontal
    case vertical
}

/// Aspect ratio setting for the crop box.
public enum CropAspectRatio: Equatable, Sendable {
    /// The crop box can be freely resized.
    case free
    /// The crop box is locked to `width / height` (e.g. `.fixed(16/9)`).
    case fixed(CGFloat)
}

/// An observable handle to a live crop session.
///
/// Create a session, pass it to ``ImageCropper``, and drive the cropper
/// imperatively while observing its state declaratively:
///
/// ```swift
/// @StateObject private var session = CropSession()
///
/// var body: some View {
///     VStack {
///         ImageCropper(image: image, session: session)
///             .cropShape(.circle)
///             .onCrop { result in croppedImage = result.croppedImage }
///         HStack {
///             Button("Undo") { session.undo() }.disabled(!session.canUndo)
///             Button("Redo") { session.redo() }.disabled(!session.canRedo)
///             Button("Rotate") { session.rotate(.clockwise) }
///             Button("Done") { session.crop() }
///         }
///     }
/// }
/// ```
///
/// On iOS 17 and later the session also participates in the Observation
/// framework, so it can be stored with `@State` and observed with the
/// fine-grained `@Observable` tracking; on earlier systems it behaves as a
/// plain `ObservableObject`. All members must be used from the main thread.
public final class CropSession: ObservableObject {

    weak var cropViewController: CropViewController?

    public init() {}

    // MARK: - Observable state

    private var _canUndo = false
    /// Whether an undo step is available.
    public internal(set) var canUndo: Bool {
        get {
            access(\.canUndo)
            return _canUndo
        }
        set {
            guard newValue != _canUndo else { return }
            objectWillChange.send()
            withMutation(\.canUndo) { _canUndo = newValue }
        }
    }

    private var _canRedo = false
    /// Whether a redo step is available.
    public internal(set) var canRedo: Bool {
        get {
            access(\.canRedo)
            return _canRedo
        }
        set {
            guard newValue != _canRedo else { return }
            objectWillChange.send()
            withMutation(\.canRedo) { _canRedo = newValue }
        }
    }

    private var _isResettable = false
    /// Whether the current state differs from the initial one, i.e. reset would change something.
    public internal(set) var isResettable: Bool {
        get {
            access(\.isResettable)
            return _isResettable
        }
        set {
            guard newValue != _isResettable else { return }
            objectWillChange.send()
            withMutation(\.isResettable) { _isResettable = newValue }
        }
    }

    private var _transformation: Transformation?
    /// The transformation currently applied to the image, updated live as the user pans/zooms/rotates.
    public internal(set) var transformation: Transformation? {
        get {
            access(\.transformation)
            return _transformation
        }
        set {
            guard newValue != _transformation else { return }
            objectWillChange.send()
            withMutation(\.transformation) { _transformation = newValue }
        }
    }

    // MARK: - Actions

    /// Rotates the image by 90 degrees. No-op when the session is not attached to a cropper.
    public func rotate(_ direction: RotationDirection = .clockwise) {
        switch direction {
        case .clockwise:
            cropViewController?.didSelectClockwiseRotate()
        case .counterClockwise:
            cropViewController?.didSelectCounterClockwiseRotate()
        }
    }

    /// Flips the image around the given axis.
    public func flip(_ direction: FlipDirection = .horizontal) {
        switch direction {
        case .horizontal:
            cropViewController?.didSelectHorizontallyFlip()
        case .vertical:
            cropViewController?.didSelectVerticallyFlip()
        }
    }

    /// Performs the crop. The result is delivered through ``ImageCropper/onCrop(_:)``.
    public func crop() {
        cropViewController?.crop()
    }

    /// Reverts the last user adjustment. Requires undo support (enabled automatically
    /// when the session is attached through ``ImageCropper``).
    public func undo() {
        cropViewController?.didSelectUndo()
    }

    /// Re-applies the last undone adjustment.
    public func redo() {
        cropViewController?.didSelectRedo()
    }

    /// Resets all adjustments back to the initial state.
    public func reset() {
        cropViewController?.didSelectReset()
    }

    /// Changes the crop box aspect ratio while the session is running.
    public func setAspectRatio(_ ratio: CropAspectRatio) {
        switch ratio {
        case .free:
            cropViewController?.didSelectFreeRatio()
        case .fixed(let value):
            cropViewController?.didSelectRatio(ratio: Double(value))
        }
    }

    // MARK: - Attachment

    func attach(to cropViewController: CropViewController) {
        self.cropViewController = cropViewController
        canUndo = false
        canRedo = false
        isResettable = false
    }

    // MARK: - iOS 17+ Observation bridging

    // Stored as Any so the class itself stays available on iOS 15/16;
    // ObservationRegistrar is a struct wrapping shared reference storage,
    // so copying it out of the Any box preserves registration state.
    private let registrarBox: Any? = {
#if canImport(Observation)
        if #available(iOS 17.0, macCatalyst 17.0, *) {
            return ObservationRegistrar()
        }
#endif
        return nil
    }()

    private func access<Member>(_ keyPath: KeyPath<CropSession, Member>) {
#if canImport(Observation)
        if #available(iOS 17.0, macCatalyst 17.0, *),
           let registrar = registrarBox as? ObservationRegistrar {
            registrar.access(self, keyPath: keyPath)
        }
#endif
    }

    private func withMutation<Member>(_ keyPath: KeyPath<CropSession, Member>, _ mutation: () -> Void) {
#if canImport(Observation)
        if #available(iOS 17.0, macCatalyst 17.0, *),
           let registrar = registrarBox as? ObservationRegistrar {
            registrar.withMutation(of: self, keyPath: keyPath, mutation)
            return
        }
#endif
        mutation()
    }
}

#if canImport(Observation)
@available(iOS 17.0, macCatalyst 17.0, *)
extension CropSession: Observable {}
#endif
