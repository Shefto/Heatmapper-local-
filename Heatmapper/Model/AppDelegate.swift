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
import IQKeyboardManagerSwift
import CloudKit
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

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

    // enable IQKeyboardManager
    IQKeyboardManager.shared.enable = true


    // handle user notifications
    let notificationCenter = UNUserNotificationCenter.current()
    notificationCenter.requestAuthorization(options: [.badge, .sound, .alert], completionHandler: { granted, error in

      if let error = error {
        MyFunc.logMessage(.error, "Error requesting authorization: \(error.localizedDescription)")
      }
    })

    UNUserNotificationCenter.current().delegate = self

    application.registerForRemoteNotifications()

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

  func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {

    print("didReceiveRemoteNotification called")
    let notification: CKNotification = CKNotification(fromRemoteNotificationDictionary: userInfo as! [String : NSObject])!

    if (notification.notificationType ==
        CKNotification.NotificationType.query) {

      let queryNotification =
      notification as! CKQueryNotification

      let recordID = queryNotification.recordID
      MyFunc.logMessage(.debug, "record created with recordId: \(String(describing: recordID?.recordName))")

//      let keyWindow = UIApplication.shared.windows.first { $0.isKeyWindow }
//      let viewController = keyWindow?.rootViewController as! ViewController
//
//      //      let viewController: ViewController = self.window?.rootViewController as! ViewController
//      viewController.fetchRecord(recordID!)
    }
  }

//  func application(_ application: UIApplication, userDidAcceptCloudKitShareWith cloudKitShareMetadata: CKShare.Metadata) {
//
//    let acceptSharesOperation =
//    CKAcceptSharesOperation(shareMetadatas: [cloudKitShareMetadata])
//    acceptSharesOperation.perShareCompletionBlock = {
//      metadata, share, error in
//      if error != nil {
//        print(error?.localizedDescription)
//      } else {
//        let viewController: ViewController =
//        self.window?.rootViewController as! ViewController
//        viewController.fetchShare(cloudKitShareMetadata)
//      }
//    }
//    CKContainer(identifier:
//                  cloudKitShareMetadata.containerIdentifier).add(
//                    acceptSharesOperation)
//  }

  func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
    let userInfo = response.notification.request.content.userInfo
    MyFunc.logMessage(.debug, "userInfo: \(userInfo.debugDescription)")
  }
}
