//
//  ImageCropper.swift
//  MantisSwiftUIExample
//
//  Created by Yingtao Guo on 2/16/23.
//

import Mantis
import SwiftUI

enum ImageCropperType {
    case normal
    case noRotaionDial
    case noAttachedToolbar
}

struct ImageCropper: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Binding var cropShapeType: Mantis.CropShapeType
    @Binding var presetFixedRatioType: Mantis.PresetFixedRatioType
    @Binding var type: ImageCropperType
    
    @Environment(\.presentationMode) var presentationMode
    
    class Coordinator: CropViewControllerDelegate {
        var parent: ImageCropper
        
        init(_ parent: ImageCropper) {
            self.parent = parent
        }
        
        func cropViewControllerDidCrop(_ cropViewController: Mantis.CropViewController, cropped: UIImage, transformation: Transformation, cropInfo: CropInfo) {
            parent.image = cropped
            print("transformation is \(transformation)")
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func cropViewControllerDidCancel(_ cropViewController: Mantis.CropViewController, original: UIImage) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> UIViewController {
        switch type {
        case .normal:
            return makeNormalImageCropper(context: context)
        case .noRotaionDial:
            return makeImageCropperHiddingRotationDial(context: context)
        case .noAttachedToolbar:
            return makeImageCropperWithoutAttachedToolbar(context: context)
        }
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        
    }
}

extension ImageCropper {
    func makeNormalImageCropper(context: Context) -> UIViewController {
        var config = Mantis.Config()
        config.cropViewConfig.cropShapeType = cropShapeType
        config.presetFixedRatioType = presetFixedRatioType
        let cropViewController = Mantis.cropViewController(image: image!,
                                                           config: config)
        cropViewController.delegate = context.coordinator
        return cropViewController
    }
    
    func makeImageCropperHiddingRotationDial(context: Context) -> UIViewController {
        var config = Mantis.Config()
        config.cropViewConfig.showRotationDial = false
        let cropViewController = Mantis.cropViewController(image: image!, config: config)
        cropViewController.delegate = context.coordinator

        return cropViewController
    }
    
    func makeImageCropperWithoutAttachedToolbar(context: Context) -> UIViewController {
        var config = Mantis.Config()
        config.showAttachedCropToolbar = false
        let cropViewController: CustomViewController = Mantis.cropViewController(image: image!, config: config)
        cropViewController.delegate = context.coordinator

        return UINavigationController(rootViewController: cropViewController)
    }
}
