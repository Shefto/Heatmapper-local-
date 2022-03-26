//
//  MainMenuViewController.swift
//  Heatmapper
//
//  Created by Richard English on 09/09/2020.
//  Copyright © 2020 Richard English. All rights reserved.

import AVFoundation
import CoreLocation
import HealthKit
import os
import UIKit
import GoogleMobileAds

class MainMenuViewController: UIViewController, CLLocationManagerDelegate, GADBannerViewDelegate, SessionCommands {

  let logger = Logger(subsystem: "com.wimbledonappcompany.Heatmapper", category: "StartViewController")
  let theme = ColourTheme()

  let locale = Locale.current
  let defaults = UserDefaults.standard

  // HealthKit variables
  private let healthStore         = HKHealthStore()
  let workoutConfiguration        = HKWorkoutConfiguration()
  var builder: HKWorkoutBuilder!

  // Core Location variables
  let locationManager             = CLLocationManager()
  let settingsImage               = UIImage(systemName: "gearshape")

  var bannerView: GADBannerView!

  @IBAction func btnHistory(_ sender: Any) {
    performSegue(withIdentifier: "mainMenuToHistory", sender: .none)
  }

  @IBAction func btnMatch(_ sender: Any) {
    performSegue(withIdentifier: "mainMenuToTracker", sender: .none)
  }
  
  @IBAction func btnSettings(_ sender: Any) {
    performSegue(withIdentifier: "mainMenuToSettings", sender: .none)
  }


  @IBAction func btnReferenceData(_ sender: Any) {
    performSegue(withIdentifier: "mainMenuToReferenceData", sender: .none)
  }

  @IBAction func btnPlayingAreas(_ sender: Any) {
    performSegue(withIdentifier: "mainMenuToPlayingAreas", sender: .none)
  }

  @IBAction func btnTeams(_ sender: Any) {
    performSegue(withIdentifier: "mainMenuToTeams", sender: .none)
  }


  override func viewWillAppear(_ animated: Bool) {
    if MyFunc.removeAdsPurchased() == false {
      // In this case, we instantiate the banner with desired ad size.
      bannerView = GADBannerView(adSize: GADAdSizeBanner)
      bannerView.delegate = self
      addBannerViewToView(bannerView)
      // line to swap in when testing
      //    bannerView.adUnitID =  "/6499/example/banner"
      bannerView.adUnitID = "ca-app-pub-2779736734695934/6901269940"

      bannerView.rootViewController = self
      bannerView.load(GADRequest())

    } else {
      if bannerView != nil {
        bannerView.isHidden = true
      }
    }

  }

  override func viewDidLoad() {
    super.viewDidLoad()

    locationManager.delegate = self

    loadUI()
    authorizeLocation()
    authorizeHealthKit()

  }

  func loadUI() {

    self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: settingsImage, style: .plain, target: self, action: #selector(self.btnSettings))

  }

  func authorizeHealthKit() {

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

    let healthKitTypesToRead: Set<HKObjectType> = [heartRate,
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

    if typeAuthStatus != .sharingAuthorized  {
      MyFunc.logMessage(.debug, "typeAuthStatus:\(typeAuthStatus.rawValue)")
      healthKitTypesToWrite.insert(HKObjectType.workoutType())
      healthKitTypesToWrite.insert(HKSeriesType.workoutType())
      healthKitTypesToWrite.insert(HKSeriesType.workoutRoute())
    }

    if routeAuthStatus != .sharingAuthorized {
      MyFunc.logMessage(.debug, "routeAuthStatus:\(routeAuthStatus.rawValue)")
      healthKitTypesToWrite.insert(HKObjectType.workoutType())
      healthKitTypesToWrite.insert(HKSeriesType.workoutType())
      healthKitTypesToWrite.insert(HKSeriesType.workoutRoute())

    }

    //4. Request Authorization
    HKHealthStore().requestAuthorization(toShare: healthKitTypesToWrite, read: healthKitTypesToRead) { (success, error) in

      guard success else {
        self.logger.error("Error in HealthKitSetupAssistant requesting HealthKit Authorization: \(String(describing: error))")
        return
      }
      MyFunc.logMessage(.debug, "MainMenuViewController requestAuthorization success: \(success)")
    }

  }

  func authorizeLocation() {

    let locationStatus = locationManager.authorizationStatus

    switch locationStatus {
    case .authorizedAlways, .authorizedWhenInUse:
      logger.debug("Location use authorized : Status = \(String(describing: locationStatus.rawValue))")
    case .denied, .notDetermined, .restricted:
      logger.debug("Location use not authorized : Status = \(String(describing: locationStatus.rawValue))")
      locationManager.requestAlwaysAuthorization()
    default:
      logger.debug("Location use status not known : \(String(describing: locationStatus.rawValue))")
    }
    locationManager.allowsBackgroundLocationUpdates = true
  }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
  }


  //MARK: Google AdMob functions
  func addBannerViewToView(_ bannerView: GADBannerView) {
    bannerView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(bannerView)
    view.addConstraints(
      [NSLayoutConstraint(item: bannerView,
                          attribute: .top,
                          relatedBy: .equal,
                          toItem: view.safeAreaLayoutGuide,
                          attribute: .top,
                          multiplier: 1,
                          constant: 0),
       NSLayoutConstraint(item: bannerView,
                          attribute: .centerX,
                          relatedBy: .equal,
                          toItem: view,
                          attribute: .centerX,
                          multiplier: 1,
                          constant: 0)
      ])
  }

  /// Tells the delegate an ad request loaded an ad.
  func adViewDidReceiveAd(_ bannerView: GADBannerView) {
    print("adViewDidReceiveAd")
  }

  /// Tells the delegate an ad request failed.
  private func adView(_ bannerView: GADBannerView,
              didFailToReceiveAdWithError error: Error) {
    print("adView:didFailToReceiveAdWithError: \(error.localizedDescription)")
  }

  /// Tells the delegate that a full-screen view will be presented in response
  /// to the user clicking on an ad.
  private func adViewWillPresentScreen(_ bannerView: GADBannerView) {
    print("adViewWillPresentScreen")
  }

  /// Tells the delegate that the full-screen view will be dismissed.
  private func adViewWillDismissScreen(_ bannerView: GADBannerView) {
    print("adViewWillDismissScreen")
  }

  /// Tells the delegate that the full-screen view has been dismissed.
  private func adViewDidDismissScreen(_ bannerView: GADBannerView) {
    print("adViewDidDismissScreen")
  }

  /// Tells the delegate that a user click will open another app (such asthe App Store), backgrounding the current app.
  func adViewWillLeaveApplication(_ bannerView: GADBannerView) {
    print("adViewWillLeaveApplication")
  }

}
