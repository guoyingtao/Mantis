#
#  Be sure to run `pod spec lint Mantis.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|
  s.name         = "Mantis"
  s.version      = "1.7.4"
  s.summary      = "A swift photo cropping tool which mimics Photo.app"

  s.description  = <<-DESC
        Mantis is a swift photo cropping tool which mimics Photo.app
                   DESC

  s.homepage     = "https://github.com/guoyingtao/Mantis"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author             = { "Yingtao Guo" => "guoyingtao@outlook.com" }
  s.social_media_url   = "http://twitter.com/guoyingtao"
  s.platform     = :ios
  s.swift_version = "5.0"
  s.ios.deployment_target = "11.0"
  s.source       = { :git => "https://github.com/guoyingtao/Mantis.git", :tag => "#{s.version}" }
  s.source_files  = "Sources/**/*.{h,swift}"
  s.resource_bundles = {
    "MantisResource" => ["Sources/**/*.lproj/*.strings"]
  }
  
  s.pod_target_xcconfig = {
    "PRODUCT_BUNDLE_IDENTIFIER": "com.echo.framework.Mantis"
  }

end
