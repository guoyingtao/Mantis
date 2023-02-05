<p align="center">
    <img src="logo.png" height="80" max-width="90%" alt="Mantis" />
</p>

<p align="center">
    <img src="https://img.shields.io/badge/swift-5.0-orange.svg" alt="swift 5.0 badge" />
    <img src="https://img.shields.io/badge/platform-iOS-lightgrey.svg" alt="platform iOS badge" />
    <img src="https://img.shields.io/badge/license-MIT-black.svg" alt="license MIT badge" />   
</p>

# Mantis

   Mantis is an iOS Image cropping library, which mimics the Photo App written in Swift and provides rich cropping interactions for your iOS/Mac app (Catalyst only).
   
<p align="center">
    <img src="Images/Mantis on all devices.png" height="400" alt="Mantis" />
</p>
   
   Mantis also provides rich crop shapes from the basic circle/square to polygon to arbitrary paths(We even provide a heart shape ❤️ 😏).
<p align="center">
    <img src="Images/cropshapes.png" height="450" alt="Mantis" />
</p>

## Requirements
* iOS 11.0+
* MacOS 10.15+
* Xcode 10.0+

## Breaking Changes in 2.x.x
* Add CropViewConfig
  * move some properties from Config to CropViewConfig
  * make dialConfig as a property of CropViewConfig
* Refactor CropToolbarConfigProtocol
  * rename some properties

## Install

<details>
    <summary><strong>CocoaPods</strong></summary>

```ruby
pod 'Mantis', '~> 2.6.2'
```
</details>

<details>
 <summary><strong>Carthage</strong></summary>

```ruby
github "guoyingtao/Mantis"
```
</details>

<details>
 <summary><strong>Swift Packages</strong></summary>

* Respository: https://github.com/guoyingtao/Mantis.git
* Rules: Version - Exact - 2.6.2

</details>

## Usage

<details>
<summary><strong>Basic</strong></summary>

* Create a cropViewController in Mantis with default config and default mode

**You need set (cropViewController or its navigation controller).modalPresentationStyle = .fullscreen for iOS 13+ when the cropViewController is presented**

```Swift
    let cropViewController = Mantis.cropViewController(image: <Your Image>)
    cropViewController.delegate = self
    <Your ViewController>.present(cropViewController, animated: true)
```

* The caller needs to conform CropViewControllerDelegate
```swift
public protocol CropViewControllerDelegate: class {
    func cropViewControllerDidCrop(_ cropViewController: CropViewController, cropped: UIImage, transformation: Transformation, cropInfo: CropInfo)
    func cropViewControllerDidCancel(_ cropViewController: CropViewController, original: UIImage)
    
    // The implementaion of the following functions are optional
    func cropViewControllerDidFailToCrop(_ cropViewController: CropViewController, original: UIImage)     
    func cropViewControllerDidBeginResize(_ cropViewController: CropViewController)
    func cropViewControllerDidEndResize(_ cropViewController: CropViewController, original: UIImage, cropInfo: CropInfo)    
}
```
</details>
    
<details>
<summary><strong>CropToolbar mode</strong></summary>

* CropToolbar has two modes:

  * normal mode

  In normal mode, you can use a set of standard CropViewController photo editing features with "Cancel" and "Done" buttons.
<p align="center">
    <img src="Images/Screen Shot.png" height="300" alt="Mantis" />
</p>

```swift
let cropViewController = Mantis.cropViewController(image: <Your Image>)
```

  * embedded mode
  
  This mode does not include "Cancel" and "Done" buttons, so you can embed CropViewController into another view controller

<p align="center">
    <img src="Images/customizable.jpg" height="300" alt="Mantis" />
</p>

```swift
var config = Mantis.Config()
config.cropToolbarConfig.mode = .embedded
let cropViewController = Mantis.cropViewController(image: <Your Image>, config: config)
```

</details>

<details>
<summary><strong>Add your own ratio</strong></summary>

```swift
            // Add a custom ratio 1:2 for portrait orientation
            let config = Mantis.Config()
            config.addCustomRatio(byVerticalWidth: 1, andVerticalHeight: 2)            
            <Your Crop ViewController> = Mantis.cropViewController(image: <Your Image>, config: config)
            
            // Set the ratioOptions of the config if you don't want to keep all default ratios
            let config = Mantis.Config() 
            //config.ratioOptions = [.original, .square, .custom]
            config.ratioOptions = [.custom]
            config.addCustomRatio(byVerticalWidth: 1, andVerticalHeight: 2)            
            <Your Crop ViewController> = Mantis.cropViewController(image: <Your Image>, config: config)
```

* If you always want to use only one fixed ratio, set Mantis.Config.presetFixedRatioType = alwaysUsingOnePresetFixedRatio

```swift
    <Your Crop ViewController>.config.presetFixedRatioType = .alwaysUsingOnePresetFixedRatio(ratio: 16.0 / 9.0)
```

When choose alwaysUsingOnePresetFixedRatio, fixed-ratio setting button does not show.

* If you want to hide rotation dial, set Mantis.Config..cropViewConfig.dialConfig = nil
* If you want to use ratio list instead of presenter, set Mantis.CropToolbarConfig.ratioCandidatesShowType = .alwaysShowRatioList

```swift
public enum RatioCandidatesShowType {
    case presentRatioList
    case alwaysShowRatioList
}
```

* If you build your custom toolbar you can add your own fixed ratio buttons
```swift
// set a custom fixed ratio
cropToolbarDelegate?.didSelectRatio(ratio: 9 / 16)
```
</details>

<details>
<summary><strong>Crop shapes</strong></summary>

* If you want to set different crop shape, set Mantis.Config.cropViewConfig.cropShapeType
```swift
public enum CropShapeType {
    case rect
    case square
    case ellipse
    case circle(maskOnly: Bool = false)
    case diamond(maskOnly: Bool = false)
    case heart(maskOnly: Bool = false)
    case polygon(sides: Int, offset: CGFloat = 0, maskOnly: Bool = false)
    case path(points: [CGPoint], maskOnly: Bool = false)
}
```
</details>

<details>
<summary><strong>Preset transformations</strong></summary>

* If you want to apply transformations when showing an image, set Mantis.Config.cropViewConfig.presetTransformationType
```swift
public enum PresetTransformationType {
    case none
    case presetInfo(info: Transformation)
    case presetNormalizedInfo(normailizedInfo: CGRect)
}
```
Please use the transformation infomation obtained previously from delegate method cropViewControllerDidCrop(_ cropViewController: CropViewController, cropped: UIImage, transformation: Transformation, , cropInfo: CropInfo).

</details>
                
<details>
    <summary><strong>Localization</strong></summary>
    
* UIKit project    
    Add more languages support to the Localizaions section for Project Info tab 
    
<p align="center">
    <img src="https://user-images.githubusercontent.com/26723384/128650945-5a1da648-7e7d-4faf-9c95-232725b05dcc.png" height="200" alt="Mantis" />
    <br>fig 1</br>
</p>
    
* SwiftUI project    
    Please check this [link](https://github.com/guoyingtao/Mantis/discussions/123#discussioncomment-1127611)

* Static frameworks
    If you use static frameworks in CocoaPods, you need to add the code below in order to find the correct resource bundle.
    
```
    Mantis.locateResourceBundle(by: Self.self)
```
  
* Custom localization tables and bundle
    
By default mantis will use built in localization tables to get string resources not every language is supported out of the box (see fig 1).
    
However if your app support multiple languages and those languages are not 'built in', then you can define your own strings table and localize them in the application target or framework. By doing so you'll need to configure Mantis localization.

**IMPORTANT!** Firstly you'll need to create strings file with these keys:

```
"Mantis.Done" = "";
"Mantis.Cancel" = "";
"Mantis.Reset" = "";
"Mantis.Original" = "";
"Mantis.Square" = "";
```
Then you'll need to configure Mantis:

```
let config = Mantis.Config()
config.localizationConfig.bundle = // a bundle where strings file is located
config.localizationConfig.tableName = // a localizaed strings file name within the bundle
```
  
</details>

<details>
    <summary><strong>Custom View Controller</strong></summary>

- If needed you can subclass `CropViewController`:

```swift
class CustomViewController: CropViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do your custom logic here.
        // The MantisExample project also has a showcase for a CustomViewController.
    }
}
```

- To get an instance, Mantis provides a factory method:

```swift
let cropViewController: CustomViewController = Mantis.cropViewController(image: image, config: config)
```

</details>
    
### Demo projects
Mantis provide two demo projects
- MantisExample (using Storyboard)
- MantisSwiftUIExample (using SwiftUI)

## Credits
* The crop are strongly inspired by [TOCropViewController](https://github.com/TimOliver/TOCropViewController) 
* The rotation feature is inspired by [IGRPhotoTweaks](https://github.com/IGRSoft/IGRPhotoTweaks)
* The rotation dial is inspired by [10clock](https://github.com/joedaniels29/10Clock)
* Thanks [Leo Dabus](https://stackoverflow.com/users/2303865/leo-dabus) for helping me to solve the problem of cropping an ellipse image with transparent background https://stackoverflow.com/a/59805317/288724
* <div>Icons made by <a href="https://www.freepik.com" title="Freepik">Freepik</a> from <a href="https://www.flaticon.com/" title="Flaticon">www.flaticon.com</a> is licensed by <a href="http://creativecommons.org/licenses/by/3.0/" title="Creative Commons BY 3.0" target="_blank">CC 3.0 BY</a></div>



