//
//  ImageCropperWrapper.swift
//  MantisSwiftUIExample
//
//  Created by Yingtao Guo on 2/16/23.
//

import Mantis
import SwiftUI

/**
 * Demonstrates the legacy binding-based API (`ImageCropperView` driven by a
 * `CropAction` binding), kept as a migration reference for Mantis 2.x users.
 *
 * New code should prefer the declarative `ImageCropper` + `CropSession` API;
 * see DeclarativeCropperDemoView for the equivalent of this screen.
 */
struct ImageCropperWrapper: View {
    @Binding var image: UIImage?
    @Binding var transformation: Transformation?
    @State private var action: CropAction?

    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            makeImageCropperWithoutAttachedToolbar()
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItemGroup(placement: .navigationBarLeading) {
                        Button(
                            action: {
                                presentationMode.wrappedValue.dismiss()
                            },
                            label: {
                                Image(systemName: "xmark")
                            }
                        )
                    }

                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        Button(
                            action: {
                                action = .rotateLeft
                            },
                            label: {
                                Image(systemName: "rotate.left")
                            }
                        )

                        Button(
                            action: {
                                action = .reset
                            },
                            label: {
                                Image(systemName: "arrow.counterclockwise")
                            }
                        )

                        Menu(
                            content: {
                                Button(
                                    action: {
                                        action = .rotateRight
                                    },
                                    label: {
                                        HStack {
                                            Image(systemName: "rotate.right")
                                            Text("Rotate Right")
                                        }
                                    }
                                )

                                Button(
                                    action: {
                                        action = .undo
                                    },
                                    label: {
                                        HStack {
                                            Image(systemName: "arrow.uturn.backward")
                                            Text("Undo")
                                        }
                                    }
                                )

                                Button(
                                    action: {
                                        action = .redo
                                    },
                                    label: {
                                        HStack {
                                            Image(systemName: "arrow.uturn.forward")
                                            Text("Redo")
                                        }
                                    }
                                )
                            },
                            label: {
                                Image(systemName: "ellipsis.circle")
                            }
                        )

                        Button(
                            action: {
                                action = .crop
                            },
                            label: {
                                Image(systemName: "checkmark")
                            }
                        )
                    }
                }
        }
    }
}

extension ImageCropperWrapper {
    func makeImageCropperWithoutAttachedToolbar() -> some View {
        var config = Mantis.Config()
        config.showAttachedCropToolbar = false
        config.enableUndoRedo = true

        return ImageCropperView(
            config: config,
            image: $image,
            transformation: $transformation,
            cropInfo: .constant(nil),
            action: $action,
            onDismiss: {
                presentationMode.wrappedValue.dismiss()
            }
        )
    }
}
