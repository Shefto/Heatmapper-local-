//
//  MainMenuInterfaceController.swift
//  FIT WatchKit Extension
//
//  Created by Richard English on 05/10/2020.
//  Copyright © 2020 Richard English. All rights reserved.
//

import WatchKit
import HealthKit
import os
import CoreLocation

class MainMenuInterfaceController: WKInterfaceController, CLLocationManagerDelegate {

  let logger = Logger(subsystem: "wimbledonappcompany.com.FIT.watchkitapp.watchkitextension", category: "MainMenuInterfaceController")
  var countdownTimeLeft: TimeInterval = 3.1
  var countdownEndTime: Date?
  var countdownTimer = Timer()
  let audio = Audio()
  var buttonJustPressed : Bool = false

  // HealthKit variables
  private let healthStore                 = HKHealthStore()

  // Core Location variables
  let locationManager             = CLLocationManager()

  @IBOutlet weak var flatSetsButtonLabel: WKInterfaceLabel!
  @IBOutlet weak var automaticButton: MyWKInterfaceButton!
  @IBOutlet weak var tabataButton: WKInterfaceButton!
  @IBOutlet weak var customButton: WKInterfaceButton!
  @IBOutlet weak var randomButton: WKInterfaceButton!
  @IBOutlet weak var repeatSetButton: WKInterfaceButton!
  @IBOutlet weak var countdownTimerLabel: WKInterfaceLabel!
  @IBOutlet weak var pyramidButton: WKInterfaceButton!

  override func awake(withContext context: Any?) {


  }

  @IBAction func btnPyramid() {
    let contextToSend =  MyFunc.setContext(.pyramid, .none)
    pushController(withName: "Set Intervals Interface Controller", context: contextToSend)
  }

  // IBActions

  @IBAction func btnAutomatic() {
    preventMultiplePresses()

    let contextToSend =  MyFunc.setContext(.auto, .none)
    pushController(withName: "Countdown Interface Controller", context: contextToSend)
  }

  @IBAction func btnTabata() {
    preventMultiplePresses()
    let contextToSend =  MyFunc.setContext(.tabata, .none)
    pushController(withName: "Set Intervals Interface Controller", context: contextToSend)
  }

  @IBAction func btnRandom() {
    preventMultiplePresses()
    let contextToSend =  MyFunc.setContext(.random, .none)
    pushController(withName: "Set Intervals Interface Controller", context: contextToSend)
  }

  @IBAction func btnRepeat() {
    preventMultiplePresses()
    let contextToSend =  MyFunc.setContext(.repeat, .none)
    pushController(withName: "Set Intervals Interface Controller", context: contextToSend)
  }

  @IBAction func btnCustom() {
    preventMultiplePresses()
    let contextToSend =  MyFunc.setContext(.custom, .none)
    pushController(withName: "Custom Intervals Interface Controller", context: contextToSend)

  }

  override func didAppear() {

    authorizeHealth()
    authorizeLocation()

    // set VC as CLLocationManager delegate
    locationManager.delegate = self
    locationManager.startUpdatingLocation()

    automaticButton.setHidden(false)
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
      locationManager.requestAlwaysAuthorization()
    case .notDetermined:
      MyFunc.logMessage(.default, "Location authorizationStatus = notDetermined")
      locationManager.requestAlwaysAuthorization()
    case .restricted:
      MyFunc.logMessage(.default, "Location authorizationStatus = restricted")
      locationManager.requestAlwaysAuthorization()
    default:
      MyFunc.logMessage(.default, "Location authorizationStatus not recognized")
      locationManager.requestAlwaysAuthorization()
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
