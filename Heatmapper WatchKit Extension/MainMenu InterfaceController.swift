//
//  MainMenuInterfaceController.swift
//  Heatmapper WatchKit Extension
//
//  Created by Richard English on 05/10/2020.
//  Copyright © 2020 Richard English. All rights reserved.
//

import WatchKit
import HealthKit
import os
import CoreLocation

class MainMenuInterfaceController: WKInterfaceController, CLLocationManagerDelegate {

  let logger = Logger(subsystem: "wimbledonappcompany.com.Heatmapper.watchkitapp.watchkitextension", category: "MainMenuInterfaceController")
  var countdownTimeLeft: TimeInterval = 3.1
  var countdownEndTime: Date?
  var countdownTimer = Timer()
//  let audio = Audio()
  var buttonJustPressed : Bool = false

  // HealthKit variables
  private let healthStore      = HKHealthStore()
  // Core Location variables

  let locationManager          = CLLocationManager()

  override func awake(withContext context: Any?) {
    super.awake(withContext: context)
  }

  @IBAction func btnStart() {

    pushController(withName: "Countdown Interface Controller", context: nil)

  }

  override func didAppear() {

    authorizeHealth()
    authorizeLocation()

    // set VC as CLLocationManager delegate

    locationManager.delegate = self
    locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
    locationManager.activityType = .fitness
    locationManager.distanceFilter = 5
    locationManager.allowsBackgroundLocationUpdates = true
    locationManager.startUpdatingLocation()

  }

  func authorizeHealth() {

    // create Set for writing to HealthStore
    let typesToShare: Set = [
      HKQuantityType.workoutType(),
      HKSeriesType.workoutRoute()
    ]

    // create Set for reading from HealthStore
    let typesToRead: Set = [
      HKQuantityType.quantityType(forIdentifier: .heartRate)!,
      HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
      HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!,
      HKQuantityType.quantityType(forIdentifier: .heartRate)!
    ]

    // ask for authorization to read / write from Health Store
    healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead, completion: {(_, _) in })

  }

  func authorizeLocation() {

    let locationStatus = locationManager.authorizationStatus
    switch locationStatus {
    case .authorizedAlways:
      MyFunc.logMessage(.default, "Location authorizationStatus = authorizedAlways")
    case .authorizedWhenInUse:
      MyFunc.logMessage(.default, "Location authorizationStatus = authorizedWhenInUse")
    case .denied:
      MyFunc.logMessage(.default, "Location authorizationStatus = denied")
      locationManager.requestWhenInUseAuthorization()
    case .notDetermined:
      MyFunc.logMessage(.default, "Location authorizationStatus = notDetermined")
      locationManager.requestWhenInUseAuthorization()
    case .restricted:
      MyFunc.logMessage(.default, "Location authorizationStatus = restricted")
      locationManager.requestWhenInUseAuthorization()
    default:
      MyFunc.logMessage(.default, "Location authorizationStatus not recognized")
      locationManager.requestWhenInUseAuthorization()
    }

    locationManager.allowsBackgroundLocationUpdates = true

  } // func authorizeLocation

  func preventMultiplePresses() {

    if buttonJustPressed == true {
      MyFunc.logMessage(.debug, "buttonJustPressed prevented multiple clicks")
      return
    }
    // after 3 seconds, activate it again
    DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3)) {
      self.buttonJustPressed = false
    }
  }

}
