//
//  ContentView.swift
//  MantisSwiftUIExample
//
//  Created by Echo on 4/29/21.
//

import SwiftUI
import Mantis

struct ContentView: View {
    // Mirrors the UIKit example's data flow: `image` always holds the full
    // original; crop results only go to `croppedImage` for display, so every
    // demo starts from the complete picture.
    @State private var image: UIImage? = UIImage(named: "sunflower")!
    @State private var croppedImage: UIImage?
    @State private var savedTransformation: Transformation?

    @State private var cropperOptions: DeclarativeCropperOptions?
    @State private var showingCustomToolbarCropper = false
    @State private var showingLegacyCropper = false
    @State private var showingCropShapeList = false
    @State private var cropShapeType: Mantis.CropShapeType = .rect
    @State private var contentHeight: CGFloat = 0

    @State private var showImagePicker = false
    @State private var showCamera = false
    @State private var showSourceTypeSelection = false
    @State private var sourceType: UIImagePickerController.SourceType?
    @State private var pickedImage: UIImage?

    @State private var transformation: Transformation?
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var body: some View {
        AdaptiveStack {
            createImageHolder()
            createFeatureDemoList()
        }
        .fullScreenCover(item: $cropperOptions, onDismiss: reset, content: { options in
            DeclarativeCropperView(image: $image,
                                   croppedImage: $croppedImage,
                                   savedTransformation: $savedTransformation,
                                   options: options)
                .ignoresSafeArea()
        })
        .fullScreenCover(isPresented: $showingCustomToolbarCropper, content: {
            DeclarativeCropperDemoView(image: $image,
                                       croppedImage: $croppedImage,
                                       savedTransformation: $savedTransformation)
                .ignoresSafeArea()
        })
        .fullScreenCover(isPresented: $showingLegacyCropper, content: {
            // The legacy binding API replaces the bound image with the crop
            // result by design, so hand it the displayed image and route the
            // result to croppedImage — the original stays untouched.
            ImageCropperWrapper(image: Binding(
                get: { croppedImage ?? image },
                set: { croppedImage = $0 }
            ), transformation: $transformation)
                .onDisappear(perform: reset)
                .ignoresSafeArea()
        })
        .sheet(isPresented: $showingCropShapeList) {
            // CropShapeListView writes cropShapeType before flipping selectedType,
            // so the setter below sees the freshly chosen shape.
            CropShapeListView(cropShapeType: $cropShapeType, selectedType: Binding(
                get: { cropperOptions != nil },
                set: { isSelected in
                    if isSelected {
                        cropperOptions = DeclarativeCropperOptions(cropShapeType: cropShapeType)
                    }
                }
            ))
        }
        .sheet(isPresented: $showSourceTypeSelection) {
            SourceTypeSelectionView(showSourceTypeSelection: $showSourceTypeSelection, showCamera: $showCamera, showImagePicker: $showImagePicker)
        }
        .sheet(isPresented: $showCamera, onDismiss: applyPickedImage) {
            CameraView(image: $pickedImage)
        }
        .sheet(isPresented: $showImagePicker, onDismiss: applyPickedImage) {
            ImagePickerView(image: $pickedImage)
        }
    }

    func reset() {
        cropShapeType = .rect
    }

    /// A saved transformation is only valid for the image it was created
    /// from, so switching the original clears the derived state.
    func applyPickedImage() {
        guard let pickedImage = pickedImage else { return }
        image = pickedImage
        croppedImage = nil
        savedTransformation = nil
        self.pickedImage = nil
    }
    
    func createImageHolder() -> some View {
        VStack {
            Spacer()
            Image(uiImage: croppedImage ?? image!)
                .resizable().aspectRatio(contentMode: .fit)
                .frame(width: 300, height: 300, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
            HStack {
                Button("Choose Image") {
                    showSourceTypeSelection = true
                }
                .font(.title)
                Button("Reset Image") {
                    image = UIImage(named: "sunflower")!
                    croppedImage = nil
                    savedTransformation = nil
                }
                .font(.title)
            }
            Spacer()
        }
    }
    
    func createFeatureDemoList() -> some View {
        ScrollView {
            if horizontalSizeClass == .regular {
                createFeatureDemoListContent()
                    .frame(maxWidth: .infinity, minHeight: 0, maxHeight: contentHeight < UIScreen.main.bounds.height ? .infinity : nil)
                    .padding(.vertical, (UIScreen.main.bounds.height - contentHeight) / 2)
            } else {
                createFeatureDemoListContent()
            }
        }
    }
    
    func createFeatureDemoListContent() -> some View {
        VStack(alignment: .leading) {
            Spacer()
            Button("Normal Crop") {
                // Like the UIKit example's normal entry: reopen restored to
                // the previous crop state, cropping the full original image.
                cropperOptions = DeclarativeCropperOptions(restoresLastTransformation: true)
            }.font(.title)
            Button("Custom Toolbar (CropSession)") {
                showingCustomToolbarCropper = true
            }.font(.title)
            Button("Select crop shape") {
                showingCropShapeList = true
            }.font(.title)
            Button("Keep 1:1 ratio") {
                cropperOptions = DeclarativeCropperOptions(aspectRatio: .fixed(1))
            }.font(.title)
            Button("Hide Rotation Dial") {
                cropperOptions = DeclarativeCropperOptions(showsRotationControl: false)
            }.font(.title)
            Button("Slide Dial") {
                cropperOptions = DeclarativeCropperOptions(usesSlideDial: true)
            }.font(.title)
            Button("Perspective Correction") {
                cropperOptions = DeclarativeCropperOptions(enablesPerspectiveCorrection: true)
            }.font(.title)
            Button("Zoom Out While Expanding") {
                cropperOptions = DeclarativeCropperOptions(zoomsOutWhileExpandingCropBox: true)
            }.font(.title)
            Button("Legacy Binding API") {
                showingLegacyCropper = true
            }.font(.title)
            Spacer()
        }
        .background(
            GeometryReader { proxy in
                Color.clear
                    .onAppear {
                        self.contentHeight = proxy.size.height
                    }
            }
        )
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ForEach(ColorScheme.allCases, id: \.self) {
            ContentView().preferredColorScheme($0)
            if #available(iOS 15.0, *) {
                ContentView()
                    .previewInterfaceOrientation(.landscapeLeft)
            }
        }
    }
}
