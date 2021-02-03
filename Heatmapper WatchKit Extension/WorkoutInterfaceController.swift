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

class WorkoutInterfaceController: WKInterfaceController, DataProvider, SessionCommands, CLLocationManagerDelegate, WorkoutManagerDelegate {

  let audio         = Audio()
  
  // WatchConnectivity variables
  private var command: Command!
  private let fileTransferObservers = FileTransferObservers()
  
  // Units default - these will be retrieved during initialisation
  var units: String = ""
  var unitLength: UnitLength = .meters
  var unitSpeed: UnitSpeed  = .metersPerSecond
  var measurementFormatter  = MeasurementFormatter()

  var vibrateWatch : String = ""

  // HealthKit variables
  let workoutManager = WorkoutManager()
  var routeBuilder: HKWorkoutRouteBuilder!
  
  // Interval variables
  private var fartlekStartDate: Date?
  private var fartlekEndDate: Date?
  private var currentFartlekDistance: Double = 0.0
  private var currentFartlekTime: TimeInterval = 0.0
  
  private var manualStartDate: Date?
  private var manualEndDate: Date?
  private var currentManualDistance: Double = 0.0
  private var currentManualTime: TimeInterval = 0.0
  
  private var nextPedometerQueryStartDate: Date?
  
  // timer variables
  let fartlekTimer                = Stopwatch()
  var isRunning                   = true
  
  var intervalTimer               = Timer()
  var manualIntervalTimeLeft: TimeInterval = 0.0
  var manualIntervalEndTime: Date?
  var intervalTemplateArray: [IntervalTemplate] = []
  var intervalCount: Int = 0
  var getNextInterval: Bool = false
  
  var workoutStartDate: Date?
  var workoutEndDate: Date?
  var workoutDurationDateInterval: DateInterval?
  var workoutEventArray: [HKWorkoutEvent] = []
  
  var workoutPausedDate: Date?
  var workoutTotalTime: Double = 0
  
  var activityType                 = ActivityType()
  
  // Core Location variables
  let locationManager             = CLLocationManager()
  
  // Core Motion variables
  var currentMotionType: String = ""
  var previousMotionType: String = ""
  var previousMotionTypeForUpdate: String = ""
  var currentManualMotionType: String = ""
  var previousManualMotionType: String = ""
  var confidenceThreshold: Int = 1
  var currentConfidence: Int = 0
  var previousConfidence: Int = 0
  let pedometer                   = CMPedometer()
  let motionActivityManager       = CMMotionActivityManager()

  var previousStationary: Bool = false
  var previousWalking: Bool = false
  var previousRunning: Bool = false
  
  // log variables
  var log: String = ""
  let fileDateFormatter           = DateFormatter()
  let numberFormatter             = NumberFormatter()
  
  @IBOutlet weak var runLabel: WKInterfaceButton!
  @IBOutlet weak var walkLabel: WKInterfaceButton!
  @IBOutlet weak var stationaryLabel: WKInterfaceButton!
  
  @IBOutlet weak var distanceLabel: WKInterfaceLabel!
  @IBOutlet weak var paceLabel: WKInterfaceLabel!
  @IBOutlet weak var currentPace: WKInterfaceLabel!
  @IBOutlet weak var currentDistance: WKInterfaceLabel!
  
  @IBOutlet weak var workoutDurationLabel: WKInterfaceLabel!
  @IBOutlet weak var currentStopwatch: WKInterfaceLabel!
  @IBOutlet weak var heartRateLabel: WKInterfaceLabel!
  @IBOutlet weak var activeCaloriesLabel: WKInterfaceLabel!
  @IBOutlet weak var activityTypeLabel: WKInterfaceLabel!
  @IBOutlet weak var centreGroup: WKInterfaceGroup!
  @IBOutlet weak var setLabelGroup: WKInterfaceGroup!

  @IBOutlet weak var currentSetLabel: WKInterfaceLabel!
  @IBOutlet weak var totalSetsLabel: WKInterfaceLabel!


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
    fartlekTimer.stop()
    
  }
  
  override func awake(withContext context: Any?) {
    super.awake(withContext: context)
    
    guard let contextReceived = context as? ActivityType else {
      MyFunc.logMessage(.error, "Invalid context received by WorkoutInterfaceController : \(String(describing: context))")
      return
    }
    activityType = contextReceived
    
    if activityType == .auto {
      activityTypeLabel.setHidden(true)
      setLabelGroup.setHidden(true)
      workoutDurationLabel.setHidden(false)
    } else {
      activityTypeLabel.setHidden(false)
      setLabelGroup.setHidden(false)
      workoutDurationLabel.setHidden(true)
    }
    let timerFont = UIFont.monospacedDigitSystemFont(ofSize: 36, weight: .regular)
    let timerText = NSAttributedString(string: "00:00", attributes: [NSAttributedString.Key.font: timerFont])
    currentStopwatch.setAttributedText(timerText)
    let durationFont = UIFont.monospacedSystemFont(ofSize: 16, weight: .regular)
    let durationText = NSAttributedString(string: "0.0", attributes: [NSAttributedString.Key.font: durationFont])
    workoutDurationLabel.setAttributedText(durationText)
    
    addNotificationObservers()
    
    // start workout for all ActivityTypes
    startWorkout()
    
    // set VC as CLLocationManager delegate
    locationManager.delegate = self
    locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
    workoutManager.delegate = self
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
    
    workoutManager.startWorkout()
    
    // check if pedometer data is available, if so start updates
    if CMPedometer.isPedometerEventTrackingAvailable() {
      pedometer.startEventUpdates(handler: { [weak self] (_, error) in
        // line purely to silence warning below
        let selfSilencer = self
        MyFunc.logMessage(.info, String(describing: selfSilencer))

        if error != nil {
          MyFunc.logMessage(.error, "Error in FartlekInterfaceController startEventUpdates: \(String(describing: error))")
          
        }
        
      })
    }
    
    // set all variables ready for new Workout
    FartlekWorkout.intervalArray.removeAll()
    FartlekWorkout.startDate = Date()
    FartlekWorkout.lastIntervalEndDate = Date()
    
    fartlekEndDate  = nil
    previousMotionType = ""
    previousMotionTypeForUpdate = ""
    currentMotionType = ""
    
    workoutTotalTime = 0
    getNextInterval = true
    
    MyFunc.logMessage(.debug, "startWorkout : fartlekTimer.start()")
    // fartlekTimer is for auto tracking only
    fartlekTimer.start()
    fartlekStartDate = Date()
    workoutStartDate = fartlekStartDate
    // intervalTimer controls the displayed Time
    
    // start the workout for the respective activityType
    switch activityType {
    case .auto:
      intervalTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(WorkoutInterfaceController.updateFartlekTimeLabel(_:)), userInfo: nil, repeats: true)
      runAutoWorkout()
      
    case .repeat, .tabata:
      // get the Repeat defaults
      let activityTemplate = MyFunc.getActivityDefaults(activityType)
      
      // decompose ActivityTemplate into flattened array
      intervalTemplateArray.removeAll()
      intervalTemplateArray = MyFunc.createRepeatIntervalSet(activityTemplate)

      workoutStartDate = Date()
      let totalSetsStr = String(intervalTemplateArray.count)
      totalSetsLabel.setText(totalSetsStr)
      runManualWorkout()

    case .pyramid:
      // get the Repeat defaults
      let activityTemplate = MyFunc.getActivityDefaults(activityType)
      
      // decompose ActivityTemplate into flattened array
      intervalTemplateArray.removeAll()
      intervalTemplateArray = MyFunc.createCustomIntervalSet(activityTemplate)
      
      workoutStartDate = Date()
      let totalSetsStr = String(intervalTemplateArray.count)
      totalSetsLabel.setText(totalSetsStr)
      runManualWorkout()

    case .custom:
      // get the Repeat defaults
      let activityTemplate = MyFunc.getActivityDefaults(activityType)
      
      // decompose ActivityTemplate into flattened array
      intervalTemplateArray.removeAll()
      intervalTemplateArray = activityTemplate.intervals
      
      // set start time for workout and go
      workoutStartDate = Date()
      let totalSetsStr = String(intervalTemplateArray.count)
      totalSetsLabel.setText(totalSetsStr)
      runManualWorkout()
      
    case .random:
      // get the Repeat defaults
      let activityTemplate = MyFunc.getActivityDefaults(activityType)
      
      // decompose ActivityTemplate into flattened array
      intervalTemplateArray.removeAll()
      intervalTemplateArray = MyFunc.createRandomIntervalSet(activityTemplate)
      
      workoutStartDate = Date()
      let totalSetsStr = String(intervalTemplateArray.count)
      totalSetsLabel.setText(totalSetsStr)
      runManualWorkout()
      
    default:
      MyFunc.logMessage(.error, "Unknown activityType \(activityType) received")
    }
    
  } // func startWorkout
  
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
  
  // main function for tracking running / walking / stationary activity
  func runManualWorkout() {


    // next process each interval in turn
    if getNextInterval == true {
      getNextInterval = false

      let intervalNumber = intervalCount + 1
      let intervalNumberStr = String(intervalNumber)
      currentSetLabel.setText(intervalNumberStr)
      // set UI for current activity Type
      activityTypeLabel.setText(intervalTemplateArray[intervalCount].intervalType.rawValue)
      updateUIForIntervalType(intervalTemplateArray[intervalCount].intervalType)
      
      let newIntervalPhrase = "\(intervalTemplateArray[intervalCount].intervalType) now"
      let newIntervalPhraseLocalized = NSLocalizedString("\(newIntervalPhrase)", comment: "")
      audio.speak(phrase: newIntervalPhraseLocalized)

      if vibrateWatch == "On" {
        let device = WKInterfaceDevice()
        device.play(.retry)
      }
      intervalTimer = Timer()
      manualIntervalTimeLeft = intervalTemplateArray[intervalCount].duration
      manualIntervalEndTime = Date().addingTimeInterval(manualIntervalTimeLeft)
      intervalTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(updateIntervalTime), userInfo: nil, repeats: true)
      
    }
    
  } // func runManualWorkout
  
  func updateUIForIntervalType(_ intervalType: IntervalType ) {
    
    var activityBackground = UIColor.clear
    switch intervalType {
    case .warmup, .cooldown:
      activityBackground = .clear
    case .work:
      activityBackground = .red
    case .rest:
      activityBackground = .orange
    default:
      activityBackground = .clear
    }
    
    centreGroup.setBackgroundColor(activityBackground)
  }
  
  @objc func updateIntervalTime() {
    if manualIntervalTimeLeft > 0 {
      
      manualIntervalTimeLeft = manualIntervalEndTime?.timeIntervalSinceNow ?? 0
      
      currentStopwatch.setText(manualIntervalTimeLeft.time)
      
      let timeby10 = manualIntervalTimeLeft * 10
      let roundedTimeby10 = round(timeby10)
      let roundedTimeby10asInt = Int(roundedTimeby10)
      
      let roundedTimeLeft = round(manualIntervalTimeLeft)
      let roundedTimeAsInt = Int(roundedTimeLeft)
      // round by 10 as time is tracked in deciseconds and want to process logic at full seconds
      let roundedTimeAsIntby10 = roundedTimeAsInt * 10
      
      if roundedTimeAsIntby10 == roundedTimeby10asInt {
        
        // 3 second warning that next interval is about to start
        if roundedTimeby10asInt == 30 {
          if intervalCount + 1 < intervalTemplateArray.count {
            // get next Interval
            let nextInterval = intervalTemplateArray[intervalCount+1].intervalType
            let activityPhrase = "Get ready to \(nextInterval)"
            let activityPhraseLocalized = NSLocalizedString("\(activityPhrase)", comment: "")
            audio.speak(phrase: activityPhraseLocalized)
          } else {
            let workoutCompletePhraseLocalized = NSLocalizedString("Workout complete. Well done", comment: "Workout complete. Well done")
            audio.speak(phrase: workoutCompletePhraseLocalized)
          }
          // check next Interval activity
          
        }
        
      }
      
    } else {
      
      // interval time has reached zero - reset stopwatch and increment interval count
      currentStopwatch.setText("00:00")
      intervalTimer.invalidate()
      
      intervalCount += 1
      fartlekEndDate = Date()
      // add interval to FartlekWorkout array
      addInterval(startDate: self.fartlekStartDate!, endDate: self.fartlekEndDate!, motionType: self.previousMotionType, finalInterval: false)
      fartlekStartDate = fartlekEndDate

      if intervalCount == intervalTemplateArray.count {
        // if last interval reached, end the workout
        endWorkout()
      } else {
        getNextInterval = true

        runManualWorkout()
      }
    }
    
  }
  
  // main function for tracking running / walking / stationary activity
  func runAutoWorkout() {
    
    if CMMotionActivityManager.isActivityAvailable() {
      
      motionActivityManager.startActivityUpdates(to: .main, withHandler: { [self](motion) in
        
        let motionStr = String(describing: motion)
        MyFunc.logMessage(.debug, "motion: \(motionStr)")
        
        // Log CMMotionActivityManager changes
        let motionChangedDate = motion?.startDate ?? nil
        
        if (motion?.stationary) == true {
          if self.previousStationary == false {
            MyFunc.logMessage(.debug, "Stationary changed to True on \(String(describing: motionChangedDate))")
          }
          self.previousStationary = true
          
        } else {
          if self.previousStationary == true {
            MyFunc.logMessage(.debug, "Stationary changed to False on \(String(describing: motionChangedDate))")
          }
          self.previousStationary = false
          
        }
        
        if (motion?.walking) == true {
          if self.previousWalking == false {
            MyFunc.logMessage(.debug, "Walking changed to True on \(String(describing: motionChangedDate))")
          }
          self.previousWalking = true
          
        } else {
          if self.previousWalking == true {
            MyFunc.logMessage(.debug, "Walking changed to False on \(String(describing: motionChangedDate))")
          }
          self.previousWalking = false
          
        }
        
        if (motion?.running) == true {
          
          if self.previousRunning == false {
            MyFunc.logMessage(.debug, "Running changed to True on \(String(describing: motionChangedDate))")
          }
          self.previousRunning = true
          
        } else {
          if self.previousRunning == true {
            MyFunc.logMessage(.debug, "Running changed to False on \(String(describing: motionChangedDate))")
          }
          self.previousRunning = false
          
        }
        
        // Running overrides Walking which in turn overrides Stationary
        // logic to handle transition between walking and running
        if motion?.running == true {
          self.currentMotionType = "Running"
        } else {
          if motion?.walking == true {
            self.currentMotionType = "Walking"
          } else {
            self.currentMotionType = "Stationary"
          }
        }
        
        // if the Motion Type has changed, record a new interval
        if self.currentMotionType != self.previousMotionType {
          
          if (motion?.confidence.rawValue)! >= self.confidenceThreshold {
            
            if self.previousMotionType == "" {
              
              // If there is no previousMotionType, capture the current motion as the first type of Interval.
              // When the next motionType change is detected, or the workout is ended manually, the Interval will be recorded.
              // Until a motionType change is detected, the Workout will not start
              if motionChangedDate! > workoutStartDate! {
                
                self.fartlekStartDate = motionChangedDate
                // set this as the start of the Workout also
                workoutStartDate = motionChangedDate
                
                MyFunc.logMessage(.debug, "motionChangedDate after Workout Start Date")
                MyFunc.logMessage(.debug, "motionChangedDate: \(String(describing: motionChangedDate))")
                MyFunc.logMessage(.debug, "workoutStartDate: \(String(describing: workoutStartDate))")
                
                self.fartlekTimer.start()
                intervalTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(updateFartlekTimeLabel(_:)), userInfo: nil, repeats: true)
                MyFunc.logMessage(.debug, "runAutoWorkout : previousMotionType == ''")
                
              } else {
                
                MyFunc.logMessage(.debug, "motionChangedDate before WorkoutStartDate")
                MyFunc.logMessage(.debug, "motionChangedDate: \(String(describing: motionChangedDate))")
                MyFunc.logMessage(.debug, "workoutStartDate: \(String(describing: workoutStartDate))")
              }
              
            } else {
              // Previous Motion Type exists so record interval just completed
              // write this to additional variable to avoid update of previousMotionType in any asynchronous thread
              
              let phrase = "Recording " + self.previousMotionType + " interval"
              let phraseLocalized = NSLocalizedString("\(phrase)", comment: "Recording interval")
              self.audio.speak(phrase: phraseLocalized)
              
              // KIV - variable is at class level in phone app
              // check to see if this affects data returned
              self.fartlekEndDate = motionChangedDate
              
              addInterval(startDate: self.fartlekStartDate!, endDate: self.fartlekEndDate!, motionType: self.previousMotionType, finalInterval: false)
              //reset timer
              fartlekTimer.stop()
              fartlekTimer.start()
              
            } // else (self.previousMotionType != ""...)
            
            self.previousMotionType = self.currentMotionType
            
          } // if (motion?.confidence.rawValue)! >= self.confidenceThreshold
          
        } // if self.currentMotionType != self.previousMotionType {
        
      }) // motionActivityManager...
      
    } // if CMMotionActivityManager...
    
  } // func runAutoWorkout
  
  @objc func speakStartingWorkout(_ timer: Timer) {
    if fartlekTimer.isRunning == true {
      let startPhraseLocalized = NSLocalizedString("Starting workout now", comment: "")
      audio.speak(phrase: startPhraseLocalized)
    }
  }
  
  @objc func endWorkout() {
    
    // set as current page
    DispatchQueue.main.async {
      self.becomeCurrentPage()
    }
    
    fartlekTimer.stop()
    intervalTimer.invalidate()
    
    
    // if moving from paused to stopped state, mark the workout as having finished from the last pause
    if workoutManager.session.state == .paused {
      //    if session.state == .paused {
      workoutEndDate = workoutPausedDate
    } else {
      workoutEndDate = Date()
    }
    
    // record the final interval and stop location and motion updates
    addInterval(startDate: fartlekStartDate!, endDate: workoutEndDate!, motionType: self.previousMotionType, finalInterval: true)
    locationManager.stopUpdatingLocation()
    motionActivityManager.stopActivityUpdates()
    pedometer.stopUpdates()
    locationManager.stopUpdatingHeading()
    
    // removal of pauses should be an ongoing check
    workoutDurationDateInterval = DateInterval(start: workoutStartDate!, end: workoutEndDate!)
    
    // create Workout Events for each Interval
    for fartlek in 0..<FartlekWorkout.intervalArray.count {
      let fartlekInterval = FartlekWorkout.intervalArray[fartlek]
      // note : Event metadata does not appear to be visible through Health app; adding for completeness
      let fartlekEvent = HKWorkoutEvent(type: HKWorkoutEventType.segment, dateInterval: fartlekInterval.duration!, metadata: ["Type": fartlekInterval.activity])
      workoutEventArray.append(fartlekEvent)
    }
    
    workoutManager.addWorkoutEvents(eventArray: workoutEventArray)
    
    self.exportLog()
    
    DispatchQueue.main.async {
      self.displayAlert(title: "Workout saved", message: "")
      WKInterfaceController.reloadRootPageControllers(withNames: ["IntervalsTableController"], contexts: ["workoutEnded"], orientation: WKPageOrientation.horizontal, pageIndex: 0)
      
    }
    
    
  } // func endWorkout
  
  @objc func pauseWorkout() {
    
    // set as current page
    DispatchQueue.main.async {
      self.becomeCurrentPage()
    }
    
    workoutManager.pauseWorkout()
    //    session.pause()
    audio.stopSpeaking()
    let pausePhrase = NSLocalizedString("Workout paused", comment: "")
    audio.speak(phrase: pausePhrase)
    intervalTimer.invalidate()
    
    if activityType == .auto {
      if fartlekTimer.isRunning {
        fartlekTimer.stop()
        
        workoutPausedDate = Date()
//        let workoutPausedDateInterval = DateInterval(start: workoutPausedDate!, end: workoutPausedDate!)
//        let workoutPausedEvent = HKWorkoutEvent(type: .pause, dateInterval: workoutPausedDateInterval, metadata: ["Type": "Pause"])
//        workoutEventArray.append(workoutPausedEvent)
        
      }
    }
    
  }
  
  @objc func resumeWorkout() {
    
    // set as current page
    DispatchQueue.main.async {
      self.becomeCurrentPage()
    }
    audio.stopSpeaking()
    let resumePhraseLocalized = NSLocalizedString("Resuming workout", comment: "Resuming workout")
    audio.speak(phrase: resumePhraseLocalized)
    
    workoutManager.resumeWorkout()
    //    session.resume()
    
    if activityType == .auto {
      let workoutResumedDate = Date()
//      let workoutResumedDateInterval = DateInterval(start: workoutResumedDate, end: workoutResumedDate)
//      let workoutResumedEvent = HKWorkoutEvent(type: .resume, dateInterval: workoutResumedDateInterval, metadata: ["Type": "Resume"])
//      workoutEventArray.append(workoutResumedEvent)
//
      runAutoWorkout()
      
      self.fartlekStartDate = workoutResumedDate
      fartlekTimer.startFromDate(date: self.fartlekStartDate!)
      intervalTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(updateFartlekTimeLabel(_:)), userInfo: nil, repeats: true)
    } else {
      intervalTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(updateIntervalTime), userInfo: nil, repeats: true)
      runManualWorkout()
    }
    
  } // @objc func resumeWorkout
  
  @objc func lockScreen() {
    
    WKInterfaceDevice.current().enableWaterLock()
    // set as current page
    DispatchQueue.main.async {
      self.becomeCurrentPage()
    }
    
  }
  
  // Core Location code to get the current location
  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    
    let currentLocation = locations[locations.count - 1]
    MyFunc.logMessage(.info, "Current Location Found: \(currentLocation)")
    
    // Filter the raw data.
    let filteredLocations = locations.filter { (location: CLLocation) -> Bool in
      location.horizontalAccuracy <= 50.0
    }
    
    guard !filteredLocations.isEmpty else { return }
    
    // Add the filtered data to the route.
    routeBuilder.insertRouteData(filteredLocations) { (success, error) in
      if !success {
        MyFunc.logMessage(.error, "Error inserting Route data: \(String(describing: error))")
      }
    }
  }
  
  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    MyFunc.logMessage(.error, "Error attempting to get Location: \(error)")
  }
  
  func displayAlert (title: String, message: String) {
    var nextController = "MainMenuInterfaceController"
    if activityType == .auto {
      nextController = "IntervalsTableController"
    }
    
    //Alert user that Save has worked
    let okAction = WKAlertAction(title: "OK", style: WKAlertActionStyle.default, handler: {
      
      MyFunc.logMessage(.default, "okAction handler called")
      DispatchQueue.main.async {
        self.pushController(withName: nextController, context: nil)
      }
      
    })
    MyFunc.logMessage(.default, "displayAlert called")
    WKExtension.shared().visibleInterfaceController?.presentAlert(withTitle: title, message: message, preferredStyle: WKAlertControllerStyle.alert, actions: [okAction])
    
    DispatchQueue.main.async {
      self.pushController(withName: nextController, context: nil)
    }
  }
  
  func addInterval(startDate: Date, endDate: Date, motionType: String, finalInterval: Bool) {
    
    var newFartlekInterval  = Interval()
    let intervalStartDate   = startDate
    let intervalEndDate     = endDate
    let intervalMotionType  = motionType
    
    if intervalStartDate < intervalEndDate {
      newFartlekInterval.duration    = DateInterval(start: intervalStartDate, end: intervalEndDate)
    } else {
      MyFunc.logMessage(.error, "Error setting newFartlekInterval.duration: sd: \(String(describing: intervalStartDate)), ed: \(String(describing: intervalEndDate))")
    }
    
    newFartlekInterval.activity    = intervalMotionType
    newFartlekInterval.startDate   = intervalStartDate
    newFartlekInterval.endDate     = intervalEndDate
    
    pedometer.queryPedometerData(from: intervalStartDate, to: intervalEndDate) {
      
      (pedometerData: CMPedometerData!, error) -> Void in
      
      if error == nil {
        
        newFartlekInterval.distance    = pedometerData.distance ?? 0
        newFartlekInterval.pace        = pedometerData.averageActivePace ?? 0
        newFartlekInterval.steps       = pedometerData.numberOfSteps
        newFartlekInterval.cadence     = pedometerData.currentCadence ?? 0
        
        FartlekWorkout.intervalArray.append(newFartlekInterval)
        FartlekWorkout.lastIntervalEndDate = intervalEndDate
        self.fartlekStartDate = intervalEndDate
        
        // code below creates Samples : commented out while identifying interval tracking issues
        guard let distanceType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.distanceWalkingRunning),
              let activeEnergyType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.activeEnergyBurned),
              let heartRateType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate),
              let basalEnergyType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.basalEnergyBurned)
        else { fatalError("Data not available in HealthKit") }
        
        // create Distance Sample
        let distanceDouble: Double = pedometerData.distance?.doubleValue ?? 0.0
        let distanceQuantity = HKQuantity(unit: HKUnit.meter(), doubleValue: distanceDouble)
        let distanceSample = HKQuantitySample(type: distanceType, quantity: distanceQuantity, start: intervalStartDate, end: intervalEndDate, device: .local(), metadata: ["Activity Type": self.previousMotionTypeForUpdate])
        FartlekWorkout.sampleArray.append(distanceSample)
        
        // create Active Energy Sample
        let activeEnergySample = self.workoutManager.getSampleForType(startDate: intervalStartDate, endDate: intervalEndDate, quantityType: activeEnergyType, option: .cumulativeSum)
        FartlekWorkout.sampleArray.append(activeEnergySample)
        
        // create Basal Energy Sample
        let basalEnergySample = self.workoutManager.getSampleForType(startDate: intervalStartDate, endDate: intervalEndDate, quantityType: basalEnergyType, option: .cumulativeSum)
        FartlekWorkout.sampleArray.append(basalEnergySample)
        
        // create Heart Rate Sample
        let heartRateSample = self.workoutManager.getHeartRateSample(startDate: intervalStartDate, endDate: intervalEndDate, quantityType: heartRateType, option: .discreteAverage)
        FartlekWorkout.sampleArray.append(heartRateSample)
        
      }
      
    } // self.pedometer.queryPedometerData
    
    //    // Previous Motion Type exists so record interval just completed
    self.previousMotionTypeForUpdate = self.previousMotionType
    
  } // func addInterval
  
  
  // this function updates the timer labels for the current interval and overall workout
  @objc func updateFartlekTimeLabel(_ timer: Timer) {
    
    if fartlekTimer.isRunning {
      
      // update main timer
      let timerFont = UIFont.monospacedDigitSystemFont(ofSize: 36, weight: .regular)
      let timerText = NSAttributedString(string: fartlekTimer.elapsedTimeAsString, attributes: [NSAttributedString.Key.font: timerFont])
      currentStopwatch.setAttributedText(timerText)
      
      // update overall duration timer
      var workoutTotalTimeInterval: Double = 0
      workoutTotalTimeInterval = FartlekWorkout.totalDuration
      workoutTotalTimeInterval += fartlekTimer.elapsedTime
      let durationFont = UIFont.monospacedSystemFont(ofSize: 16, weight: .light)
      let durationText = NSAttributedString(string: workoutTotalTimeInterval.toReadableString(), attributes: [NSAttributedString.Key.font: durationFont])
      workoutDurationLabel.setAttributedText(durationText)
      
    } else {
      timer.invalidate()
    }
  }
  
//  // MARK: - HKLiveWorkoutBuilderDelegate
//  func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
//
//    // update UI with latest stats
//    for type in collectedTypes {
//      guard let quantityType = type as? HKQuantityType else {
//        return
//      }
//
//      let statistics = workoutBuilder.statistics(for: quantityType)
//      let label = labelForQuantityType(quantityType)
//      updateLabel(label, withStatistics: statistics)
//    }
//
//  } // didCollectDataOf
  
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
    // Make sure we got non `nil` parameters.
    guard let label = label, let statistics = statistics else {
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
        let elapsedTime = self.fartlekTimer.elapsedTime
        let pace = distance / elapsedTime
        let paceString = MyFunc.getUnitSpeedAsString(value: pace, unitSpeed: unitSpeed, formatter: measurementFormatter)
        
        self.currentPace.setText(paceString)
        self.currentFartlekDistance = distance
        paceLabel.setText(unitSpeed.symbol)
        
        return
      default:
        return
      }
    }
  }
  
  func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
    // retrieve the workout event.
    guard let workoutEventType = workoutBuilder.workoutEvents.last?.type else { return }
    
    // Update the timer based on the event received.
    switch workoutEventType {
    case .pause: // The user paused the workout.
      MyFunc.logMessage(.default, "Workout Paused")
      
    case .resume: // The user resumed the workout.
      MyFunc.logMessage(.default, "Workout Resumed")
      
    default:
      return
    }
  }
  
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
