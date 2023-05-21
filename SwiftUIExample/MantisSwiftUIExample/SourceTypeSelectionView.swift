//
//  SourceTypeSelectionView.swift
//  MantisSwiftUIExample
//
//  Created by Yingtao Guo on 2/20/23.
//

import SwiftUI

struct SourceTypeSelectionView: View {
    @Binding var showSourceTypeSelection: Bool
    @Binding var showCamera: Bool
    @Binding var showImagePicker: Bool

    var body: some View {
        VStack {
            Text("Select Image Source")
                .font(.title)
                .padding()

            Button("Photo Library") {
                showSourceTypeSelection = false
                showImagePicker = true
            }
            .font(.title)
            .padding()

            Button("Camera") {
                showSourceTypeSelection = false
                showCamera = true
            }
            .font(.title)
            .padding()

            Button("Cancel") {
                showSourceTypeSelection = false
            }
            .font(.title)
            .padding()
        }
    }
}

struct SourceTypeSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        SourceTypeSelectionView(showSourceTypeSelection: .constant(false), showCamera: .constant(false), showImagePicker: .constant(false))
    }
}
