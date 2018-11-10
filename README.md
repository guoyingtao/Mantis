<p align="center">
    <img src="logo.png" height="80" max-width="90%" alt="Mantis" />
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



