<p align="center">
    <img src="logo.png" height="80" max-width="90%" alt="Mantis" />
</p>

#Mantis

   Mantis is a swift 4.2 library that allow to expand an interface to crop photos
It mimics almost the main interaction of Photos.app of iOS device.
This project is inspired by [IGRPhotoTweaks](https://github.com/IGRSoft/IGRPhotoTweaks) and [TOCropViewController](https://github.com/TimOliver/TOCropViewController)

<p align="center">
    <img src="Screen Shot.png" height="300" alt="Mantis" />
</p>

## Install

### CocoaPods

To do

## Usage

* Create a crop ViewController

```swift
Mantis.cropViewController(image: image)
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
  
  * embedded mode
  
  Under this mode, you can embed CropViewController into another UIViewController. That way you can add more customized edit features other than cropping.

```swift
        let cropViewController = Mantis.cropViewController(image: image, mode: .normal)
        cropViewController.delegate = self
        present(cropViewController, animated: true)
```



