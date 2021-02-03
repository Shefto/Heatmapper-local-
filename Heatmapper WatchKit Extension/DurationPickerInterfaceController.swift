//
//  DurationPickerInterfaceController.swift
//  Heatmapper WatchKit Extension
//
//  Created by Richard English on 10/11/2020.
//  Copyright © 2020 Richard English. All rights reserved.
//

import WatchKit
import Foundation

class DurationPickerInterfaceController: WKInterfaceController, SessionCommands {

  var minuteItems: [WKPickerItem] = []
  var secondItems: [WKPickerItem] = []
  var minute: Int = 0
  var second: Int = 0
  var durationText: String = ""
  var minuteStr: String = ""
  var secondStr: String = ""

  var activityType      = ActivityType()
  var intervalType      = IntervalType()
  var intervalTemplate  = IntervalTemplate(activityType: .none, duration: 0)
  var activityTemplate  = ActivityTemplate()

  let defaults          = UserDefaults.standard

  var pickersLoaded: Bool = false

  @IBOutlet weak var durationLabel: WKInterfaceLabel!
  @IBOutlet weak var minutePicker: WKInterfacePicker!
  @IBOutlet weak var secondPicker: WKInterfacePicker!

  @IBAction func minuteChanged(_ value: Int) {
    if pickersLoaded == true {

      minuteStr = minuteItems[value].title ?? ""

      // set seconds to 00 if maximum minutes selected
      if (value+1) == minuteItems.count {
        secondPicker.setSelectedItemIndex(0)
      }

      performUpdates()
    }
  }

  @IBAction func secondChanged(_ value: Int) {
    if pickersLoaded == true {
      secondStr = secondItems[value].title ?? ""
      performUpdates()
    }
  }

  override func awake(withContext context: Any?) {
    super.awake(withContext: context)

    guard let contextReceived = context as? String
    else {
      MyFunc.logMessage(.default, "Invalid context received by DurationPickerInterfaceController : \(String(describing: context))")
      return
    }

    let activityTypeFromContext = MyFunc.getContext(contextReceived).activityType
    let intervalTypeFromContext = MyFunc.getContext(contextReceived).intervalType
    activityType = activityTypeFromContext
    intervalType = intervalTypeFromContext

    // get the Activity Template data for the received Activity Type
    activityTemplate = MyFunc.getActivityDefaults(activityType)

    // get the Interval Template data for the received Interval Type in the Activity Template
    intervalTemplate = getIntervalTemplateForType(activityTemplate, intervalType)
    if activityType == .random && intervalType == .work {
      setTitle("Activity")
    } else {
    setTitle(intervalTemplate.intervalType.rawValue)
    }
    let durationReceived: TimeInterval = intervalTemplate.duration
    let minutes = durationReceived.minuteOfHour()
    let seconds = durationReceived.secondsOfMinute()

    // set up UI objects
    loadPickers()
    minutePicker.setItems(minuteItems)
    secondPicker.setItems(secondItems)

    minuteStr = String(describing: minutes)
    let minutesIndex: Int = minuteItems.firstIndex(where: { $0.title == minuteStr }) ?? 0
    minutePicker.setSelectedItemIndex(minutesIndex)

    secondStr = String(describing: seconds)
    let secondsIndex: Int = secondItems.firstIndex(where: { $0.title == secondStr }) ?? 0
    secondPicker.setSelectedItemIndex(secondsIndex)

    pickersLoaded = true

  }

  override func willActivate() {
    // This method is called when watch view controller is about to be visible to user
    super.willActivate()
  }

  override func didDeactivate() {
    // This method is called when watch view controller is no longer visible
    super.didDeactivate()
    performUpdates()

  }

  func loadPickers() {
    loadMinuteItems()
    loadSecondItems()
  }

  func loadMinuteItems() {
    for minute in 0...5 {

      let item = WKPickerItem()
      let itemStr = String(minute)
      item.title = itemStr
      item.caption = itemStr + " min"
      minuteItems.append(item)
    }
  }

  func loadSecondItems() {
    for second in stride(from: 0, through: 55, by: 5) {
      let item = WKPickerItem()

      var itemStr = String(second)

      if itemStr == "0" {
        itemStr = "00"
      }

      if itemStr == "5" {
        itemStr = "05"
      }
      item.title = itemStr
      item.caption = itemStr + " sec"
      secondItems.append(item)
    }
  }

  func performUpdates() {
    updateDuration()
    let updatedActivityTemplate = setIntervalTemplateForType(intervalTemplate, activityTemplate)
    MyFunc.saveActivityDefaults(updatedActivityTemplate)
    self.activityTemplate = updatedActivityTemplate
//    DispatchQueue.main.async {
      self.updateApplicationContextForActivityTemplate(activityTemplate: self.activityTemplate)
//    }

  }

  func updateDuration() {

    minute = Int(minuteStr) ?? 0
    second  = Int(secondStr) ?? 0

    let durationInt = (minute*60) + second
    let durationDouble = Double(durationInt)
    intervalTemplate.duration = durationDouble

  }

  func getIntervalTemplateForType(_ activityTemplate: ActivityTemplate, _ intervalType: IntervalType) -> IntervalTemplate {
    var intervalTemplateToReturn = IntervalTemplate(activityType: .none, duration: 0)
    switch intervalType {
    case .warmup:
      intervalTemplateToReturn = activityTemplate.warmup
    case .rest:
      intervalTemplateToReturn = activityTemplate.rest
    case .work:
      intervalTemplateToReturn = activityTemplate.work
    case .cooldown:
      intervalTemplateToReturn = activityTemplate.cooldown
    default:
      MyFunc.logMessage(.error, "Unknown Interval Type \(intervalType) for ActivityTemplate \(activityTemplate)")
    }
    return intervalTemplateToReturn
  }

  func setIntervalTemplateForType(_ intervalTemplate: IntervalTemplate, _ activityTemplate: ActivityTemplate) -> ActivityTemplate {

    var activityTemplateToReturn = activityTemplate
    switch intervalTemplate.intervalType {
    case .warmup:
      activityTemplateToReturn.warmup.duration = intervalTemplate.duration
    case .rest:
      activityTemplateToReturn.rest.duration = intervalTemplate.duration
    case .work:
      activityTemplateToReturn.work.duration = intervalTemplate.duration
    case .cooldown:
      activityTemplateToReturn.cooldown.duration = intervalTemplate.duration
    default:
      MyFunc.logMessage(.error, "Unknown intervalTemplate \(intervalTemplate) for intervalTemplate \(activityTemplate)")
    }
    return activityTemplateToReturn
  }

}
