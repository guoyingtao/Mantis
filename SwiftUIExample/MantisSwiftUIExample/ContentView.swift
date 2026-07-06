//
//  ContentView.swift
//  MantisSwiftUIExample
//
//  Created by Echo on 4/29/21.
//

import SwiftUI
import Mantis

struct ContentView: View {
    @State private var image: UIImage? = UIImage(named: "sunflower")!
    @State private var cropperOptions: DeclarativeCropperOptions?
    @State private var showingCustomToolbarCropper = false
    @State private var showingLegacyCropper = false
    @State private var showingCropShapeList = false
    @State private var cropShapeType: Mantis.CropShapeType = .rect
    @State private var showingRestorableCropper = false
    @State private var savedTransformation: Transformation?
    @State private var contentHeight: CGFloat = 0
    
    @State private var showImagePicker = false
    @State private var showCamera = false
    @State private var showSourceTypeSelection = false
    @State private var sourceType: UIImagePickerController.SourceType?
    
    @State private var transformation: Transformation?
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var body: some View {
        AdaptiveStack {
            createImageHolder()
            createFeatureDemoList()
        }
        .fullScreenCover(item: $cropperOptions, onDismiss: reset, content: { options in
            DeclarativeCropperView(image: $image, options: options)
                .ignoresSafeArea()
        })
        .fullScreenCover(isPresented: $showingRestorableCropper, content: {
            RestorableCropperDemoView(image: $image,
                                      savedTransformation: $savedTransformation,
                                      originalImage: UIImage(named: "sunflower")!)
            .ignoresSafeArea()
        })
        .fullScreenCover(isPresented: $showingCustomToolbarCropper, content: {
            DeclarativeCropperDemoView(image: $image)
                .ignoresSafeArea()
        })
        .fullScreenCover(isPresented: $showingLegacyCropper, content: {
            ImageCropperWrapper(image: $image, transformation: $transformation)
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
        .sheet(isPresented: $showCamera) {
            CameraView(image: $image)
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePickerView(image: $image)
        }
    }
    
    func reset() {
        cropShapeType = .rect
    }
    
    func createImageHolder() -> some View {
        VStack {
            Spacer()
            Image(uiImage: image!)
                .resizable().aspectRatio(contentMode: .fit)
                .frame(width: 300, height: 300, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
            HStack {
                Button("Choose Image") {
                    showSourceTypeSelection = true
                }
                .font(.title)
                Button("Reset Image") {
                    image = UIImage(named: "sunflower")!
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
                cropperOptions = DeclarativeCropperOptions()
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
            Button("Restore Last Crop") {
                showingRestorableCropper = true
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
