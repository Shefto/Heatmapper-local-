//
//  WorkoutViewController.swift
//  Heatmapper
//
//  Created by Richard English on 27/06/2020.
//  Copyright © 2020 Richard English. All rights reserved.
//

import AVFoundation
import CoreLocation
import CoreMotion
import HealthKit
import UIKit
import os
import WatchConnectivity
import GoogleMobileAds
import AudioToolbox

class WorkoutViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, DataProvider, SessionCommands, CLLocationManagerDelegate {

  let logger = Logger(subsystem: "com.wimbledonappcompany.Heatmapper", category: "WorkoutViewController")
  let defaults = UserDefaults.standard

  // GoogleMobileAds
  var interstitial: GADInterstitial!
  weak var rootVC: UIViewController?
  // AV variables
  let audio                       = Audio()

  // Core Motion variables
  let pedometer                   = CMPedometer()
  let motionActivityManager       = CMMotionActivityManager()
  let motionManager               = CMMotionManager()

  private var startDate: Date?
  let dateFormatterForHHMMSS      = DateFormatter()
  let numberFormatter             = NumberFormatter()

  // HealthKit variables
  private let healthStore         = HKHealthStore()
  let workoutConfiguration        = HKWorkoutConfiguration()
  var builder: HKWorkoutBuilder!
  var routeBuilder: HKWorkoutRouteBuilder!
  var workoutEventArray: [HKWorkoutEvent] = []

  var distanceSampleArray: [HKSample] = []
  var activeEnergySampleArray: [HKSample] = []
  var basalEnergySampleArray: [HKSample] = []
  var sampleArray: [HKSample] = []

  // Core Location variables
  let locationManager             = CLLocationManager()
  var locationArray               : [CLLocationCoordinate2D] = []

  // Core Motion variables
  var currentMotionType: String = ""
  var previousMotionType: String = ""
  var previousMotionTypeForUpdate: String = ""

  var previousStationary: Bool = false
  var previousWalking: Bool = false
  var previousRunning: Bool = false

  // Activity Type & related variables
  var intervalTimer = Timer()
  var manualIntervalTimeLeft: TimeInterval = 0.0
  var manualIntervalEndTime: Date?
  var manualIntervalPaused: TimeInterval = 0.0
  var activityType      = ActivityType()
  var activityTemplate  = ActivityTemplate()
  var intervalTemplateArray: [IntervalTemplate] = []
  var intervalCount: Int = 0
  var getNextInterval: Bool = false

  var totalSetStr : String = ""
  var fartlekStartStr: String = ""
  var fartlekEndStr: String = ""
  var fartlekStartDate: Date?
  var fartlekEndDate: Date?
  var workoutStartDate: Date?
  var workoutEndDate: Date?
  var workoutDurationDateInterval: DateInterval?
  var backgroundStartDate: Date?
  var backgroundEndDate: Date?
  var workoutDistance: Double = 0.0
  var workoutPace: Double = 0.0
  var workoutPausedDate: Date?
  var workoutPausedTotal: TimeInterval?

  var fartlekArray                = [Interval]()
  var checkArray                  = [Interval]()
  let fartlekTimer                = Stopwatch()

  let fileDateFormatter = DateFormatter()
  let theme = ColourTheme()

  let locale = Locale.current
  let measurementFormatter = MeasurementFormatter()
  var unitLength = MyFunc.getDefaultsUnitLength()
  var unitSpeed = MyFunc.getDefaultsUnitSpeed()

  // Countdown Timer variables
  let timeLeftArc = CAShapeLayer()
  let countdownCircle = CAShapeLayer()
  var countdownTimeLeft: TimeInterval = 3.1
  var countdownEndTime: Date?
  var countdownTimer = Timer()
  let timeLeftFill = CABasicAnimation(keyPath: "strokeEnd")

  enum WorkoutStatusType {
    case started
    case cancelled
    case paused
    case stopped
  }
  var workoutStatus: WorkoutStatusType = .stopped

  var confidenceThreshold: Int = 1
  var log: String = ""

  // watchOS declarations
  let commands: [Command] = [.transferFile]

  // @IBOutlets
  @IBOutlet weak var paceLabel: ThemeColumnHeaderUILabel!
  @IBOutlet weak var distanceLabel: ThemeColumnHeaderUILabel!

  @IBOutlet weak var countdownView: ThemeView!
  @IBOutlet weak var countdownTimerLabel: ThemeLargeNumericUILabel!
  @IBOutlet weak var workoutTotalView: UIView!

  @IBOutlet weak var activityDurationView: UIView!
  @IBOutlet weak var setLabel: ThemeVeryLargeFontUILabel!


  @IBOutlet weak var tableHeaderStackView: UIStackView!
  @IBOutlet weak var fartlekCurrentStackView: UIStackView!
  @IBOutlet weak var fartlekTimerLabel: UILabel!
  @IBOutlet weak var fartlekPaceLabel: UILabel!
  @IBOutlet weak var fartlekDistLabel: UILabel!
  @IBOutlet weak var fartlekTableView: UITableView!

  @IBOutlet weak var fartlekTableViewHeightConstraint: NSLayoutConstraint!

  @IBOutlet weak var buttonStackViewHeight: NSLayoutConstraint!

  @IBOutlet weak var startButton: UIButton!
  @IBOutlet weak var pauseButton: UIButton!
  @IBOutlet weak var stopButton: UIButton!
  @IBOutlet weak var activityTypeLabel: ThemeVeryLargeFontUILabel!
  @IBOutlet weak var durationLeftLabel: ThemeLargeNumericUILabel!

  @IBOutlet weak var fartlekCurrentPaceView: UIView!
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    // set up observers to monitor app moving states from Foreground to Background and vice-versa
    NotificationCenter.default.addObserver(self, selector: #selector(applicationWillEnterForeground(_:)), name: UIApplication.willEnterForegroundNotification, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(applicationWillResignActive(_:)), name: UIApplication.willResignActiveNotification, object: nil)

    createAndLoadInterstitial()

    fartlekTableView.reloadData()
    self.scrollToBottom(animated: false)

  }

  @objc func applicationWillEnterForeground(_ notification: NSNotification) {

    // note when the app left the background
    backgroundEndDate = Date()

    guard let _backgroundStartDate = backgroundStartDate else {
      MyFunc.logMessage(.error, "WorkoutViewController applicationWillEnterForeground : backgroundStartDate null")
      return
    }
    // first query for motion changes between backgroundStartDate and backgroundEndDate
    motionActivityManager.queryActivityStarting(from: _backgroundStartDate, to: backgroundEndDate!, to: .main, withHandler: { (motionActivities, error) in

      if error == nil {

        let motionArray = motionActivities!.sorted {
          $0.startDate < $1.startDate
        }
        let motionArrayStr = String(describing: motionArray)
        MyFunc.logMessage(.info, "Sorted motion Array :")
        MyFunc.logMessage(.info, motionArrayStr)

        for motionActivity in motionArray {
          // create interval using each motion change

          MyFunc.logMessage(.debug, "motionActivity: \(String(describing: motionActivity))")

        }

      } else {
        MyFunc.logMessage(.error, "error using queryActivityStarting to retrieve background motion activities: \(String(describing: error))")
      }

    })

  }

  @objc func applicationWillResignActive(_ notification: NSNotification) {
    backgroundStartDate = Date()
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    activityTemplate = MyFunc.getActivityDefaults(activityType)
    // get the locale for displaying metrics in km or mi
    measurementFormatter.locale = locale
    measurementFormatter.unitOptions = .providedUnit
    measurementFormatter.unitStyle = .medium
    measurementFormatter.numberFormatter.usesSignificantDigits = false
    measurementFormatter.numberFormatter.minimumIntegerDigits = 1
    measurementFormatter.numberFormatter.maximumFractionDigits = 2

    loadUI()

    // set VC as CLLocationManager delegate
    locationManager.delegate = self

    // create HealthKit workout and builder
    workoutConfiguration.activityType = .running
    workoutConfiguration.locationType = .outdoor

    builder = HKWorkoutBuilder(healthStore: healthStore, configuration: workoutConfiguration, device: .local())
    routeBuilder = HKWorkoutRouteBuilder(healthStore: healthStore, device: nil)

  }  // func viewDidLoad

  override func viewWillLayoutSubviews() {
    super.viewWillLayoutSubviews()
    fartlekTableViewHeightConstraint.constant = fartlekTableView.contentSize.height
  }

  fileprivate func createAndLoadInterstitial() {
    interstitial = GADInterstitial(adUnitID: "ca-app-pub-2779736734695934/7555499739")
    let request = GADRequest()
    //    // Request test ads on devices you specify. Your test device ID is printed to the console when
    //    // an ad request is made.
    //    request.testDevices = [kGADSimulatorID as! String, "2077ef9a63d2b398840261c8221a0c9a"]
    interstitial.load(request)
  }

  func loadUI() {


    let unitLengthDefault = defaults.object(forKey: "Units") as? String ?? ""

    switch unitLengthDefault {
    case "km/h":
      let distanceTextLocalized = NSLocalizedString("Distance\n(m)", comment: "")
      let paceTextLocalized = NSLocalizedString("Pace\n(km/h)", comment: "")
      distanceLabel.text = distanceTextLocalized
      paceLabel.text = paceTextLocalized
    case "mph":
      let distanceTextLocalized = NSLocalizedString("Distance\n(yds)", comment: "")
      let paceTextLocalized = NSLocalizedString("Pace\n(mph)", comment: "")
      distanceLabel.text = distanceTextLocalized
      paceLabel.text = paceTextLocalized
    case "mins/km":
      let distanceTextLocalized = NSLocalizedString("Distance\n(m)", comment: "")
      let paceTextLocalized = NSLocalizedString("Pace\n(mins/km)", comment: "")
      distanceLabel.text = distanceTextLocalized
      paceLabel.text = paceTextLocalized
    case "mins/mi":
      let distanceTextLocalized = NSLocalizedString("Distance\n(yds)", comment: "")
      let paceTextLocalized = NSLocalizedString("Pace\n(mins/mi)", comment: "")
      distanceLabel.text = distanceTextLocalized
      paceLabel.text = paceTextLocalized



    default:
      MyFunc.logMessage(.error, "Unknown value for Units default: \(unitLengthDefault)")
    }

    // display table on load, hide Countdown Timer and current Workout fields
    if activityType == .auto {
      fartlekCurrentStackView.isHidden  = false
      tableHeaderStackView.isHidden = false
      fartlekTableView.isHidden = false
    } else {
      fartlekCurrentStackView.isHidden  = true
      tableHeaderStackView.isHidden = true
      fartlekTableView.isHidden = true
    }

    countdownView.isHidden            = true
    durationLeftLabel.isHidden        = true
    activityTypeLabel.isHidden        = false
    setLabel.isHidden       = true
    activityTypeLabel.text            = NSLocalizedString("Let's go!", comment:  "Let's go!") 

    // initialise table
    fartlekTableView.delegate = self
    fartlekTableView.dataSource = self
    fartlekTableView.register(UINib(nibName: "fartlekCell", bundle: nil), forCellReuseIdentifier: "FartlekTableViewCell")
    fartlekTableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: fartlekTableView.frame.size.width, height: 1))
    fartlekTableView.tableHeaderView?.backgroundColor = UIColor.clear
    fartlekTableView.isHidden = true

    // hide workout total label
    workoutTotalView.isHidden = true
    fartlekTimerLabel.font = UIFont.preferredFont(forTextStyle: .title2)
    fartlekPaceLabel.font = UIFont.preferredFont(forTextStyle: .title2)
    fartlekDistLabel.font = UIFont.preferredFont(forTextStyle: .title2)

    // set up buttons ready to start workout
    setButtonsForStart()

    fileDateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"

    dateFormatterForHHMMSS.dateFormat = "HH:mm:ss"
    numberFormatter.numberStyle = .decimal
    numberFormatter.minimumFractionDigits = 2
    numberFormatter.maximumFractionDigits = 2
    numberFormatter.roundingMode = .up

  }

  func setButtonsForStart() {
    self.stopButton.tintColor = UIColor.systemGray
    self.pauseButton.tintColor = UIColor.systemGray
    self.startButton.tintColor = UIColor.systemGreen
    self.stopButton.isEnabled = false
    self.pauseButton.isEnabled = false
    self.startButton.isEnabled = true
  }

  func setSummaryForStart() {

  }

  @IBAction func btnStart(_ sender: Any) {

    self.navigationItem.hidesBackButton = true

    audio.stopSpeaking()

    if workoutStatus == .paused {
      // if workout is paused, resume it

      self.stopButton.tintColor = UIColor.systemRed
      self.pauseButton.tintColor = UIColor.systemOrange
      self.startButton.tintColor = UIColor.systemGray

      self.stopButton.isEnabled = true
      self.pauseButton.isEnabled = true
      self.startButton.isEnabled = false

      if activityType == .auto {
        // show the current Interval
        fartlekCurrentStackView.isHidden = false

        let workoutResumedDate = Date()
        guard let pausedDate = self.workoutPausedDate else {
          MyFunc.logMessage(.error, "WorkoutViewController: workoutPausedDate has no value")
          return
        }

        if pausedDate > workoutResumedDate {
          MyFunc.logMessage(.error, "WorkoutViewController: workoutPausedDateInterval could not be created")
          return
        }

        let workoutPausedDateInterval = DateInterval(start: pausedDate, end: workoutResumedDate)
        let workoutPausedTimeInterval = workoutPausedDateInterval.duration
        workoutPausedTotal = workoutPausedTotal! +  workoutPausedTimeInterval

        let workoutResumedDateInterval = DateInterval(start: workoutResumedDate, end: workoutResumedDate)
        let workoutResumedEvent = HKWorkoutEvent(type: .resume, dateInterval: workoutResumedDateInterval, metadata: ["Type": "Resume"])
        workoutEventArray.append(workoutResumedEvent)

        fartlekTimer.start()
        Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(WorkoutViewController.updateWorkoutDurationLabel(_:)), userInfo: nil, repeats: true)
        runAutoWorkout()
      } else {

        manualIntervalEndTime = Date().addingTimeInterval(manualIntervalTimeLeft)
        intervalTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(updateIntervalTime), userInfo: nil, repeats: true)
        runManualWorkout()

      }

      let resumePhraseLocalized = NSLocalizedString("Resuming workout", comment: "Resuming workout")
      audio.speak(phrase: resumePhraseLocalized)
      workoutStatus = .started

    } else {

      // set buttons for starting new workout state
      self.stopButton.tintColor = UIColor.systemRed
      self.pauseButton.tintColor = UIColor.systemGray
      self.startButton.tintColor = UIColor.systemGray

      self.stopButton.isEnabled = true
      // pause button disabled during countdown phase
      self.pauseButton.isEnabled = false
      self.startButton.isEnabled = false

      MyFunc.logMessage(.info, "btnStart pressed, starting new Workout")

      // set all variables ready for new Workout
      intervalCount = 0
      countdownTimeLeft = 3.1
      previousMotionType = ""
      previousMotionTypeForUpdate = ""
      currentMotionType = ""
      fartlekStartStr = ""
      fartlekEndStr = ""
      fartlekStartDate = nil
      fartlekEndDate  = nil
      workoutStartDate = nil
      workoutEndDate = nil
      fartlekTimerLabel.text = "0.0"
      fartlekDistLabel.text = "0.0"
      fartlekPaceLabel.text = "0.0"
      workoutTotalView.isHidden = true
      fartlekTimerLabel.font = UIFont.preferredFont(forTextStyle: .title2)
      fartlekPaceLabel.font = UIFont.preferredFont(forTextStyle: .title2)
      fartlekDistLabel.font = UIFont.preferredFont(forTextStyle: .title2)
      workoutPausedTotal = 0

      displayCountdownTimer()
      fartlekArray.removeAll()
      fartlekTableView.reloadData()
      workoutStatus = .started

    } // if workoutStatus = .paused

  } // btnStart

  @IBAction func btnPause(_ sender: Any) {

    audio.stopSpeaking()
    let pausePhraseLocalized = NSLocalizedString("Pausing workout", comment: "Pausing workout")
    audio.speak(phrase: pausePhraseLocalized)

    // set buttons for paused state
    self.stopButton.tintColor = UIColor.systemRed
    self.pauseButton.tintColor = UIColor.systemGray
    self.startButton.tintColor = UIColor.systemGreen

    self.stopButton.isEnabled = true
    self.pauseButton.isEnabled = false
    self.startButton.isEnabled = true

    intervalTimer.invalidate()
    workoutStatus = .paused
    workoutPausedDate = Date()
    if activityType == .auto {

      if fartlekTimer.isRunning {
        fartlekTimer.stop()

        workoutStatus = .paused
        workoutPausedDate = Date()
        let workoutPausedDateInterval = DateInterval(start: workoutPausedDate!, end: workoutPausedDate!)
        let workoutPausedEvent = HKWorkoutEvent(type: .pause, dateInterval: workoutPausedDateInterval, metadata: ["Type": "Pause"])
        workoutEventArray.append(workoutPausedEvent)
        self.fartlekEndDate = Date()

        guard let startDate = self.fartlekStartDate else {
          MyFunc.logMessage(.error, "Error accessing fartlekStartDate")
          return
        }
        // add the current interval to fartlekArray
        addInterval(startDate: startDate, endDate: self.fartlekEndDate!, motionType: self.previousMotionType, finalInterval: false)
        // hide the current interval view as the workout is paused (and therefore there is no "current" interval)
        fartlekCurrentStackView.isHidden = true

      }

    }
  }

  @IBAction func btnStop(_ sender: Any) {
    endWorkout()
  }

  func endWorkout() {

    MyFunc.logMessage(.debug, "btnStop pressed")
    setButtonsForStart()
    self.navigationItem.hidesBackButton = false
    locationManager.stopUpdatingLocation()
    motionActivityManager.stopActivityUpdates()
    audio.stopSpeaking()

    // if workout was running or is paused, stop and then save workout
    // (otherwise workout will be cancelled)
    if fartlekTimer.isRunning  || workoutStatus == .paused {

      if workoutStatus == .paused {
        // if moving from paused state to stop, ignore the last pause
        workoutEndDate = workoutPausedDate
      } else {

        // if auto-detection is on, record the final interval
        if activityType == .auto {

          fartlekEndDate = Date()

          guard let startDate = self.fartlekStartDate else {
            MyFunc.logMessage(.error, "Error accessing fartlekStartDate")
            return
          }

          addInterval(startDate: startDate, endDate: self.fartlekEndDate!, motionType: self.previousMotionType, finalInterval: false)
        }

      }
      workoutEndDate = Date()
      workoutStatus = .stopped
      fartlekTimer.stop()
      intervalTimer.invalidate()
      countdownTimerLabel.text = "00:00"
      let finishPhraseLocalized = NSLocalizedString("Finishing workout", comment: "")
      audio.speak(phrase: finishPhraseLocalized)

      // remove any pauses from the workout total
      let pausedTotal = self.workoutPausedTotal ?? 0

      let workoutEndMinusPauses = Date(timeInterval: -(pausedTotal), since: workoutEndDate!)
      workoutDurationDateInterval = DateInterval(start: workoutStartDate!, end: workoutEndMinusPauses)

      // update UI with latest data
      self.fartlekTableView.reloadData()
      self.view.layoutIfNeeded()
      self.scrollToBottom(animated: false)

      guard let startDate = self.workoutStartDate else {
        MyFunc.logMessage(.error, "WorkoutViewController btnStop : workoutStartDate has no value")
        return
      }

      // get average pace and distance for entire Workout
      pedometer.queryPedometerData(from: startDate, to: workoutEndDate!) {
        (pedometerData: CMPedometerData!, error) -> Void in

        if error == nil {
          self.workoutPace = Double(truncating: pedometerData.averageActivePace ?? 0)
          self.workoutDistance = Double(truncating: pedometerData.distance ?? 0)
          DispatchQueue.main.async { [self] in

            let paceString = MyFunc.getUnitSpeedAsString(value: self.workoutPace, unitSpeed: unitSpeed, formatter: measurementFormatter)

            self.fartlekPaceLabel.text = NSLocalizedString("\(paceString)", comment: "#bc-ignore!")
            let distanceString = MyFunc.getUnitLengthAsString(value: self.workoutDistance, unitLength: unitLength, formatter: measurementFormatter)
            self.fartlekDistLabel.text = NSLocalizedString("\(distanceString)", comment:  "#bc-ignore!")
            self.fartlekPaceLabel.backgroundColor = self.fartlekDistLabel.backgroundColor

          }
        } else {
          MyFunc.logMessage(.error, "Error querying Pedometer Data: \(String(describing: error))")
        }
      }

      // get the full workout Duration
      if workoutStartDate! >= workoutEndMinusPauses {
        MyFunc.logMessage(.critical, "Error setting workoutDurationDateInterval: wsd: \(self.workoutStartDate! as NSObject), wed: \(self.workoutEndDate! as NSObject)")
      }
      let workoutDurationTimeInterval = workoutDurationDateInterval?.duration
      let workoutDurationStr = workoutDurationTimeInterval!.toReadableString()

      if activityType == .auto {
        fartlekTimerLabel.text = workoutDurationStr
        fartlekTimerLabel.font = fartlekTimerLabel.font.bold()
        fartlekPaceLabel.font = fartlekPaceLabel.font.bold()
        fartlekDistLabel.font = fartlekDistLabel.font.bold()
        tableHeaderStackView.isHidden = false
        fartlekCurrentStackView.isHidden = false
        workoutTotalView.isHidden = false

        self.fartlekTableView.reloadData()
        self.view.layoutIfNeeded()
        self.scrollToBottom(animated: false)
      }

      // add each Sample Array to the Workout
      addSamplesToWorkout(sampleArray: activeEnergySampleArray)
      addSamplesToWorkout(sampleArray: distanceSampleArray)
      addSamplesToWorkout(sampleArray: basalEnergySampleArray)

      // create Workout Events for each Interval
      for fartlek in 0..<fartlekArray.count {
        let fartlekInterval = fartlekArray[fartlek]
        // note : Event metadata does not appear to be visible
        let fartlekEvent = HKWorkoutEvent(type: HKWorkoutEventType.segment, dateInterval: fartlekInterval.duration!, metadata: ["Type": fartlekInterval.activity])
        workoutEventArray.append(fartlekEvent)
      }

      // add the Workout Events to the Workout
      self.builder.addWorkoutEvents(self.workoutEventArray, completion: {(success, error) in

        guard success == true else {
          MyFunc.logMessage(.debug, "Error appending workout event to array: \(String(describing: error))")
          return
        }
        MyFunc.logMessage(.info, "Events added to Workout:")
        MyFunc.logMessage(.info, String(describing: self.workoutEventArray))

        // end Workout Builder data collection
        self.builder.endCollection(withEnd: Date(), completion: { (success, error) in
          guard success else {
            MyFunc.logMessage(.error, "Error ending Workout Builder data collection: \(String(describing: error))")
            return
          }

          // save the Workout
          self.builder.finishWorkout { [self] (savedWorkout, error) in

            guard savedWorkout != nil else {
              MyFunc.logMessage(.error, "Failed to save Workout with error : \(String(describing: error))")
              return
            }

            MyFunc.logMessage(.info, "Workout saved successfully:")
            MyFunc.logMessage(.info, String(describing: savedWorkout))

            // insert the route data from the Location array
            routeBuilder.insertRouteData(LocationManager.sharedInstance.locationDataArray) { (success, error) in
              if !success {
                MyFunc.logMessage(.error, "Error inserting Route data: \(String(describing: error))")
              }
            }
            
            // save the Workout Route
            routeBuilder.finishRoute(with: savedWorkout!, metadata: ["Activity Type": "Fartleks"]) {(workoutRoute, error) in
              guard workoutRoute != nil else {
                MyFunc.logMessage(.error, "Failed to save Workout Route with error : \(String(describing: error))")
                return
              }

              MyFunc.logMessage(.debug, "Workout Route saved successfully:")
              MyFunc.logMessage(.debug, String(describing: workoutRoute))
              MyFunc.logMessage(.debug, "Saved Events: \(String(describing: savedWorkout?.workoutEvents))")
              exportLog()

            } // self.routeBuilder

          } // self.builder.finishWorkout

        }) // self.builder.endCollection

      }) // self.builder.addWorkoutEvents
      let completedTitle = NSLocalizedString("Workout completed", comment: "")
      let completedMessage = NSLocalizedString("Your workout has been saved successfully", comment: "")
      displayAlert(title: completedTitle, message: completedMessage)

    } else {

      let cancelPhraseLocalized = NSLocalizedString("Cancelling workout", comment: "Cancelling workout")
      audio.speak(phrase: cancelPhraseLocalized)
      workoutStatus = .cancelled
      fartlekArray.removeAll()

      countdownTimeLeft = 0
      countdownView.isHidden = true
      countdownTimerLabel.text = "00:00"
      self.view.layoutIfNeeded()

      // end Workout Builder data collection
      self.builder.endCollection(withEnd: Date(), completion: { (success, error) in
        guard success else {
          MyFunc.logMessage(.error, "Error ending Workout Builder data collection: \(String(describing: error))")
          return
        }
      })
      displayAlert(title: "Workout cancelled", message: "Cancelled workout")

    }// if workoutStatus = .stopped

    self.navigationItem.hidesBackButton = false
  }

  // main function for tracking running / walking / stationary activity
  func runManualWorkout() {

    // next process each interval in turn
    if getNextInterval == true {
      getNextInterval = false

      let intervalNumber = intervalCount + 1
      let intervalNumberStr = String(intervalNumber)
      let setStr = NSLocalizedString("Set ", comment: "Set")
      let ofStr = NSLocalizedString(" of ", comment: "of")
      let setsFullLabel = setStr + intervalNumberStr + ofStr + totalSetStr
      setLabel.text = setsFullLabel


      let activityTypeForDisplay = intervalTemplateArray[intervalCount].intervalType.rawValue
      let activityTypeLocalized = NSLocalizedString("\(activityTypeForDisplay)", comment: "\(activityTypeForDisplay)")
      activityTypeLabel.text = activityTypeLocalized
      // set UI for current activity Type
      updateUIForIntervalType(intervalTemplateArray[intervalCount].intervalType)

      let newIntervalPhrase = "\(intervalTemplateArray[intervalCount].intervalType) now"
      let newIntervalPhraseLocalized = NSLocalizedString("\(newIntervalPhrase)", comment: "Localized version of starting phrase")
      MyFunc.logMessage(.debug, "newIntervalPhraseLocalized: \(newIntervalPhraseLocalized)")
      audio.speak(phrase: newIntervalPhraseLocalized)

      let vibratePhone = defaults.object(forKey: "Vibration") as? String ?? ""
      if vibratePhone == "On" {
        AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
      }
      manualIntervalTimeLeft = intervalTemplateArray[intervalCount].duration
      manualIntervalEndTime = Date().addingTimeInterval(manualIntervalTimeLeft)
      intervalTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(updateIntervalTime), userInfo: nil, repeats: true)

    }

  } // func runManualWorkout

  func updateUIForIntervalType(_ intervalType: IntervalType ) {

    var activityBackground = UIColor.clear
    switch intervalType {
    case .warmup, .cooldown:
      activityBackground = theme.navBar
    case .work:
      activityBackground = .red
    case .rest:
      activityBackground = .orange
    default:
      activityBackground = .clear
    }
    activityDurationView.backgroundColor = activityBackground
    activityTypeLabel.backgroundColor = activityBackground
    activityTypeLabel.layer.cornerRadius = 9
    durationLeftLabel.backgroundColor = activityBackground

  }

  @objc func updateIntervalTime() {
    if manualIntervalTimeLeft > 0 {

      manualIntervalTimeLeft = manualIntervalEndTime?.timeIntervalSinceNow ?? 0
      durationLeftLabel.text = manualIntervalTimeLeft.time

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
            MyFunc.logMessage(.debug, "activityPhraseLocalized: \(activityPhraseLocalized)")
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
      fartlekTimerLabel.text = "00:00"
      intervalTimer.invalidate()

      intervalCount += 1

      if intervalCount == intervalTemplateArray.count {
        // if last interval reached, end the workout
        endWorkout()
      } else {
        getNextInterval = true

        runManualWorkout()
      }
    }

  } //updateIntervalTime()

  // main function managing motion and activity tracking
  func runAutoWorkout() {

    fartlekStartDate = Date()

    // on initial query, check last ten minutes to get most recent activity
    let workoutStartDateLeadup = Calendar.current.date(byAdding: .second, value: -600, to: workoutStartDate!)

    motionActivityManager.queryActivityStarting(from: workoutStartDateLeadup!, to: workoutStartDate!, to: .main, withHandler: {
      (activities, error) in

      if error == nil {

        MyFunc.logMessage(.info, "Activities from queryActivityStarting: \(String(describing: activities))")

        // get most recent activity motion type
        let lastActivity = activities?.last
        if lastActivity?.running == true {
          self.currentMotionType = "Running"
        } else {
          if lastActivity?.walking == true {
            self.currentMotionType = "Walking"
          } else {
            self.currentMotionType = "Stationary"
          }
        }

        // set the inital previous motion type to the current one
        self.previousMotionType = self.currentMotionType
        self.previousMotionTypeForUpdate = self.previousMotionType
      } else {
        MyFunc.logMessage(.error, "Error getting initial motion: \(String(describing: error))")
      }

    }) //  motionActivityManager.queryActivityStarting

    if CMPedometer.isPedometerEventTrackingAvailable() {
      pedometer.startEventUpdates(handler: {(_, error) in
        if error != nil {
          let errorStr = String(describing: error)
          MyFunc.logMessage(.error, "Error in queryPedometerData: \(errorStr)")
        }
      })
    }

    if CMMotionActivityManager.isActivityAvailable() {

      motionActivityManager.startActivityUpdates(to: .main, withHandler: { [self](motion) in
        MyFunc.logMessage(.debug, "motion: \(String(describing: motion))")

        let motionChangedDate = motion?.startDate

        // set current motion type
        // Running overrides Walking which in turn overrides Stationary
        if motion?.running == true {
          self.currentMotionType = "Running"
        } else {
          if motion?.walking == true {
            self.currentMotionType = "Walking"
          } else {
            self.currentMotionType = "Stationary"
          }
        }

        if self.workoutStatus == .started {
          // if the Motion Type has changed, record a new interval
          if self.currentMotionType != self.previousMotionType {

            MyFunc.logMessage(.debug, "Motion type changed from \(self.previousMotionType) to \(self.currentMotionType) with confidence \(String(describing: motion?.confidence))")

            // if the CMMotionActivityManager's confidence in the motion is greater than or equal to the set threshold
            guard let motionConfidence = motion?.confidence.rawValue else {
              MyFunc.logMessage(.debug, "No motion confidence detected")
              return
            }
            if motionConfidence >= self.confidenceThreshold {

              // set the colour of the current Interval according to the detected Motion Type
              var currIntervalColour: UIColor = .clear
              switch self.currentMotionType {
              case "Walking":
                currIntervalColour = .orange
              case "Running":
                currIntervalColour = .red
              case "Stationary":
                currIntervalColour = .green
              default:
                currIntervalColour = .clear
              }

              DispatchQueue.main.async {
                self.fartlekCurrentPaceView.backgroundColor = currIntervalColour
                self.fartlekPaceLabel.textColor = UIColor.white
              }

              // If there is no previousMotionType, capture the current motion as the first type of Interval.
              // When the next motionType change is detected, or the workout is ended manually, the Interval will be recorded.
              // Until a motionType change is detected, the Workout will not start
              if self.previousMotionType == "" {

                if motionChangedDate! > workoutStartDate! {

                  // set the interval start date from the point motion changed
                  self.fartlekStartDate = motionChangedDate
                  self.fartlekTimer.start()
                  Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(WorkoutViewController.updateWorkoutDurationLabel(_:)), userInfo: nil, repeats: true)
                } else {
                  MyFunc.logMessage(.debug, "motionChangedDate before WorkoutStartDate")
                  MyFunc.logMessage(.debug, "motionChangedDate: \(String(describing: motionChangedDate))")
                  MyFunc.logMessage(.debug, "workoutStartDate: \(String(describing: workoutStartDate))")
                }

              } else {

                let recordingPhrase = "Recording " + self.previousMotionType + " interval"
                let recordingPhraseLocalized = NSLocalizedString("\(recordingPhrase)", comment: "")
                MyFunc.logMessage(.debug, "recordingPhraseLocalized: \(recordingPhraseLocalized)")
                audio.speak(phrase: recordingPhraseLocalized)

                // Previous Motion Type exists so record interval just completed
                // write this to additional variable to avoid update of previousMotionType in any asynchronous thread
                self.previousMotionTypeForUpdate = self.previousMotionType

                self.fartlekEndDate = motionChangedDate
                let intervalEndDate = self.fartlekEndDate!
                guard let intervalStartDate = self.fartlekStartDate else {
                  MyFunc.logMessage(.error, "WorkoutViewController: fartlekStartDate null")
                  return
                }

                addInterval(startDate: intervalStartDate, endDate: intervalEndDate, motionType: self.previousMotionType, finalInterval: false)

                // restart the timer for the next Interval
                self.fartlekTimer.start()
                Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(WorkoutViewController.updateWorkoutDurationLabel(_:)), userInfo: nil, repeats: true)

              } // else (self.previousMotionType != ""...)

              self.previousMotionType = self.currentMotionType

            } // if (motion?.confidence.rawValue)! >= self.confidence

          } // if self.currentMotionType != self.previousMotionType

        } // if workoutStatus = .started

      }) // motionActivityManager...

    } // if CMMotionActivityManager...

  } // func runAutoWorkout

  // this function writes the Interval
  func addInterval(startDate: Date, endDate: Date, motionType: String, finalInterval: Bool) {

    var newFartlekInterval  = Interval()
    let intervalStartDate   = startDate
    let intervalEndDate     = endDate
    let intervalMotionType  = motionType

    if intervalStartDate > intervalEndDate {
      MyFunc.logMessage(.critical, "Error setting newFartlekInterval.duration: sd: \(intervalStartDate as NSObject), ed: \(intervalEndDate as NSObject)")
    }

    MyFunc.logMessage(.debug, "addInterval self.previousMotionTypeForUpdate: \(self.previousMotionTypeForUpdate)")
    MyFunc.logMessage(.debug, "addInterval self.previousMotionType: \(self.previousMotionType)")

    newFartlekInterval.activity    = intervalMotionType
    newFartlekInterval.startDate   = intervalStartDate
    newFartlekInterval.endDate     = intervalEndDate
    newFartlekInterval.duration    = DateInterval(start: intervalStartDate, end: intervalEndDate)

    self.pedometer.queryPedometerData(from: intervalStartDate, to: intervalEndDate) {

      (pedometerData: CMPedometerData!, error) -> Void in

      if error == nil {

        // populate new Interval
        newFartlekInterval.distance    = pedometerData.distance ?? 0
        newFartlekInterval.pace        = pedometerData.averageActivePace ?? 0
        newFartlekInterval.steps       = pedometerData.numberOfSteps
        newFartlekInterval.cadence     = pedometerData.currentCadence ?? 0

        self.fartlekArray.append(newFartlekInterval)
        DispatchQueue.main.async {
          self.fartlekTableView.reloadData()
          self.view.layoutIfNeeded()
          self.scrollToBottom(animated: false)
        } // DispatchQueue

        self.fartlekStartDate = intervalEndDate

        // create Samples
        guard let distanceType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.distanceWalkingRunning),
              let activeEnergyType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.activeEnergyBurned),
              let basalEnergyType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.basalEnergyBurned)
        else {
          MyFunc.logMessage(.error, "Sample Types not available in HealthKit")
          return
        }

        // create Distance Sample
        let distanceDouble: Double = pedometerData.distance?.doubleValue ?? 0.0
        let distanceQuantity = HKQuantity(unit: HKUnit.meter(), doubleValue: distanceDouble)
        let distanceSample = HKQuantitySample(type: distanceType, quantity: distanceQuantity, start: intervalStartDate, end: intervalEndDate, device: .local(), metadata: ["Activity Type": intervalMotionType])
        self.distanceSampleArray.append(distanceSample)
        self.sampleArray.append(distanceSample)

        // create Active Energy Sample
        let activeEnergySample = self.getSampleForType(startDate: intervalStartDate, endDate: intervalEndDate, quantityType: activeEnergyType)
        self.sampleArray.append(activeEnergySample)

        // create Basal Energy Sample
        let basalEnergySample = self.getSampleForType(startDate: intervalStartDate, endDate: intervalEndDate, quantityType: basalEnergyType)
        self.sampleArray.append(basalEnergySample)

      } // if error == nil

    } // self.pedometer.queryPedometerData

  } // func addInterval

  @objc func updateWorkoutDurationLabel(_ timer: Timer) {
    // this function updates the duration, distance and pace for the current Interval
    if fartlekTimer.isRunning {
      let currentElapsedTime = fartlekTimer.elapsedTime.toReadableString()
      fartlekTimerLabel.text = currentElapsedTime

      guard let startDate = fartlekStartDate else {
        MyFunc.logMessage(.error, "updateWorkoutDurationLabel : fartlekStartDate null")
        return
      }
      getIntervalFromDate(startDate: startDate)

    } else {
      timer.invalidate()
    }
  }

  func getIntervalFromDate (startDate: Date) {

    // this function gets CMPedometer data from a specified date and returns data for the current (in progress) interval
    let endDate = Date()
    var currentInterval = Interval()
    self.pedometer.queryPedometerData(from: startDate, to: endDate) { [self]

      (pedometerData: CMPedometerData!, error) -> Void in

      if error == nil {

        currentInterval.distance    = pedometerData.distance ?? 0
        currentInterval.pace        = pedometerData.averageActivePace ?? 0

        // get the distance and pace formatted according to the user's preferred measurement
        let fartlekPaceStr = MyFunc.getUnitSpeedAsString(value: self.workoutPace, unitSpeed: unitSpeed, formatter: measurementFormatter)
        let fartlekDistanceStr = MyFunc.getUnitLengthAsString(value: self.workoutDistance, unitLength: unitLength, formatter: measurementFormatter)


        // update the UI immediately
        DispatchQueue.main.async {
          self.fartlekDistLabel.text = fartlekDistanceStr
          self.fartlekPaceLabel.text = fartlekPaceStr
        }

      } else {
        MyFunc.logMessage(.error, "Error in queryPedometerData: \(String(describing: error))")
      }
    }
  }

  func scrollToBottom(animated: Bool) {

    if self.isViewLoaded {
      let point = CGPoint(x: 0, y: self.fartlekTableView.contentSize.height + self.fartlekTableView.contentInset.bottom - self.fartlekTableView.frame.height)
      if point.y >= 0 {
        self.fartlekTableView.setContentOffset(point, animated: animated)
      }
    }
  }

  // this function returns a HealthKit Sample for a given period and quantity type
  func getSampleForType(startDate: Date, endDate: Date, quantityType: HKQuantityType) -> HKSample {

    let queryStartDate = startDate
    let queryEndDate = endDate
    var quantityValue: Double = 0.0

    let quantityPredicate = HKQuery.predicateForSamples(withStart: queryStartDate, end: queryEndDate)

    let quantityStatsQuery = HKStatisticsQuery(quantityType: quantityType, quantitySamplePredicate: quantityPredicate, options: .cumulativeSum) { (_, statisticsOrNil, _) in

      guard let statistics = statisticsOrNil else {
        MyFunc.logMessage(.error, "Error getting quantity")
        return
      }

      let sum = statistics.sumQuantity()
      quantityValue = (sum?.doubleValue(for: HKUnit.largeCalorie()))!

    }
    healthStore.execute(quantityStatsQuery)
    MyFunc.logMessage(.debug, "StatsQuery for Quantity returned: \(quantityStatsQuery)")

    let quantity = HKQuantity(unit: HKUnit.kilocalorie(), doubleValue: quantityValue)
    let quantitySample = HKQuantitySample(type: quantityType, quantity: quantity, start: queryStartDate, end: queryEndDate, metadata: ["": ""])

    return quantitySample
  }

  func getActiveEnergyBurned(startDate: Date, endDate: Date) -> Double {

    let queryStartDate = startDate
    let queryEndDate = endDate
    var activeEnergyBurned: Double = 0.0

    let activeEnergyType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.activeEnergyBurned)
    let activityPredicate = HKQuery.predicateForSamples(withStart: queryStartDate, end: queryEndDate)

    let activityStatsQuery = HKStatisticsQuery(quantityType: activeEnergyType!, quantitySamplePredicate: activityPredicate, options: .cumulativeSum) { (_, statisticsOrNil, _) in

      guard let statistics = statisticsOrNil else {
        MyFunc.logMessage(.error, "Error getting Active Energy")
        return
      }

      let sum = statistics.sumQuantity()
      activeEnergyBurned = (sum?.doubleValue(for: HKUnit.largeCalorie()))!

    }
    healthStore.execute(activityStatsQuery)
    MyFunc.logMessage(.debug, "StatsQuery for Active Energy returned: \(activityStatsQuery)")
    return activeEnergyBurned
  }

  // if this works without changes combine into single query function
  func getBasalEnergyBurned(startDate: Date, endDate: Date) -> Double {

    let queryStartDate = startDate
    let queryEndDate = endDate
    var basalEnergyBurned: Double = 0.0

    let basalEnergyType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.basalEnergyBurned)
    let basalPredicate = HKQuery.predicateForSamples(withStart: queryStartDate, end: queryEndDate)

    let basalStatsQuery = HKStatisticsQuery(quantityType: basalEnergyType!, quantitySamplePredicate: basalPredicate, options: .cumulativeSum) { (_, statisticsOrNil, _) in

      guard let statistics = statisticsOrNil else {
        MyFunc.logMessage(.error, "Error getting Basal Energy")
        return
      }

      let sum = statistics.sumQuantity()
      basalEnergyBurned = (sum?.doubleValue(for: HKUnit.largeCalorie()))!

    }
    healthStore.execute(basalStatsQuery)
    MyFunc.logMessage(.debug, "StatsQuery for Basal Energy returned: \(basalStatsQuery)")
    return basalEnergyBurned
  }



  // Core Location code to get the current location
  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {

    let currentLocation = locations[locations.count - 1]
    //    let locationStr = String(describing: currentLocation)
    MyFunc.logMessage(.debug, "Current Location Found: \(currentLocation)")

    // Filter the raw data.
    let filteredLocations = locations.filter { (location: CLLocation) -> Bool in
      location.horizontalAccuracy <= 50.0
    }

    guard !filteredLocations.isEmpty else { return }

    locationArray.append(currentLocation.coordinate)
    MyFunc.logMessage(.debug, "Appended currentLocation \(currentLocation) to locationArray")
    MyFunc.logMessage(.debug, "locationArray:")
    MyFunc.logMessage(.debug, String(describing: locationArray))

    // Add the filtered data to the route.
    routeBuilder.insertRouteData(filteredLocations) { (success, error) in
      if !success {
        MyFunc.logMessage(.error, "Error inserting Route data: \(String(describing: error))")
      }
    }
  }

  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    MyFunc.logMessage(.error, "Error attepting to get Location: \(String(describing: error))")
  }

  func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    let headerView = UIView(frame: .zero)
    headerView.isUserInteractionEnabled = false
    return headerView
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return fartlekArray.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

    let cell = tableView.dequeueReusableCell(withIdentifier: "FartlekTableViewCell", for: indexPath) as! FartlekTableViewCell

    // format distance including metric / imperial conversion as required
    let distanceAsDouble = Double(truncating: fartlekArray[indexPath.row].distance)
    let distanceString = MyFunc.getUnitLengthAsString(value: distanceAsDouble, unitLength: unitLength, formatter: measurementFormatter)
    cell.distanceLabel.text = distanceString

    let paceAsDouble = Double(truncating: fartlekArray[indexPath.row].pace)
    let paceString = MyFunc.getUnitSpeedAsString(value: paceAsDouble, unitSpeed: unitSpeed, formatter: measurementFormatter)
    cell.paceLabel.text = paceString
    cell.paceLabel.textColor = UIColor.white

    let duration = fartlekArray[indexPath.row].duration?.duration

    let durationStr = duration?.toReadableString()
    cell.durationLabel.text = durationStr

    switch fartlekArray[indexPath.row].activity {
    case "Walking":
      cell.distanceView.backgroundColor = .orange
    case "Running":
      cell.distanceView.backgroundColor = .red
    case "Stationary":
      cell.distanceView.backgroundColor = .green

    default:
      cell.distanceView.backgroundColor = .clear
    }

    return cell

  }

  func exportLog() {

    // generate filename including timestamp
    let currDate = fileDateFormatter.string(from: Date())
    let fileName = "Heatmapper_Log_" + currDate + ".txt"

    guard let path = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent(fileName) as NSURL else {
      return }

    do {
      try log.write(to: path as URL, atomically: true, encoding: String.Encoding.utf8)
      MyFunc.logMessage(.info, "Log data written to \(path)")
    } catch {
      MyFunc.logMessage(.error, "Failed to create file with error \(String(describing: error))")
    } // catch

  }

  func logMessage(string: String) {
    let currDate = dateFormatterForHHMMSS.string(from: Date())
    let logStr = currDate + " : " + string + "\n"
    log.append(logStr)
    // print only when debugging
    //    print(logStr)
  }

  func displayAlert (title: String, message: String) {

    //Alert user that Save has worked
    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
    let okAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: {(_: UIAlertAction!) in
      if MyFunc.removeAdsPurchased() == false {
        if self.interstitial.isReady {
          self.interstitial.present(fromRootViewController: self)

        } else {
          MyFunc.logMessage(.debug, "Ad wasn't ready")
        }
      }
    })
    let healthActionTitle = NSLocalizedString("Open Health app", comment: "Open Health app")
    let healthAction = UIAlertAction(title: healthActionTitle,
                                     style: UIAlertAction.Style.default,
                                     handler: {(_: UIAlertAction!) in
                                      // open HealthKit app - note current URL only opens the app at root or where previous session was
                                      MyFunciOS.openUrl(urlString: "x-apple-health:root&path=BROWSE")
                                     })
    alert.addAction(okAction)
    if workoutStatus != .cancelled {
      alert.addAction(healthAction)
    }
    present(alert, animated: true, completion: nil)

  }

  func hideCountdownTimer() {
    fartlekTableView.isHidden = false
    countdownCircle.removeFromSuperlayer()
    timeLeftArc.removeFromSuperlayer()
    countdownView.isHidden = true
  }

  func displayManualActivityTracker() {
    activityDurationView.isHidden = false
    activityTypeLabel.isHidden = false
    setLabel.isHidden = false
    durationLeftLabel.isHidden = false
    activityTypeLabel.textColor = theme.navBarTitle
    durationLeftLabel.textColor = theme.textAlternate
  }

  func displayCountdownTimer() {

    // hide views to give room for Countdown View
    fartlekArray.removeAll()
    fartlekTableView.reloadData()
    fartlekCurrentStackView.isHidden  = true
    activityTypeLabel.isHidden = true
    setLabel.isHidden = true
    activityDurationView.isHidden = true
    countdownView.isHidden = false
    self.view.setNeedsLayout()
    self.view.layoutIfNeeded()

    drawCircle()
    drawTimeLeftShape()
    countdownTimerLabel.text = countdownTimeLeft.time
    timeLeftFill.fromValue = 0
    timeLeftFill.toValue = 1
    timeLeftFill.duration = 3
    timeLeftArc.add(timeLeftFill, forKey: nil)
    countdownTimeLeft = 3.1
    countdownEndTime = Date().addingTimeInterval(countdownTimeLeft)
    countdownTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(updateTime), userInfo: nil, repeats: true)

  }

  @objc func updateTime() {
    if countdownTimeLeft > 0 {

      countdownTimeLeft = countdownEndTime?.timeIntervalSinceNow ?? 0
      countdownTimerLabel.text = countdownTimeLeft.time

      let timeby10 = countdownTimeLeft * 10
      let roundedTimeby10 = round(timeby10)
      let roundedTimeby10asInt = Int(roundedTimeby10)

      let roundedTimeLeft = round(countdownTimeLeft)
      let roundedTimeAsInt = Int(roundedTimeLeft)
      let roundedTimeAsIntby10 = roundedTimeAsInt * 10

      if roundedTimeAsIntby10 == roundedTimeby10asInt {
        if roundedTimeby10asInt > 0 {
          audio.playSound(filename: "FiT_second_beep", fileExtension: "aif")
        } else {

          audio.playSound(filename: "FIT_minute_beep", fileExtension: "aif")
        }
      }

    } else {
      countdownTimerLabel.text = "00:00"
      countdownTimer.invalidate()

      if workoutStatus == .started {
        self.pauseButton.tintColor = UIColor.systemOrange
        self.pauseButton.isEnabled = true
        self.hideCountdownTimer()

        if activityType == .auto {
          fartlekCurrentStackView.isHidden  = false
          tableHeaderStackView.isHidden = false
          fartlekTableView.isHidden = false
        }
        self.fartlekTimer.start()
        self.workoutStartDate = Date()

        self.locationManager.startUpdatingLocation()

        // begin collecting Workout data
        self.builder.beginCollection(withStart: Date(), completion: { (success, error) in
          guard success else {
            MyFunc.logMessage(.error, "Error beginning data collection in Workout Builder: \(String(describing: error))")
            return
          }

        })

        // execute main event tracking process
        switch activityType {
        case .auto:
          Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(WorkoutViewController.speakStartingWorkout(_:)), userInfo: nil, repeats: false)
          intervalTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(WorkoutViewController.updateWorkoutDurationLabel(_:)), userInfo: nil, repeats: true)
          runAutoWorkout()

        case .repeat, .tabata:
          displayManualActivityTracker()

          // get Repeat / Tabata intervals as required
          intervalTemplateArray.removeAll()
          intervalTemplateArray = MyFunc.createRepeatIntervalSet(activityTemplate)
          totalSetStr = String(intervalTemplateArray.count)
          //          totalSetLabel.text = totalSetsStr
          getNextInterval = true
          runManualWorkout()

        case .pyramid:
          displayManualActivityTracker()
          // for manual activity types, get the defaults

          // decompose these into an array
          intervalTemplateArray.removeAll()
          intervalTemplateArray = MyFunc.createCustomIntervalSet(activityTemplate)
          MyFunc.logMessage(.debug, String(describing: intervalTemplateArray))
          totalSetStr = String(intervalTemplateArray.count)
          //          totalSetLabel.text = totalSetsStr
          getNextInterval = true
          runManualWorkout()

        case .random:
          displayManualActivityTracker()
          // for manual activity types, get the defaults
          activityTemplate = MyFunc.getActivityDefaults(activityType)

          // decompose these into an array
          intervalTemplateArray.removeAll()
          intervalTemplateArray = MyFunc.createRandomIntervalSet(activityTemplate)
          MyFunc.logMessage(.debug, String(describing: intervalTemplateArray))
          totalSetStr = String(intervalTemplateArray.count)
          //          totalSetLabel.text = totalSetsStr
          getNextInterval = true
          runManualWorkout()

        case .custom:
          displayManualActivityTracker()
          intervalTemplateArray.removeAll()
          intervalTemplateArray = activityTemplate.intervals
          totalSetStr = String(intervalTemplateArray.count)
          //          totalSetLabel.text = totalSetsStr
          getNextInterval = true
          runManualWorkout()

        default:
          MyFunc.logMessage(.error, "Unknown activityType \(activityType) received")

        }

      }
    } // if workoutStatus == .started

  } // func updateTimer

  @objc func speakStartingWorkout(_ timer: Timer) {
    if fartlekTimer.isRunning == true {
      let beginPhraseLocalized = NSLocalizedString("Begin activity", comment: "Begin activity")
      audio.speak(phrase: beginPhraseLocalized)
    }
  }

  func drawCircle() {

    countdownView.layer.addSublayer(countdownCircle)
    countdownCircle.name = "bgShapeLayer"
    let circle = CAShapeLayer()
    countdownCircle.frame = countdownView.bounds
    circle.path = UIBezierPath(arcCenter: CGPoint(x: countdownView.bounds.midX, y: countdownView.bounds.midY), radius:
                                (countdownView.bounds.midX * 0.8), startAngle: -90.degreesToRadians, endAngle: 270.degreesToRadians, clockwise: true).cgPath
    countdownCircle.strokeColor = theme.navBar.cgColor
    countdownCircle.fillColor = UIColor.clear.cgColor
    countdownCircle.lineWidth = countdownView.bounds.midX * 0.2
    countdownCircle.path = circle.path

  }

  // this function draws the time remaining
  func drawTimeLeftShape() {

    timeLeftArc.path = UIBezierPath(arcCenter: CGPoint(x: countdownView.bounds.midX, y: countdownView.bounds.midY), radius:
                                      (countdownView.bounds.midX * 0.8), startAngle: -90.degreesToRadians, endAngle: 270.degreesToRadians, clockwise: true).cgPath
    timeLeftArc.strokeColor = theme.navBarTint.cgColor
    timeLeftArc.fillColor = UIColor.clear.cgColor
    timeLeftArc.lineWidth = countdownView.bounds.midX * 0.2
    timeLeftArc.name = "timeLeftShapeLayer"
    countdownView.layer.addSublayer(timeLeftArc)
  }

  func addSamplesToWorkout(sampleArray: [HKSample]) {

    self.builder.add(sampleArray, completion: {(success, error) in
      guard success
      else {
        MyFunc.logMessage(.error, "Error adding Samples to workout: \(error! as NSObject)")
        return
      }
      MyFunc.logMessage(.debug, "Samples added to workout successfully")

    })

  }

  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {

    MyFunc.logMessage(.debug, "Location Status changed to:")
    let authorizationStatus = locationManager.authorizationStatus
    switch authorizationStatus {
    case .authorizedAlways:
      MyFunc.logMessage(.debug, "authorizedAlways")
    case .authorizedWhenInUse:
      MyFunc.logMessage(.debug, "authorizedWhenInUse")
    case .denied:
      MyFunc.logMessage(.debug, "denied")
    case .notDetermined:
      MyFunc.logMessage(.debug, "notDetermined")
    case .restricted:
      MyFunc.logMessage(.debug, "restricted")

    default:
      MyFunc.logMessage(.debug, "unknown (possibly new) value")
    }
  }

}
