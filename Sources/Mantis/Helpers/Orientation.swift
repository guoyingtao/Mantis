//
//  OrientationExtensions.swift
//  Mantis
//
//  Created by Echo on 10/10/20.
//
import UIKit

public struct Orientation {
    public static var orientation: UIInterfaceOrientation {
        get {
            if #available(iOS 13, macOS 10.13, *) {
                return (UIApplication.shared.windows.first?.windowScene?.interfaceOrientation)!
            } else {
                return UIApplication.shared.statusBarOrientation
            }
        }
    }
    
    // indicate current device is in the LandScape orientation
    public static var isLandscape: Bool {
        get {
            if #available(iOS 13, macOS 10.13, *) {
                return UIDevice.current.orientation.isValidInterfaceOrientation
                    ? UIDevice.current.orientation.isLandscape
                    : (UIApplication.shared.windows.first?.windowScene?.interfaceOrientation.isLandscape)!
            } else {
                return UIDevice.current.orientation.isValidInterfaceOrientation
                    ? UIDevice.current.orientation.isLandscape
                    : UIApplication.shared.statusBarOrientation.isLandscape
            }
        }
    }
    // indicate current device is in the Portrait orientation
    public static var isPortrait: Bool {
        get {
            if #available(iOS 13, macOS 10.13, *) {
                return UIDevice.current.orientation.isValidInterfaceOrientation
                    ? UIDevice.current.orientation.isPortrait
                    : (UIApplication.shared.windows.first?.windowScene?.interfaceOrientation.isPortrait)!
            } else {
                return UIDevice.current.orientation.isValidInterfaceOrientation
                    ? UIDevice.current.orientation.isPortrait
                    : UIApplication.shared.statusBarOrientation.isPortrait
            }
        }
    }
    
    public static var isLandscapeLeft: Bool {
        get {
            if #available(iOS 13, macOS 10.13, *) {
                return UIDevice.current.orientation.isValidInterfaceOrientation
                    ? UIDevice.current.orientation == .landscapeLeft
                    : (UIApplication.shared.windows.first?.windowScene?.interfaceOrientation)! == .landscapeLeft
            } else {
                return UIDevice.current.orientation.isValidInterfaceOrientation
                    ? UIDevice.current.orientation == .landscapeLeft
                    : UIApplication.shared.statusBarOrientation == .landscapeLeft
            }
        }
    }
    
    public static var isLandscapeRight: Bool {
        get {
            if #available(iOS 13, macOS 10.13, *) {
                return UIDevice.current.orientation.isValidInterfaceOrientation
                    ? UIDevice.current.orientation == .landscapeRight
                    : (UIApplication.shared.windows.first?.windowScene?.interfaceOrientation)! == .landscapeRight
            } else {
                return UIDevice.current.orientation.isValidInterfaceOrientation
                    ? UIDevice.current.orientation == .landscapeRight
                    : UIApplication.shared.statusBarOrientation == .landscapeRight
            }
        }
    }
}
