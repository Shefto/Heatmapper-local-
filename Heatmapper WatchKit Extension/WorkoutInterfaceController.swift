//
//  WorkoutInterfaceController.swift
//  Heatmapper WatchKit Extension
//
//  Created by Richard English on 08/07/2020.
//  Copyright © 2020 Richard English. All rights reserved.
//

//import AVFoundation
import CoreLocation
import CoreMotion
import HealthKit

import WatchConnectivity
import WatchKit

protocol WorkoutManagerDelegate {
  func updateLabel(_ label: WKInterfaceLabel?, withStatistics statistics: HKStatistics?)
  func labelForQuantityType(_ type: HKQuantityType) -> WKInterfaceLabel?
}

class WorkoutInterfaceController: WKInterfaceController, DataProvider, SessionCommands, /*CLLocationManagerDelegate,*/ WorkoutManagerDelegate {

  // WatchConnectivity variables
  private var command: Command!
  private let fileTransferObservers = FileTransferObservers()
  
  // Units default - these will be retrieved during initialisation
  var units                 : String      = ""
  var unitLength            : UnitLength  = .meters
  var unitSpeed             : UnitSpeed   = .metersPerSecond
  var measurementFormatter                = MeasurementFormatter()

  var vibrateWatch : String = ""

  // HealthKit variables
  let workoutManager = WorkoutManager()
  var routeBuilder: HKWorkoutRouteBuilder!

  // timer variables
  let workoutTimer                = Stopwatch()
  var isRunning                   = true
  var intervalTimer               = Timer()

  // Workout variables
  var workoutStartDate: Date?
  var workoutEndDate: Date?
  var workoutPausedDate: Date?
  var workoutDurationTimeInterval: TimeInterval = 0

  // Interval variables
  private var intervalStartDate : Date?
  private var intervalEndDate : Date?
  var intervalDurationDateInterval : DateInterval?
  var intervalDurationTimeInterval : TimeInterval = 0

  let pedometer                   = CMPedometer()

  // log variables
  var log: String = ""
  let fileDateFormatter           = DateFormatter()
  let numberFormatter             = NumberFormatter()

  @IBOutlet weak var distanceLabel: WKInterfaceLabel!
  @IBOutlet weak var paceLabel: WKInterfaceLabel!
  @IBOutlet weak var currentPace: WKInterfaceLabel!
  @IBOutlet weak var currentDistance: WKInterfaceLabel!
  @IBOutlet weak var locationLabel: WKInterfaceLabel!

  @IBOutlet weak var workoutDurationLabel: WKInterfaceLabel!
  @IBOutlet weak var heartRateLabel: WKInterfaceLabel!
  @IBOutlet weak var activeCaloriesLabel: WKInterfaceLabel!

  @IBOutlet weak var centreGroup: WKInterfaceGroup!

  override init() {
    
    super.init()
    
    // set date format for logging
    fileDateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
    
    // check if default units have been set up
    let locale = Locale.current
    let defaults = UserDefaults.standard
    
    units = defaults.object(forKey: "Units") as? String ?? ""
    if units  == "" {
      //if not, set the default now
      if locale.usesMetricSystem == true {
        units = "km/h"
      } else {
        units = "mph"
      }
      defaults.set(units, forKey: "Units")
      updateApplicationContextForUserDefault(["Units": units])
      unitSpeed = MyFunc.getDefaultsUnitSpeed()
      unitLength = MyFunc.getDefaultsUnitLength()
    }

    vibrateWatch = defaults.object(forKey: "Vibration") as? String ?? ""

    // get the locale for displaying metrics in km or mi
    measurementFormatter.locale = locale
    measurementFormatter.unitOptions = .naturalScale
    measurementFormatter.unitStyle = .medium
    measurementFormatter.numberFormatter.usesSignificantDigits = false
    measurementFormatter.numberFormatter.minimumIntegerDigits = 1
    measurementFormatter.numberFormatter.maximumFractionDigits = 2
    
    // ensure the timers are set to zero
    workoutTimer.stop()
    
  }
  
  override func awake(withContext context: Any?) {
    super.awake(withContext: nil)

    workoutManager.delegate = self
    loadUI()
    addNotificationObservers()
    startWorkout()

  }
  
  override func willActivate() {
    // This method is called when watch view controller is about to be visible to user
    super.willActivate()
    
    guard command != nil else { return } // For first-time loading do nothing.
    
    if command == .transferFile {
      let transferCount = WCSession.default.outstandingFileTransfers.count
      if transferCount > 0 {
        let commandStatus = CommandStatus(command: .transferFile, phrase: .finished)
        logOutstandingTransfers(for: commandStatus, outstandingCount: transferCount)
      }
    }
    
  }
  
  func startWorkout() {

    // start workout for Workout Manager
    workoutManager.startWorkout()
    LocationManager.sharedInstance.startUpdatingLocation()
    
    // check if pedometer data is available, if so start updates
    if CMPedometer.isPedometerEventTrackingAvailable() {
      pedometer.startEventUpdates(handler: { [weak self] (_, error) in
        // line below purely to silence warning when weak self used
        // weak self required to prevent strong relationship to pedometer object
        let selfSilencer = self
        MyFunc.logMessage(.info, String(describing: selfSilencer))

        if error != nil {
          MyFunc.logMessage(.error, "Error in FartlekInterfaceController startEventUpdates: \(String(describing: error))")
          
        }
        
      })
    }

    MyFunc.logMessage(.debug, "WorkoutInterfaceController.startWorkout : workoutTimer.start()")
    workoutTimer.start()

    workoutStartDate = Date()
    intervalStartDate = workoutStartDate
    intervalEndDate  = nil

    // intervalTimer controls the displayed Time
    intervalTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(WorkoutInterfaceController.updateWorkoutDurationLabel(_:)), userInfo: nil, repeats: true)

  } // func startWorkout

  func loadUI() {
    let durationFont = UIFont.monospacedSystemFont(ofSize: 16, weight: .regular)
    let durationText = NSAttributedString(string: "0.0", attributes: [NSAttributedString.Key.font: durationFont])
    workoutDurationLabel.setAttributedText(durationText)
  }

  func addNotificationObservers() {
    
    // Actions observers
    NotificationCenter.default.addObserver(self, selector: #selector(pauseWorkout), name: Notification.Name("Pause"), object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(endWorkout), name: Notification.Name("End"), object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(resumeWorkout), name: Notification.Name("Resume"), object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(lockScreen), name: Notification.Name("Lock"), object: nil)
    
    // WatchConnectivity observers
    NotificationCenter.default.addObserver(self, selector: #selector(type(of: self).activationDidComplete(_:)), name: .activationDidComplete, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(type(of: self).reachabilityDidChange(_:)), name: .reachabilityDidChange, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(type(of: self).dataDidFlow(_:)), name: .dataDidFlow, object: nil)
    
  }

  @objc func speakStartingWorkout(_ timer: Timer) {
    if workoutTimer.isRunning == true {
      //      let startPhraseLocalized = NSLocalizedString("Starting workout now", comment: "")
      //      audio.speak(phrase: startPhraseLocalized)
    }
  }
  
  @objc func endWorkout() {
    
    // set as current page
    DispatchQueue.main.async {
      self.becomeCurrentPage()
    }
    
    workoutTimer.stop()
    intervalTimer.invalidate()

    // if moving from paused to stopped state, mark the workout as having finished from the last pause
    if workoutManager.session.state == .paused {

      workoutEndDate = workoutPausedDate
    } else {
      workoutEndDate = Date()
    }


    // record the final interval and stop location and motion updates
    // for Heatmapper, this is the only function which adds samples
    addInterval(startDate: intervalStartDate!, endDate: workoutEndDate!, duration: workoutDurationTimeInterval)
    pedometer.stopUpdates()

    LocationManager.sharedInstance.stopUpdatingLocation()
    workoutManager.endDataCollection(date: Date())


    self.exportLog()

    let coordinateCount = LocationManager.sharedInstance.locationDataAsCoordinates.count
    let arrayCount = LocationManager.sharedInstance.locationDataArray.count

    let messageString = "Coordinates: \(coordinateCount) \n Array count: \(arrayCount)"
    DispatchQueue.main.async {
      self.displayAlert(title: "Workout saved", message: messageString)
            WKInterfaceController.reloadRootPageControllers(withNames: ["Main Menu Interface Controller"], contexts: [""], orientation: WKPageOrientation.horizontal, pageIndex: 0)
    }
    
    
  } // func endWorkout
  
  @objc func pauseWorkout() {
    
    // set as current page
    DispatchQueue.main.async {
      self.becomeCurrentPage()
    }
    
    workoutManager.pauseWorkout()
    //    session.pause()
    //    audio.stopSpeaking()
    //    let pausePhrase = NSLocalizedString("Workout paused", comment: "")
    //    audio.speak(phrase: pausePhrase)
    intervalTimer.invalidate()

    if workoutTimer.isRunning {
      workoutTimer.stop()
      workoutPausedDate = Date()
      intervalEndDate = workoutPausedDate
      // calculate the total time for this interval
      intervalDurationDateInterval = DateInterval(start: intervalStartDate!, end: intervalEndDate!)
      intervalDurationTimeInterval = intervalDurationDateInterval!.duration

      // add this to the overall workout duration
      workoutDurationTimeInterval +=  intervalDurationTimeInterval
    }

  }
  
  @objc func resumeWorkout() {
    
    // set as current page
    DispatchQueue.main.async {
      self.becomeCurrentPage()
    }
    //    audio.stopSpeaking()
    //    let resumePhraseLocalized = NSLocalizedString("Resuming workout", comment: "Resuming workout")
    //    audio.speak(phrase: resumePhraseLocalized)
    
    workoutManager.resumeWorkout()

    let workoutResumedDate = Date()
    intervalStartDate = workoutResumedDate

    workoutTimer.startFromDate(date: workoutResumedDate)

    intervalTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(updateWorkoutDurationLabel(_:)), userInfo: nil, repeats: true)

  } // @objc func resumeWorkout
  
  @objc func lockScreen() {

    // lock screen
    WKInterfaceDevice.current().enableWaterLock()
    // and immediately return to display the Workout Interface
    DispatchQueue.main.async {
      self.becomeCurrentPage()
    }
    
  }

  func displayAlert (title: String, message: String) {
    let nextController = "MainMenuInterfaceController"

    
    //Alert user that Save has worked
    let okAction = WKAlertAction(title: "OK", style: WKAlertActionStyle.default, handler: {
      DispatchQueue.main.async {
        self.pushController(withName: nextController, context: nil)
      }
    })

    DispatchQueue.main.async {
      WKExtension.shared().visibleInterfaceController?.presentAlert(withTitle: title, message: message, preferredStyle: WKAlertControllerStyle.alert, actions: [okAction])
      self.pushController(withName: nextController, context: nil)
    }
  }
  
  func addInterval(startDate: Date, endDate: Date!, duration: TimeInterval) {
    
    var newInterval         = Interval()
    newInterval.duration    = DateInterval(start: startDate, duration: duration)
    newInterval.startDate   = startDate
    newInterval.endDate     = endDate

    // get interval pace, steps and distance
    pedometer.queryPedometerData(from: startDate, to: endDate) {
      (pedometerData: CMPedometerData!, error) -> Void in

      if error == nil {
        newInterval.distance    = pedometerData.distance ?? 0
        newInterval.pace        = pedometerData.averageActivePace ?? 0
        newInterval.steps       = pedometerData.numberOfSteps
        newInterval.cadence     = pedometerData.currentCadence ?? 0
        
        HeatmapperWorkout.intervalArray.append(newInterval)
        MyFunc.logMessage(.debug, "HeatmapperWorkout: \(String(describing: HeatmapperWorkout.self))")
//        HeatmapperWorkout.lastIntervalEndDate = self.intervalEndDate!

        guard let distanceType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.distanceWalkingRunning),
              let activeEnergyType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.activeEnergyBurned),
              let heartRateType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate),
              let basalEnergyType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.basalEnergyBurned)
        else { fatalError("Data not available in HealthKit") }
        
        // create Distance Sample
        let distanceDouble: Double = pedometerData.distance?.doubleValue ?? 0.0
        let distanceQuantity = HKQuantity(unit: HKUnit.meter(), doubleValue: distanceDouble)
        let distanceSample = HKQuantitySample(type: distanceType, quantity: distanceQuantity, start: startDate, end: endDate, device: .local(), metadata: ["Activity Type": "N/A"])

        HeatmapperWorkout.sampleArray.append(distanceSample)
        
        // create Active Energy Sample
        let activeEnergySample = self.workoutManager.getSampleForType(startDate: startDate, endDate: endDate, quantityType: activeEnergyType, option: .cumulativeSum)
        HeatmapperWorkout.sampleArray.append(activeEnergySample)
        
        // create Basal Energy Sample
        let basalEnergySample = self.workoutManager.getSampleForType(startDate: startDate, endDate: endDate, quantityType: basalEnergyType, option: .cumulativeSum)
        HeatmapperWorkout.sampleArray.append(basalEnergySample)
        
        // create Heart Rate Sample
        let heartRateSample = self.workoutManager.getHeartRateSample(startDate: startDate, endDate: endDate, quantityType: heartRateType, option: .discreteAverage)
        HeatmapperWorkout.sampleArray.append(heartRateSample)
        
      } // if error == nil
      
    } // pedometer.queryPedometerData

  } // func addInterval
  
  
  // this function updates the timer labels for the current interval and overall workout
  @objc func updateWorkoutDurationLabel(_ timer: Timer) {
    
    if workoutTimer.isRunning {
      
      // update main timer
      //      let timerFont = UIFont.monospacedDigitSystemFont(ofSize: 36, weight: .regular)
      //      let timerText = NSAttributedString(string: fartlekTimer.elapsedTimeAsString, attributes: [NSAttributedString.Key.font: timerFont])
      //      currentStopwatch.setAttributedText(timerText)
      
      // update overall workout timer
      var workoutTotalTimeInterval: Double = 0
      workoutTotalTimeInterval = workoutDurationTimeInterval
      workoutTotalTimeInterval += workoutTimer.elapsedTime
      let durationFont = UIFont.monospacedSystemFont(ofSize: 16, weight: .light)
      let durationText = NSAttributedString(string: workoutTotalTimeInterval.toReadableString(), attributes: [NSAttributedString.Key.font: durationFont])
      workoutDurationLabel.setAttributedText(durationText)
      
    } else {
      timer.invalidate()
    }
  }

  
  // MARK: - Update the interface
  
  // Retrieve the WKInterfaceLabel object for the quantity types we are observing.
  func labelForQuantityType(_ type: HKQuantityType) -> WKInterfaceLabel? {
    
    switch type {
    case HKQuantityType.quantityType(forIdentifier: .heartRate):
      return heartRateLabel
      
    case HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned):
      return activeCaloriesLabel
      
    case HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning):
      return currentDistance
      
    default:
      return nil
    }
  }
  
  // Update the WKInterfaceLabels with new data.
  func updateLabel(_ label: WKInterfaceLabel?, withStatistics statistics: HKStatistics?) {
    // check to ensure there are statistics to update the UI with
    guard let label = label, let statistics = statistics else {
      // if no statistics exit the function
      return
    }
    
    // Dispatch to main, because we are updating the interface.
    DispatchQueue.main.async { [self] in
      switch statistics.quantityType {
      case HKQuantityType.quantityType(forIdentifier: .heartRate):
        
        let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
        let value = statistics.mostRecentQuantity()?.doubleValue(for: heartRateUnit)
        let roundedValue = Double( round( 1 * value! ) / 1 )
        let roundedValueAsInt = Int(roundedValue)
        label.setText("\(roundedValueAsInt)")
        
      case HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned):
        let energyUnit = HKUnit.kilocalorie()
        let value = statistics.sumQuantity()?.doubleValue(for: energyUnit)
        let roundedValueAsInt = Int(value ?? 0)
        label.setText("\(roundedValueAsInt)")
        return
        
      case HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning):
        
        // always retrieve distance in meters - we then apply conversion using a standard routine
        let distance = statistics.sumQuantity()!.doubleValue(for: HKUnit.meter())
        let distanceString = MyFunc.getUnitLengthAsString(value: distance, unitLength: unitLength, formatter: measurementFormatter)
        
        label.setText(distanceString)
        distanceLabel.setText(unitLength.symbol)
        
        // for distance, update pace also based upon distance / time
        let elapsedTime = self.workoutTimer.elapsedTime
        let pace = distance / elapsedTime
        let paceString = MyFunc.getUnitSpeedAsString(value: pace, unitSpeed: unitSpeed, formatter: measurementFormatter)
        
        self.currentPace.setText(paceString)
        paceLabel.setText(unitSpeed.symbol)
        return

      default:
        // catch for other statistic types
        return
      }
    }
  }
//  
//  func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
//
//    MyFunc.logMessage(.debug, "WorkoutInterfaceController.workoutBuilderDidCollectEvent called")
//    // retrieve the workout event.
//    guard let workoutEventType = workoutBuilder.workoutEvents.last?.type else { return }
//    
//    // Update the timer based on the event received.
//    switch workoutEventType {
//    case .pause: // The user paused the workout.
//      MyFunc.logMessage(.default, "Workout Paused")
//      
//    case .resume: // The user resumed the workout.
//      MyFunc.logMessage(.default, "Workout Resumed")
//      
//    default:
//      return
//    }
//  }
  
  func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
    MyFunc.logMessage(.default, "workoutSession.didChangeTo state: \(toState) from \(fromState)")
  }
  
  func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
    MyFunc.logMessage(.default, "workoutSession.didFailWithError called")
  }
  
  // MARK: - WatchConnectivity code
  
  // .activationDidComplete notification handler.
  @objc func activationDidComplete(_ notification: Notification) {
    MyFunc.logMessage(.info, "\(#function): activationState:\(WCSession.default.activationState.rawValue)")
  }
  
  // .reachabilityDidChange notification handler.
  @objc func reachabilityDidChange(_ notification: Notification) {
  }
  
  // .activationDidComplete notification handler.
  @objc func dataDidFlow(_ notification: Notification) {
    MyFunc.logMessage(.info, "\(#function): activationState:\(WCSession.default.activationState.rawValue)")
  }
  
  // Log the outstanding transfer information if any.
  private func logOutstandingTransfers(for commandStatus: CommandStatus, outstandingCount: Int) {
    if commandStatus.phrase == .transferring {
      var text = commandStatus.phrase.rawValue + " at\n"
      text += "\nOutstanding: \(outstandingCount)\n Tap to view"
      
    }
    
  }
  
  // MARK: - Export Log code - required only as standard logging from watch to phone unreliable
  
  func exportLog() {
    // generate filename including timestamp
    let currDate = fileDateFormatter.string(from: Date())
    let fileName = "Heatmapper_Log_" + currDate + ".txt"
    
    guard let path = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent(fileName) as NSURL else {
      return }
    
    do {
      try MyFunc.log.write(to: path as URL, atomically: true, encoding: String.Encoding.utf8)
      // print only when debugging
      print("Log data written to \(path)")
    } catch {
      // print only when debugging
      print("Failed to create Log file \(String(describing: error))")
    } // catch
    MyFunc.logMessage(.info, "fileURL: \(self.file)")
    transferFile(path as URL, metadata: fileMetaData)
  }
  
}
