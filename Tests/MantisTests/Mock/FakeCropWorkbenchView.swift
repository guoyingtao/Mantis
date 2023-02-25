//
//  FakeCropWorkbenchView.swift
//  Mantis
//
//  Created by Yingtao Guo on 2/3/23.
//

import UIKit
@testable import Mantis

class FakeCropWorkbenchView: UIScrollView, CropWorkbenchViewProtocol {
    var imageContainer: ImageContainerProtocol?
    
    var touchesBegan: () -> Void = {}
    
    var touchesCancelled: () -> Void = {}
    
    var touchesEnded: () -> Void = {}
    
    func checkContentOffset() {
        
    }
    
    func updateMinZoomScale() {
        
    }
    
    func zoomScaleToBound(animated: Bool) {
        
    }
    
    func shouldScale() -> Bool {
        false
    }
    
    func updateLayout(byNewSize newSize: CGSize) {
        
    }
    
    func reset(by rect: CGRect) {
        
    }
    
    func resetImageContent(by cropBoxFrame: CGRect) {
        
    }
}
