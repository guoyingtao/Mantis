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
    @State private var showingCropper = false
    @State private var showingCropShapeList = false
    @State private var cropShapeType: Mantis.CropShapeType = .rect
    @State private var presetFixedRatioType: Mantis.PresetFixedRatioType = .canUseMultiplePresetFixedRatio()
    @State private var cropperType: MantisImageCropperType = .normal
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
        .fullScreenCover(isPresented: $showingCropper, content: {
            ImageCropperWrapper(image: $image,
                         cropShapeType: $cropShapeType,
                         presetFixedRatioType: $presetFixedRatioType,
                         type: $cropperType, transformation: $transformation)
            .onDisappear(perform: reset)
            .ignoresSafeArea()
        })
        .sheet(isPresented: $showingCropShapeList) {
            CropShapeListView(cropShapeType: $cropShapeType, selectedType: $showingCropper)
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
        presetFixedRatioType = .canUseMultiplePresetFixedRatio()
        cropperType = .normal
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
                showingCropper = true
            }.font(.title)
            Button("Select crop shape") {
                showingCropShapeList = true
            }.font(.title)
            Button("Keep 1:1 ratio") {
                presetFixedRatioType = .alwaysUsingOnePresetFixedRatio(ratio: 1)
                showingCropper = true
            }.font(.title)
            Button("Hide Rotation Dial") {
                cropperType = .noRotaionDial
                showingCropper = true
            }.font(.title)
            Button("Hide Attached Toolbar") {
                cropperType = .noAttachedToolbar
                showingCropper = true
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
