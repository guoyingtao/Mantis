<p align="center">
    <img src="logo.png" height="80" max-width="90%" alt="Mantis" />
</p>

<p align="center">
    <img src="https://img.shields.io/badge/swift-4.2-orange.svg" alt="swift 4.2 badge" />
    <img src="https://img.shields.io/badge/platform-iOS-lightgrey.svg" alt="platform iOS badge" />
    <img src="https://img.shields.io/badge/license-MIT-black.svg" alt="license MIT badge" />   
</p>

# Mantis

   Mantis is a swift 4.2 library that mimics almost most interactions of Photos.app of iOS device. You can use CropViewController of Mantis with default buttons or you can also add your own buttons under "customized" mode. 
This project is strongly inspired by [IGRPhotoTweaks](https://github.com/IGRSoft/IGRPhotoTweaks) and [TOCropViewController](https://github.com/TimOliver/TOCropViewController).

<p align="center">
    <img src="Images/p1.png" height="200" alt="Mantis" />
    <img src="Images/p2.png" height="200" alt="Mantis" />
    <img src="Images/p3.png" height="200" alt="Mantis" />
    <img src="Images/p4.png" height="200" alt="Mantis" />
    <img src="Images/p5.png" height="200" alt="Mantis" />
    <img src="Images/p6.png" height="200" alt="Mantis" />
</p>

## Install

### CocoaPods

To do

## Usage

* Create a crop ViewController of Mantis

```swift
let cropViewController = Mantis.cropViewController(image: <Your Image>, mode: .normal)
```

* The caller need to conform CropViewControllerProtocal
```swift
public protocol CropViewControllerProtocal: class {
    func didGetCroppedImage(image: UIImage)
}
```

* CropViewController has two modes

  * normal mode

  Under this mode, you can use CropViewController as normal one.
<p align="center">
    <img src="Images/Screen Shot.png" height="300" alt="Mantis" />
</p>

  
  * embedded mode
  
  Under this mode, you can embed CropViewController into another UIViewController. That way you can add more customized edit features other than cropping.

<p align="center">
    <img src="Images/embedded.png" height="300" alt="Mantis" />
</p>

### Demo code

```swift
        let cropViewController = Mantis.cropViewController(image: <Your Image>, mode: .normal)
        cropViewController.delegate = self
        <Your ViewController>.present(cropViewController, animated: true)
```

<div>Icons made by <a href="https://www.freepik.com" title="Freepik">Freepik</a> from <a href="https://www.flaticon.com/" title="Flaticon">www.flaticon.com</a> is licensed by <a href="http://creativecommons.org/licenses/by/3.0/" title="Creative Commons BY 3.0" target="_blank">CC 3.0 BY</a></div>


