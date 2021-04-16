//
//  MainMenuViewController.swift
//  Heatmapper
//
//  Created by Richard English on 09/09/2020.
//  Copyright © 2020 Richard English. All rights reserved.
//

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
  let settingsImage                = UIImage(systemName: "gearshape")

  @IBOutlet weak var autoDetectButton: ThemeButton!
  @IBOutlet weak var flatSetsButton: ThemeButton!
  @IBOutlet weak var pyramidSetsButton: ThemeButton!
  @IBOutlet weak var tabataButton: ThemeButton!
  @IBOutlet weak var customButton: ThemeButton!
  @IBOutlet weak var randomButton: ThemeButton!
  @IBOutlet weak var matchButton: ThemeButton!

  var bannerView: GADBannerView!

  var activityType = ActivityType()

  @IBAction func btnMatch(_ sender: Any) {
  }
  
  @IBAction func settingsButton() {
    self.performSegue(withIdentifier: "startToSettings", sender: .none)
  }

  @IBAction func btnTabata(_ sender: Any) {
    activityType = ActivityType.tabata
    performSegue(withIdentifier: "mainMenuToSetIntervals", sender: activityType)
  }

  @IBAction func btnRepeat(_ sender: Any) {
    activityType = ActivityType.repeat
    performSegue(withIdentifier: "mainMenuToSetIntervals", sender: activityType)
  }

  @IBAction func btnPyramid(_ sender: Any) {
    activityType = ActivityType.pyramid
    performSegue(withIdentifier: "mainMenuToSetIntervals", sender: activityType)
  }

  @IBAction func btnCustom(_ sender: Any) {
    activityType = ActivityType.custom
    performSegue(withIdentifier: "mainMenuToSetIntervals", sender: activityType)
  }

  @IBAction func btnRandom(_ sender: Any) {
    activityType = ActivityType.random
    performSegue(withIdentifier: "mainMenuToSetIntervals", sender: activityType)
  }

  @IBAction func btnAuto(_ sender: Any) {
    activityType = ActivityType.auto
    performSegue(withIdentifier: "mainMenuToWorkout", sender: activityType)
  }

  override func viewWillAppear(_ animated: Bool) {
    if MyFunc.removeAdsPurchased() == false {
      // In this case, we instantiate the banner with desired ad size.
      bannerView = GADBannerView(adSize: kGADAdSizeBanner)
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

    loadUI()
    // set VC as CLLocationManager delegate
    locationManager.delegate = self
    authorizeLocation()
    authorizeHealthKit()

    // set up defaults

  }

  func loadUI() {

    autoDetectButton.backgroundColor = UIColor(named: "autoDetect")!
    autoDetectButton.titleLabel?.textAlignment = .center
    autoDetectButton.titleLabel?.adjustsFontSizeToFitWidth = true
    autoDetectButton.titleLabel?.numberOfLines = 2
    autoDetectButton.titleLabel?.minimumScaleFactor = 0.5

    flatSetsButton.titleLabel?.textAlignment = .center
    flatSetsButton.titleLabel?.adjustsFontSizeToFitWidth = true
    flatSetsButton.titleLabel?.minimumScaleFactor = 0.5
    flatSetsButton.titleLabel?.numberOfLines = 2

    tabataButton.titleLabel?.textAlignment = .center
    tabataButton.titleLabel?.adjustsFontSizeToFitWidth = true
    tabataButton.titleLabel?.numberOfLines = 1
    tabataButton.titleLabel?.minimumScaleFactor = 0.5

    customButton.titleLabel?.textAlignment = .center
    customButton.titleLabel?.adjustsFontSizeToFitWidth = true
    customButton.titleLabel?.numberOfLines = 1
    customButton.titleLabel?.minimumScaleFactor = 0.5

    randomButton.titleLabel?.textAlignment = .center
    randomButton.titleLabel?.adjustsFontSizeToFitWidth = true
    randomButton.titleLabel?.numberOfLines = 1
    randomButton.titleLabel?.minimumScaleFactor = 0.5

    pyramidSetsButton.titleLabel?.textAlignment = .center
    pyramidSetsButton.titleLabel?.adjustsFontSizeToFitWidth = true
    //    pyramidSetsButton.titleLabel?.numberOfLines = 1
    pyramidSetsButton.titleLabel?.minimumScaleFactor = 0.5

    self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: settingsImage, style: .plain, target: self, action: #selector(self.settingsButton))

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
                                                   HKObjectType.activitySummaryType()
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

  }

  func authorizeLocation() {

    let locationStatus = locationManager.authorizationStatus

    switch locationStatus {
    case .authorizedAlways, .authorizedWhenInUse:
      logger.debug("location use authorized : Status = \(String(describing: locationStatus.rawValue))")
    case .denied, .notDetermined, .restricted:
      logger.debug("location use not authorized : Status = \(String(describing: locationStatus.rawValue))")
      locationManager.requestAlwaysAuthorization()
    default:
      logger.debug("location use status not known : \(String(describing: locationStatus.rawValue))")
    }

    locationManager.allowsBackgroundLocationUpdates = true
  }

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
  func adView(_ bannerView: GADBannerView,
              didFailToReceiveAdWithError error: GADRequestError) {
    print("adView:didFailToReceiveAdWithError: \(error.localizedDescription)")
  }

  /// Tells the delegate that a full-screen view will be presented in response
  /// to the user clicking on an ad.
  func adViewWillPresentScreen(_ bannerView: GADBannerView) {
    print("adViewWillPresentScreen")
  }

  /// Tells the delegate that the full-screen view will be dismissed.
  func adViewWillDismissScreen(_ bannerView: GADBannerView) {
    print("adViewWillDismissScreen")
  }

  /// Tells the delegate that the full-screen view has been dismissed.
  func adViewDidDismissScreen(_ bannerView: GADBannerView) {
    print("adViewDidDismissScreen")
  }

  /// Tells the delegate that a user click will open another app (such as
  /// the App Store), backgrounding the current app.
  func adViewWillLeaveApplication(_ bannerView: GADBannerView) {
    print("adViewWillLeaveApplication")
  }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

    let segueToUse = segue.identifier

    if segueToUse == "mainMenuToSetIntervals" {
      let destinationVC = segue.destination as! SetIntervalsViewController
      destinationVC.activityType = activityType
    }

    if segueToUse == "mainMenuToWorkout" {
      let destinationVC = segue.destination as! WorkoutViewController
      destinationVC.activityType = activityType
    }

    navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)

  }


  func setDefaultUnits () {

    let unitDefault = defaults.object(forKey: "Units") as? String
    if unitDefault  == "" {
      //if not, set the default now
      var units = ""
      if locale.usesMetricSystem == true {
        units = "km/h"
      } else {
        units = "mph"
      }
      defaults.set(units, forKey: "Units")
      updateApplicationContextForUserDefault(["Units": units])
    }

  }

  func setDefaultVibration () {

    let vibrationDefault = defaults.object(forKey: "Vibration") as? String
    if vibrationDefault  == "" {
      //if not, set the default now

      let vibration = "On"
      defaults.set(vibration, forKey: "Vibration")
      updateApplicationContextForUserDefault(["Vibration": vibration])
    }

  }

  func setDefaultLocation () {
    let locationDefault = defaults.object(forKey: "Location") as? String

    switch locationDefault {
    case "Balanced":
      locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
    case "Accuracy":
      locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
    case "Battery":
      locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    default:
      locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
      let location = "Balanced"
      defaults.set(location, forKey: "Location")
      updateApplicationContextForUserDefault(["Location": location])
    }

  }


}
