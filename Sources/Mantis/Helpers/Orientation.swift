//
//  OrientationExtensions.swift
//  Mantis
//
//  Created by Echo on 10/10/20.
//
import UIKit

public struct Orientation {
    
    static var interfaceOrientation: UIInterfaceOrientation {
        return (application.windows.first?.windowScene?.interfaceOrientation)!
    }
    
    static var deviceOrientation: UIDeviceOrientation? {
        device.orientation.isValidInterfaceOrientation
            ? device.orientation
            : nil
    }
    
    
    private static var application: UIApplication { .shared }
    
    private static var device: UIDevice { .current }
    
    
    /**
     Whether or not the device is in landscape orientation.
     */
    public static var isLandscape: Bool {
        device.orientation.isValidInterfaceOrientation
            ? device.orientation.isLandscape
            : interfaceOrientation.isLandscape
        
    }
    
    /**
     Whether or not the device is in landscape left orientation.
     */
    public static var isLandscapeLeft: Bool {
        device.orientation.isValidInterfaceOrientation
            ? device.orientation == .landscapeLeft
            : interfaceOrientation == .landscapeLeft
    }
    
    /**
     Whether or not the device is in landscape right orientation.
     */
    public static var isLandscapeRight: Bool {
        device.orientation.isValidInterfaceOrientation
            ? device.orientation == .landscapeRight
            : interfaceOrientation == .landscapeRight
    }
    
    /**
     Whether or not the device is in portrait orientation.
     */
    public static var isPortrait: Bool {
        device.orientation.isValidInterfaceOrientation
            ? device.orientation.isPortrait
            : interfaceOrientation.isPortrait
    }
}
