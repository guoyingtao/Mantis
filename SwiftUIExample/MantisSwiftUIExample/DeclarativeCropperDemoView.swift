//
//  DeclarativeCropperDemoView.swift
//  MantisSwiftUIExample
//
//  Demonstrates the Mantis 3.0 declarative SwiftUI API:
//  ImageCropper configured with modifiers, driven by an observable CropSession.
//

import Mantis
import SwiftUI

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
