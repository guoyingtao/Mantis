//
//  ViewController.swift
//  Mantis
//
//  Created by Yingtao Guo on 10/19/18.
//  Copyright © 2018 Echo Studio. All rights reserved.
//

import UIKit
import Mantis

class CustomViewController: CropViewController {
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
            rotate,
        ]
    }

    @objc private func onRotateClicked() {
        didSelectClockwiseRotate()
    }

    @objc private func onDoneClicked() {
        crop()
    }
}
