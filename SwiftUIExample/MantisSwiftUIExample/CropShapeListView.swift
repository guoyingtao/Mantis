//
//  CropShapeListView.swift
//  MantisSwiftUIExample
//
//  Created by Yingtao Guo on 2/16/23.
//

import Mantis
import SwiftUI

typealias CropShapeItem = (type: Mantis.CropShapeType, title: String)

struct CropShapeListView: View {
    @Environment(\.dismiss) var dismiss
    
    let cropShapeList: [CropShapeItem] = [
        (.rect, "Rect"),
        (.square, "Square"),
        (.ellipse(), "Ellipse"),
        (.circle(), "Circle"),
        (.polygon(sides: 5), "pentagon"),
        (.polygon(sides: 6), "hexagon"),
        (.roundedRect(radiusToShortSide: 0.1), "Rounded rectangle"),
        (.diamond(), "Diamond"),
        (.heart(), "Heart"),
        (.path(points: [CGPoint(x: 0.5, y: 0),
                        CGPoint(x: 0.6, y: 0.3),
                        CGPoint(x: 1, y: 0.5),
                        CGPoint(x: 0.6, y: 0.8),
                        CGPoint(x: 0.5, y: 1),
                        CGPoint(x: 0.5, y: 0.7),
                        CGPoint(x: 0, y: 0.5)]), "Arbitrary path")
    ]
    
    @Binding var cropShapeType: Mantis.CropShapeType
    @Binding var selectedType: Bool
    
    var body: some View {
        ForEach(cropShapeList, id: \.type) { item in
            Button(item.title) {
                cropShapeType = item.type
                selectedType = true
                dismiss()
            }
            .font(.title)
        }
    }
}

struct CropShapeListView_Previews: PreviewProvider {
    static var previews: some View {
        CropShapeListView(cropShapeType: .constant(.rect), selectedType: .constant(false))
    }
}
