#
#  Be sure to run `pod spec lint Mantis.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|
  s.name         = "Mantis"
  s.version      = "3.1.0"
  s.summary      = "An iOS image cropping library with UIKit and SwiftUI APIs, mimicking the Photos app with rich cropping interactions."

  s.description  = <<-DESC
        Mantis is an iOS image cropping library written in Swift, with both UIKit and SwiftUI APIs.
        It mimics the Photos app: crop with rotation, flip, free or fixed aspect ratios, rich crop
        shapes, perspective correction, and undo/redo - on iOS and Mac Catalyst.
                   DESC

  s.homepage     = "https://github.com/guoyingtao/Mantis"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author             = { "Yingtao Guo" => "guoyingtao@outlook.com" }
  s.social_media_url   = "https://x.com/guoyingtao"
  s.platform     = :ios
  s.swift_version = "5.0"
  s.ios.deployment_target = "15.0"
  s.source       = { :git => "https://github.com/guoyingtao/Mantis.git", :tag => "v#{s.version}" }
  s.source_files  = "Sources/**/*.{h,swift}"
  s.resource_bundles = {
    "MantisResources" => ["Sources/**/*.lproj/*.strings", "Sources/Mantis/PrivacyInfo.xcprivacy"]
  }
  
  s.pod_target_xcconfig = {
    "PRODUCT_BUNDLE_IDENTIFIER": "com.echo.framework.Mantis"
  }

end
