//
//  AppDelegate.swift
//  TiledGame
//
//  Created by 許雅筑 on 2016/10/16.
//  Copyright © 2016年 hsu.ya.chu. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import FBSDKLoginKit
import Firebase
import SpriteKit
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
//        return true
        FIRApp.configure()
        return FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    func application(application:UIApplication,openURL url: NSURL,sourceApplication: String?,annotation: AnyObject) -> Bool{
        return FBSDKApplicationDelegate.sharedInstance().application(application,
                                                                     openURL: url, sourceApplication: sourceApplication, annotation: annotation)
    }
    func applicationWillResignActive(application: UIApplication) {
 
    }

    func applicationDidEnterBackground(application: UIApplication) {

    }

    func applicationWillEnterForeground(application: UIApplication) {

    }

    func applicationDidBecomeActive(application: UIApplication) {
     
    }

    func applicationWillTerminate(application: UIApplication) {
   
    }


}

