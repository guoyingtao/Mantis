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
    
    var body: some View {
        AdaptiveStack {
            VStack {
                Spacer()
                Image(uiImage: uiImage)
                    .resizable().aspectRatio(contentMode: .fit)
                    .frame(width: 300, height: 300, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
                Spacer()
            }
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
                Spacer()
            }
        }.fullScreenCover(isPresented: $showingCropper, content: {
            ImageCropper(image: $uiImage,
                         cropShapeType: $cropShapeType,
                         presetFixedRatioType: $presetFixedRatioType)
                .ignoresSafeArea()
        })
    }
    
    func reset() {
        uiImage = UIImage(named: "sunflower")!
        cropShapeType = .rect
        presetFixedRatioType = .canUseMultiplePresetFixedRatio()
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
