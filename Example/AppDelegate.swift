//
//  AppDelegate.swift
//  Mantis
//
//  Created by Yingtao Guo on 10/19/18.
//  Copyright © 2018 Echo Studio. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        
        let rootVC = UINavigationController(rootViewController: DemoViewController())
        window?.rootViewController = rootVC
        
        window?.makeKeyAndVisible()
        
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
}

extension AppDelegate {
    
    override func buildMenu(with builder: UIMenuBuilder) {
        super.buildMenu(with: builder)
        
        // Ensure that the builder is modifying the menu bar system.
        guard builder.system == UIMenuSystem.main else { return }
        
        // remove items from Edit menu
        builder.remove(menu: .undoRedo)
        
        // Undo
        let undoCommand = UIKeyCommand(title: "Undo",
                                       action: #selector(EmbeddedCropViewController.undoButtonPressed(_:)),
                                       input: "z",
                                       modifierFlags: [.command])
        
        // Redo
        let redoCommand = UIKeyCommand(title: "Redo",
                                       action: #selector(EmbeddedCropViewController.redoButtonPressed(_:)),
                                       input: "z",
                                       modifierFlags: [.shift, .command])
        
        // Revert
        let revertCommand = UIKeyCommand(title: "Revert to Original",
                                         action: #selector(EmbeddedCropViewController.resetButtonPressed(_:)),
                                         input: "r",
                                         modifierFlags: [.alternate])
        
        let undoMenu = UIMenu(title: "", identifier: .undoRedo, options: .displayInline, children: [undoCommand, redoCommand, revertCommand ])
        
        builder.insertChild(undoMenu, atStartOfMenu: .edit)
        
    }
}
