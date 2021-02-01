//
//  SetIntervalsInterfaceController.swift
//  FIT WatchKit Extension
//
//  Created by Richard English on 09/11/2020.
//  Copyright © 2020 Richard English. All rights reserved.
//

import WatchKit
import Foundation
import os

class SetIntervalsInterfaceController: WKInterfaceController, SessionCommands {

  let logger = Logger(subsystem: "wimbledonappcompany.com.FIT.watchkitapp.watchkitextension", category: "SetIntervalsInterfaceController")

  let defaults            = UserDefaults.standard
  var setItems: [WKPickerItem] = []
  var levelItems: [WKPickerItem] = []
  var countdownTimeLeft: TimeInterval = 3.1
  var countdownEndTime: Date?
  var countdownTimer      = Timer()
  let audio               = Audio()
  var activityTemplate    = ActivityTemplate()
  var activityType        = ActivityType()
  var intervalType        = IntervalType()
  var pickersLoaded: Bool = false
  var buttonJustPressed : Bool = false

  @IBOutlet weak var warmupLabel: WKInterfaceLabel!
  @IBOutlet weak var workLabel: WKInterfaceLabel!
  @IBOutlet weak var restLabel: WKInterfaceLabel!
  @IBOutlet weak var cooldownLabel: WKInterfaceLabel!
  @IBOutlet weak var setPickerOutlet: WKInterfacePicker!
  @IBOutlet weak var levelPickerOutlet: WKInterfacePicker!

  @IBOutlet weak var setsLabel: WKInterfaceLabel!
  @IBOutlet weak var countdownTimerLabel: WKInterfaceLabel!
  @IBOutlet weak var warmupGroup: WKInterfaceGroup!
  @IBOutlet weak var startButton: WKInterfaceButton!
  @IBOutlet weak var workGroup: WKInterfaceGroup!
  @IBOutlet weak var restGroup: WKInterfaceGroup!
  @IBOutlet weak var setsGroup: WKInterfaceGroup!
  @IBOutlet weak var cooldownGroup: WKInterfaceGroup!

  @IBOutlet weak var levelGroup: WKInterfaceGroup!

  @IBOutlet weak var work: WKInterfaceLabel!

  @IBAction func btnStart() {
    preventMultiplePresses()
    presentController(withName: "Countdown Interface Controller", context: MyFunc.setContext(activityType, intervalType))
  }

  @IBAction func warmupGroupTap(_ sender: Any) {
    pushController(withName: "DurationPickerInterfaceController", context: MyFunc.setContext(activityType, .warmup))

  }

  @IBAction func restGroupTap(_ sender: Any) {
    if activityType != .tabata {
      pushController(withName: "DurationPickerInterfaceController", context: MyFunc.setContext(activityType, .rest))
    }
  }

  @IBAction func workGroupTap(_ sender: Any) {
    if activityType != .tabata {
      pushController(withName: "DurationPickerInterfaceController", context: MyFunc.setContext(activityType, .work))
    }
  }

  @IBAction func cooldownGroupTap(_ sender: Any) {
    pushController(withName: "DurationPickerInterfaceController", context: MyFunc.setContext(activityType, .cooldown))
  }

  @IBAction func setPicker(_ value: Int) {

    if activityType != .tabata {
      if pickersLoaded == true {
        let setsPicked = setItems[value].title
        let setsPickedInt: Int = Int(setsPicked ?? "0")!
        activityTemplate.sets = setsPickedInt
        MyFunc.saveActivityDefaults(activityTemplate)
        updateApplicationContextForActivityTemplate(activityTemplate: self.activityTemplate)

      }
    }
  }

  @IBAction func levelPicker(_ value: Int) {
    if pickersLoaded == true {
      let levelPicked = levelItems[value].title

      activityTemplate.activityLevel = ActivityLevel(rawValue: levelPicked ?? "None") ?? .none

      MyFunc.saveActivityDefaults(activityTemplate)
      updateApplicationContextForActivityTemplate(activityTemplate: self.activityTemplate)

    }

  }

  override func awake(withContext context: Any?) {
    super.awake(withContext: context)

    // process context received
    guard let contextReceived = context as? String
    else {
      MyFunc.logMessage(.error, "Invalid context received by WorkoutInterfaceController : \(String(describing: context))")
      return
    }

    let activityTypeFromContext = MyFunc.getContext(contextReceived).activityType
    let intervalTypeFromContext = MyFunc.getContext(contextReceived).intervalType
    activityType = activityTypeFromContext
    intervalType = intervalTypeFromContext
  }

  override func willActivate() {
    // This method is called when watch view controller is about to be visible to user
    super.willActivate()

    activityTemplate = MyFunc.getActivityDefaults(activityType)
    loadUI()
  }

  override func didDeactivate() {
    // This method is called when watch view controller is no longer visible
    super.didDeactivate()
  }

  func loadUI() {

    self.setTitle(activityType.rawValue)

    switch activityType {
    case .repeat, .pyramid, .tabata:
      restGroup.setHidden(false)
      levelGroup.setHidden(true)

      work.setText("Work")
      let workText = activityTemplate.work.duration.toMinutesAndSeconds()
      workLabel.setText(workText)

      let restText = activityTemplate.rest.duration.toMinutesAndSeconds()
      restLabel.setText(restText)

    case .random:
      restGroup.setHidden(true)
      levelGroup.setHidden(false)

      let workTextLocalized = NSLocalizedString("Activity", comment: "Set Intervals Activity")
      work.setText("\(workTextLocalized)")
      let workText = activityTemplate.work.duration.toMinutesAndSeconds()
      workLabel.setText(workText)

    default:
      MyFunc.logMessage(.error, "Unknown activityType received : \(activityType)")
    }

    let warmupText = activityTemplate.warmup.duration.toMinutesAndSeconds()
    warmupLabel.setText(warmupText)

    let cooldownText = activityTemplate.cooldown.duration.toMinutesAndSeconds()
    cooldownLabel.setText(cooldownText)

    loadSetItems()
    setPickerOutlet.setItems(setItems)
    let setsStr = String(describing: activityTemplate.sets)
    let setsIndex: Int = setItems.firstIndex(where: { $0.title == setsStr }) ?? 0
    setPickerOutlet.setSelectedItemIndex(setsIndex)

    loadLevelItems()
    levelPickerOutlet.setItems(levelItems)
    let levelIndex: Int = levelItems.firstIndex(where: { $0.title == activityTemplate.activityLevel?.rawValue}) ?? 0
    levelPickerOutlet.setSelectedItemIndex(levelIndex)
    pickersLoaded = true
  }

  func loadSetItems() {
    for set in 1...20 {

      let item = WKPickerItem()
      let itemStr = String(set)
      item.title = itemStr
      setItems.append(item)
    }
  }

  func loadLevelItems() {
    for level in 0..<ActivityLevel.allCases.count {

      let item = WKPickerItem()
      let itemStr = ActivityLevel.allCases[level].localizedDescription + ".png"
      MyFunc.logMessage(.debug, "picker image name: \(itemStr)")
      item.contentImage = WKImage(imageName: itemStr)
      levelItems.append(item)
    }
  }

  func displayCountdownTimer () {

    countdownTimeLeft = 3.1
    countdownEndTime = Date().addingTimeInterval(countdownTimeLeft)
    countdownTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(updateTime), userInfo: nil, repeats: true)

  }

  @objc func updateTime() {
    if countdownTimeLeft > 0 {

      countdownTimeLeft = countdownEndTime?.timeIntervalSinceNow ?? 0
      countdownTimerLabel.setText(countdownTimeLeft.time)

      let timeby10 = countdownTimeLeft * 10
      let roundedTimeby10 = round(timeby10)
      let roundedTimeby10asInt = Int(roundedTimeby10)

      let roundedTimeLeft = round(countdownTimeLeft)
      let roundedTimeAsInt = Int(roundedTimeLeft)
      let roundedTimeAsIntby10 = roundedTimeAsInt * 10

      if roundedTimeAsIntby10 == roundedTimeby10asInt {
        if roundedTimeby10asInt > 0 {
          audio.playSound(filename: "Heatmapper_second_beep", fileExtension: "aif")
        } else {

          audio.playSound(filename: "FIT_minute_beep", fileExtension: "aif")

        }
      }

    } else {
      let beginPhraseLocalized = NSLocalizedString("Begin activity", comment: "")
      audio.speak(phrase: beginPhraseLocalized)
      countdownTimerLabel.setText("00:00")
      countdownTimer.invalidate()

      Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(startWorkout), userInfo: nil, repeats: false)

    }
  }

  @objc func startWorkout() {

    var screenArray   = [String]()
    var contextArray  = [Any]()

    if activityType == .auto {
      screenArray = ["ActionsInterfaceController", "WorkoutInterfaceController", "IntervalsTableController"]
      contextArray = ["", activityType, ""]
    } else {
      screenArray = ["ActionsInterfaceController", "WorkoutInterfaceController"]
      contextArray = ["", activityType]
    }
    // set up page-based navigation for main 3 screens but with initial focus on middle
    WKInterfaceController.reloadRootPageControllers(withNames:
                                                      screenArray,
                                                    contexts: contextArray,
                                                    orientation: WKPageOrientation.horizontal,
                                                    pageIndex: 1)

  }

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
