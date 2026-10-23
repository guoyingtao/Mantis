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

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        return true
    }

    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        configuration.delegateClass = SceneDelegate.self
        return configuration
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
}

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        window = UIWindow(windowScene: windowScene)
        window?.rootViewController = UINavigationController(rootViewController: DemoViewController())
        window?.makeKeyAndVisible()
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
