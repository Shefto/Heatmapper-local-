//
//  AppDelegate.swift
//  Heatmapper
//
//  Created by Richard English on 22/06/2020.
//  Copyright © 2020 Richard English. All rights reserved.
//

import UIKit
import WatchConnectivity
//import GoogleMobileAds
import HealthKit
import os

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  let logger = Logger()

  // get ThemeKit theme
  let theme = ColourTheme()

  var window: UIWindow?

  private lazy var sessionDelegator: SessionDelegator = {
    return SessionDelegator()
  }()

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

    LocationManager.sharedInstance.startUpdatingLocation()

    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    let documentsDirectory = paths[0]
    let documentsDirectoryStr = String(describing: documentsDirectory)
    let indexStartOfText = documentsDirectoryStr.index(documentsDirectoryStr.startIndex, offsetBy: 7)
    let documentsDirectorySubstr = documentsDirectoryStr[indexStartOfText...]
    print("documentsDirectory: \(documentsDirectorySubstr)")

    // Trigger WCSession activation at the early phase of app launching.
    assert(WCSession.isSupported(), "This app requires Watch Connectivity support")
    WCSession.default.delegate = sessionDelegator
    WCSession.default.activate()

    // Remind the setup of WatchSettings.sharedContainerID.
    if WatchSettings.sharedContainerID.isEmpty {
      logger.info("Specify a shared container ID for WatchSettings.sharedContainerID to use watch settings")
    }

    // apply colour theme
    theme.apply(for: application)
    return true

  }

  // MARK: UISceneSession Lifecycle

  func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
    // Called when a new scene session is being created.

    return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
  }

  func applicationShouldRequestHealthAuthorization(_ application: UIApplication) {
    let healthStore = HKHealthStore()
    healthStore.handleAuthorizationForExtension{ (success, error) -> Void in

      guard success else {
        MyFunc.logMessage(.error, "Error in AppDelegate.swift applicationShouldRequestHealthAuthorization: \(String(describing: error))")
        return
      }
    }
  }

}
