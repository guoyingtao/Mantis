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
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        switch type {
        case .normal:
            makeNormalImageCropper()
        case .noRotationDial:
            makeImageCropperHidingRotationDial()
        case .noAttachedToolbar:
            makeImageCropperWithoutAttachedToolbar()
        }
    }
}

extension ImageCropperWrapper {
    func makeNormalImageCropper() -> some View {
        var config = Mantis.Config()
        config.cropViewConfig.cropShapeType = cropShapeType
        config.presetFixedRatioType = presetFixedRatioType
        
        return ImageCropperView(config: config, image: $image, transformation: $transformation, cropInfo: .constant(nil))
    }
    
    func makeImageCropperHidingRotationDial() -> some View {
        var config = Mantis.Config()
        config.cropViewConfig.showAttachedRotationControlView = false

        return ImageCropperView(config: config, image: $image, transformation: $transformation, cropInfo: .constant(nil))
    }
    
    func makeImageCropperWithoutAttachedToolbar() -> some View {
        var config = Mantis.Config()
        config.showAttachedCropToolbar = false
        
        return ImageCropperView(config: config, image: $image, transformation: $transformation, cropInfo: .constant(nil))
    }
}
