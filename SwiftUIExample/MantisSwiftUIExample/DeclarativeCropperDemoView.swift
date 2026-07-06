//
//  DeclarativeCropperDemoView.swift
//  MantisSwiftUIExample
//
//  Demonstrates the Mantis 3.0 declarative SwiftUI API:
//  ImageCropper configured with modifiers, driven by an observable CropSession.
//

import Mantis
import SwiftUI

/// Options for one presentation of the main-line cropper. Presented with
/// `fullScreenCover(item:)` so the cover content is always built from this
/// value — building it from separate @State vars risks the first presentation
/// seeing values from before the button's state writes were committed, and
/// the cropper applies its configuration only once at creation.
struct DeclarativeCropperOptions: Identifiable {
    let id = UUID()
    var cropShapeType: Mantis.CropShapeType = .rect
    var aspectRatio: CropAspectRatio = .free
    var showsRotationControl = true
    var usesSlideDial = false
    var enablesPerspectiveCorrection = false
}

/// The main-line cropper of the example app, built on the declarative API.
/// Shows the built-in Mantis toolbar and maps the feature-list options
/// (crop shape, aspect ratio, rotation control) onto ImageCropper modifiers.
struct DeclarativeCropperView: View {
    @Binding var image: UIImage?

    let options: DeclarativeCropperOptions

    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        makeCropper()
    }

    private func makeCropper() -> ImageCropper {
        var cropper = ImageCropper(image: image ?? UIImage())
            .cropShape(options.cropShapeType)
            .onCrop { result in
                image = result.croppedImage
                presentationMode.wrappedValue.dismiss()
            }
            .onCancel {
                presentationMode.wrappedValue.dismiss()
            }

        // Only apply an explicit ratio when one was requested; shapes like
        // circle already lock the ratio and a .free call would undo that.
        if case .fixed(let ratio) = options.aspectRatio {
            cropper = cropper.aspectRatio(.fixed(ratio))
        }

        if !options.showsRotationControl {
            cropper = cropper.configure { config in
                config.cropViewConfig.showAttachedRotationControlView = false
            }
        }

        if options.usesSlideDial {
            cropper = cropper.configure { config in
                config.cropViewConfig.builtInRotationControlViewType = .slideDial()
            }
        }

        if options.enablesPerspectiveCorrection {
            // Enables the horizontal/vertical skew correction modes; Mantis
            // switches the rotation control to a slide dial with a type
            // selector, matching the UIKit example's setup.
            cropper = cropper.configure { config in
                config.appearanceMode = .system
                config.cropViewConfig.enablePerspectiveCorrection = true
            }
        }

        return cropper
    }
}

/// Demonstrates saving the crop parameters and restoring them later:
/// the `Transformation` delivered by `onCrop` is kept and fed back through
/// `presetTransformationType` the next time the cropper opens, so the user
/// continues from exactly where the last crop left off.
///
/// The transformation is only meaningful for the image it was created from,
/// so this demo always crops the same bundled original.
struct RestorableCropperDemoView: View {
    @Binding var image: UIImage?
    @Binding var savedTransformation: Transformation?

    let originalImage: UIImage

    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        makeCropper()
    }

    private func makeCropper() -> ImageCropper {
        var cropper = ImageCropper(image: originalImage)
            .onCrop { result in
                savedTransformation = result.transformation
                image = result.croppedImage
                presentationMode.wrappedValue.dismiss()
            }
            .onCancel {
                presentationMode.wrappedValue.dismiss()
            }

        if let transformation = savedTransformation {
            cropper = cropper.configure { config in
                config.cropViewConfig.presetTransformationType = .presetInfo(info: transformation)
            }
        }

        return cropper
    }
}

struct DeclarativeCropperDemoView: View {
    @Binding var image: UIImage?

    /// CropSession is an ObservableObject on iOS 15/16 and additionally
    /// supports fine-grained Observation tracking on iOS 17+.
    @StateObject private var session = CropSession()

    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            ImageCropper(image: image ?? UIImage(), session: session)
                .aspectRatio(.free)
                .builtInToolbarVisible(false)
                .onCrop { result in
                    image = result.croppedImage
                    presentationMode.wrappedValue.dismiss()
                }
                .onCancel {
                    presentationMode.wrappedValue.dismiss()
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItemGroup(placement: .navigationBarLeading) {
                        Button {
                            presentationMode.wrappedValue.dismiss()
                        } label: {
                            Image(systemName: "xmark")
                        }
                    }

                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        Button {
                            session.undo()
                        } label: {
                            Image(systemName: "arrow.uturn.backward")
                        }
                        .disabled(!session.canUndo)

                        Button {
                            session.redo()
                        } label: {
                            Image(systemName: "arrow.uturn.forward")
                        }
                        .disabled(!session.canRedo)

                        Button {
                            session.reset()
                        } label: {
                            Image(systemName: "arrow.counterclockwise")
                        }
                        .disabled(!session.isResettable)

                        Menu {
                            Button {
                                session.rotate(.clockwise)
                            } label: {
                                Label("Rotate Right", systemImage: "rotate.right")
                            }

                            Button {
                                session.rotate(.counterClockwise)
                            } label: {
                                Label("Rotate Left", systemImage: "rotate.left")
                            }

                            Button {
                                session.flip(.horizontal)
                            } label: {
                                Label("Flip Horizontally", systemImage: "arrow.left.and.right.righttriangle.left.righttriangle.right")
                            }

                            Button {
                                session.flip(.vertical)
                            } label: {
                                Label("Flip Vertically", systemImage: "arrow.up.and.down.righttriangle.up.righttriangle.down")
                            }

                            Button {
                                session.setAspectRatio(.fixed(16 / 9))
                            } label: {
                                Label("16:9 Ratio", systemImage: "aspectratio")
                            }

                            Button {
                                session.setAspectRatio(.free)
                            } label: {
                                Label("Free Ratio", systemImage: "aspectratio.fill")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }

                        Button {
                            session.crop()
                        } label: {
                            Image(systemName: "checkmark")
                        }
                    }
                }
        }
    }
}
