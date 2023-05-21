//
//  CustomViewController.swift
//  MantisSwiftUIExample
//
//  Created by Yingtao Guo on 2/16/23.
//

import Mantis

class CustomViewController: Mantis.CropViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Custom View Controller"

        let rotate = UIBarButtonItem(
            image: UIImage.init(systemName: "crop.rotate"),
            style: .plain,
            target: self,
            action: #selector(onRotateClicked)
        )

        let done = UIBarButtonItem(
            image: UIImage.init(systemName: "checkmark"),
            style: .plain,
            target: self,
            action: #selector(onDoneClicked)
        )

        navigationItem.rightBarButtonItems = [
            done,
            rotate
        ]
    }

    @objc private func onRotateClicked() {
        didSelectClockwiseRotate()
    }

    @objc private func onDoneClicked() {
        crop()
    }
}
