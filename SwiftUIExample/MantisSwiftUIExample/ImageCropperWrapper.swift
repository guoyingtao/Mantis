//
//  ImageCropperWrapper.swift
//  MantisSwiftUIExample
//
//  Created by Yingtao Guo on 2/16/23.
//

import Mantis
import SwiftUI

/**
 * A SwiftUI wrapper that provides different configurations for the Mantis image cropper.
 * This view adapts to different cropper types and provides a convenient API for
 * integrating the Mantis image cropping functionality into SwiftUI views.
 */
struct ImageCropperWrapper: View {
    @Binding var image: UIImage?
    @Binding var cropShapeType: Mantis.CropShapeType
    @Binding var presetFixedRatioType: Mantis.PresetFixedRatioType
    @Binding var type: CropperType
    @Binding var transformation: Transformation?
    @State private var action: CropAction?
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ZStack {
                switch type {
                case .normal:
                    makeNormalImageCropper()
                case .noRotationDial:
                    makeImageCropperHidingRotationDial()
                case .noAttachedToolbar:
                    makeImageCropperWithoutAttachedToolbar()
                }
            }
            .navigationTitle("Crop Image")
            .navigationBarTitleDisplayMode(.inline)
            .if(type == .noAttachedToolbar) { view in
                view.toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            action = .crop
                        }
                    }
                }
            }
        }
    }
}

extension ImageCropperWrapper {
    func makeNormalImageCropper() -> some View {
        var config = Mantis.Config()
        config.cropViewConfig.cropShapeType = cropShapeType
        config.presetFixedRatioType = presetFixedRatioType
        
        return ImageCropperView(config: config,
                                image: $image,
                                transformation: $transformation,
                                cropInfo: .constant(nil)) {
            presentationMode.wrappedValue.dismiss()
        }
    }
    
    func makeImageCropperHidingRotationDial() -> some View {
        var config = Mantis.Config()
        config.cropViewConfig.showAttachedRotationControlView = false
        
        return ImageCropperView(config: config, image: $image, transformation: $transformation, cropInfo: .constant(nil)) {
            presentationMode.wrappedValue.dismiss()
        }
    }
    
    func makeImageCropperWithoutAttachedToolbar() -> some View {
        var config = Mantis.Config()
        config.showAttachedCropToolbar = false
        
        return ImageCropperView(config: config,
                                image: $image,
                                transformation: $transformation,
                                cropInfo: .constant(nil),
                                action: $action) {
            presentationMode.wrappedValue.dismiss()
        }
    }
}

extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool,
                             transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
