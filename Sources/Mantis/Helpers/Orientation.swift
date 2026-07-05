//
//  OrientationExtensions.swift
//  Mantis
//
//  Created by Echo on 10/10/20.
//
import UIKit

public struct Orientation {
    static var interfaceOrientation: UIInterfaceOrientation {
        let windowScenes = application.connectedScenes.compactMap { $0 as? UIWindowScene }
        let activeScene = windowScenes.first { scene in
            scene.windows.first(where: { $0.isKeyWindow }) != nil
        }
            ?? windowScenes.first { $0.activationState == .foregroundActive }
            ?? windowScenes.first
    }
        
    private static var application: UIApplication { .shared }
    
    /**
     Whether or not the interface is in landscape orientation.
     */
    public static var isLandscape: Bool {
        interfaceOrientation.isLandscape
    }
    
    /**
     Whether or not the interface is in landscape left orientation.
     */
    public static var isLandscapeLeft: Bool {
        interfaceOrientation == .landscapeLeft
    }
    
    /**
     Whether or not the interface is in landscape right orientation.
     */
    public static var isLandscapeRight: Bool {
        interfaceOrientation == .landscapeRight
    }
    
    /**
     Whether or not the interface is in portrait orientation.
     */
    public static var isPortrait: Bool {
        interfaceOrientation.isPortrait
    }
    
    /**
     Whether or not the interface is treated as in portrait orientation.
     For devices other than iPhone, they have enough space for landscape orientation, so we can always use portait layout for them.
     */
    public static var treatAsPortrait: Bool {
        interfaceOrientation.isPortrait || UIDevice.current.userInterfaceIdiom != .phone
    }
}
