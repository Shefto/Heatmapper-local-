//
//  AppDelegate.swift
//  FIT
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

    //1. Check to see if HealthKit Is Available on this device
    guard HKHealthStore.isHealthDataAvailable() else {
      logger.critical("HealthKit not available on device")
      return
    }

    //2. Prepare the data types that will interact with HealthKit
    guard   let distanceWalkingRunning = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning),
            let basalEnergy = HKObjectType.quantityType(forIdentifier: .basalEnergyBurned),
            let heartRate = HKObjectType.quantityType(forIdentifier: .heartRate),
            let activeEnergy = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned),
            let stepCount = HKObjectType.quantityType(forIdentifier: .stepCount)
    else {

      logger.critical("HealthKit data types not available on device")
      return
    }

    //3. Prepare a list of types you want HealthKit to read and write
    var healthKitTypesToWrite: Set<HKSampleType> = []

    let healthKitTypesToRead: Set<HKObjectType> = [
                                                   heartRate,
                                                   activeEnergy,
                                                   basalEnergy,
                                                   stepCount,
                                                   distanceWalkingRunning,
                                                   HKObjectType.activitySummaryType(),
                                                   HKObjectType.workoutType(),
                                                   HKSeriesType.workoutRoute()
    ]

    let activeEnergyAuthStatus = healthStore.authorizationStatus(for: activeEnergy)
    let basalEnergyAuthStatus = healthStore.authorizationStatus(for: basalEnergy)
    let heartRateAuthStatus = healthStore.authorizationStatus(for: heartRate)
    let stepCountAuthStatus = healthStore.authorizationStatus(for: stepCount)
    let distanceAuthStatus = healthStore.authorizationStatus(for: distanceWalkingRunning)
    let typeAuthStatus = healthStore.authorizationStatus(for: HKObjectType.workoutType())
    let routeAuthStatus = healthStore.authorizationStatus(for: HKSeriesType.workoutRoute())

    if activeEnergyAuthStatus != .sharingAuthorized {
      healthKitTypesToWrite.insert(activeEnergy)
    }

    if basalEnergyAuthStatus != .sharingAuthorized {
      healthKitTypesToWrite.insert(basalEnergy)
    }
    if heartRateAuthStatus != .sharingAuthorized {
      healthKitTypesToWrite.insert(heartRate)
    }
    if stepCountAuthStatus != .sharingAuthorized {
      healthKitTypesToWrite.insert(stepCount)
    }
    if distanceAuthStatus != .sharingAuthorized {
      healthKitTypesToWrite.insert(distanceWalkingRunning)
    }

    if typeAuthStatus != .sharingAuthorized {
      healthKitTypesToWrite.insert(HKObjectType.workoutType())
      healthKitTypesToWrite.insert(HKSeriesType.workoutRoute())
    }

    if routeAuthStatus != .sharingAuthorized {
      healthKitTypesToWrite.insert(HKObjectType.workoutType())
      healthKitTypesToWrite.insert(HKSeriesType.workoutRoute())
    }

    //4. Request Authorization
    HKHealthStore().requestAuthorization(toShare: healthKitTypesToWrite, read: healthKitTypesToRead) { (success, error) in

      guard success else {
        self.logger.error("Error in HealthKitSetupAssistant requesting HealthKit Authorization: \(String(describing: error))")
        return
      }
      self.logger.info("Successful Authorization of HealthKit")
    }

    logger.info("HealthKit successfully authorized")

  }

}
