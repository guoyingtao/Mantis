//
//  ContentView.swift
//  MantisSwiftUIExample
//
//  Created by Echo on 4/29/21.
//

import SwiftUI
import Mantis

struct ContentView: View {
    @State private var uiImage: UIImage = UIImage(named: "sunflower")!
    @State private var showingCropper = false
    @State private var cropShapeType: Mantis.CropShapeType = .rect
    @State private var presetFixedRatioType: Mantis.PresetFixedRatioType = .canUseMultiplePresetFixedRatio()
    @State private var cropperType: ImageCropperType = .normal
    @State private var contentHeight: CGFloat = 0
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var body: some View {
        AdaptiveStack {
            createImageHolder()
            createFeatureDemoList()
        }.fullScreenCover(isPresented: $showingCropper, content: {
            ImageCropper(image: $uiImage,
                         cropShapeType: $cropShapeType,
                         presetFixedRatioType: $presetFixedRatioType,
                         type: $cropperType)
            .ignoresSafeArea()
        })
    }
    
    func reset() {
        uiImage = UIImage(named: "sunflower")!
        cropShapeType = .rect
        presetFixedRatioType = .canUseMultiplePresetFixedRatio()
        cropperType = .normal
    }
    
    func createImageHolder() -> some View {
        VStack {
            Spacer()
            Image(uiImage: uiImage)
                .resizable().aspectRatio(contentMode: .fit)
                .frame(width: 300, height: 300, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
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
        VStack {
            Spacer()
            Button("Normal") {
                reset()
                showingCropper = true
            }.font(.title)
            Button("Circle Crop") {
                reset()
                cropShapeType = .circle()
                showingCropper = true
            }.font(.title)
            Button("Keep 1:1 ratio") {
                reset()
                presetFixedRatioType = .alwaysUsingOnePresetFixedRatio(ratio: 1)
                showingCropper = true
            }.font(.title)
            Button("Hide Rotation Dial") {
                reset()
                cropperType = .noRotaionDial
                showingCropper = true
            }.font(.title)
            Button("Hide Attached Toolbar") {
                reset()
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
