//
//  ImageAutoAdjuster.swift
//  Mantis
//
//  Created by Yingtao Guo on 6/24/23.
//

import UIKit
import Vision

class ImageAutoAdjustHelper {
    var image: UIImage!
    var adjustAngle = Angle(radians: 0)
    
    init(image: UIImage!) {
        self.image = image
    }
    
    func detectHorizon() -> Bool {
        detectHorizon(in: image)
    }
    
    func detectHorizon(in image: UIImage) -> Bool {
        guard let ciImage = CIImage(image: image) else {
            return false
        }

        let request = VNDetectHorizonRequest { [weak self] request, _ in
            guard let observations = request.results as? [VNHorizonObservation] else {
                return
            }

            if let highestConfidenceObservation = observations.max(by: { $0.confidence < $1.confidence }) {
                let angle = highestConfidenceObservation.angle
                self?.adjustAngle = Angle(radians: -angle)
            }
        }

        let handler = VNImageRequestHandler(ciImage: ciImage, orientation: .up)

        do {
            try handler.perform([request])
            return adjustAngle.degrees != 0
        } catch {
            print("Error: \(error)")
            return false
        }
    }
}
