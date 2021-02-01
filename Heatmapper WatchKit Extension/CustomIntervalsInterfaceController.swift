//
//  CustomIntervalsInterfaceController.swift
//  FIT WatchKit Extension
//
//  Created by Richard English on 20/11/2020.
//  Copyright © 2020 Richard English. All rights reserved.
//

import WatchKit
import Foundation

class CustomIntervalsInterfaceController: WKInterfaceController {

  var activityTemplate    = ActivityTemplate()
  var activityType        = ActivityType()
  var intervalType        = IntervalType()

  @IBOutlet weak var customTable: WKInterfaceTable!

  @IBAction func tableLongPress(_ sender: Any) {
    displayAlert(title: "Custom Sets", message: "Use the iPhone app to change Custom Sets. Changes will be automatically synced to your Apple Watch")
  }

  @IBAction func btnStart() {
      presentController(withName: "Countdown Interface Controller", context: MyFunc.setContext(activityType, intervalType))
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
    super.willActivate()
    activityTemplate = MyFunc.getActivityDefaults(activityType)
    loadUI()
  }

  func loadUI() {

    loadTable()
  }

  func loadTable() {

    let intervalsCount = activityTemplate.intervals.count

    customTable.setNumberOfRows(intervalsCount, withRowType: "CustomRowController")

    for intervalsCount in 0..<intervalsCount {
      let row = customTable.rowController(at: intervalsCount)
        as! CustomRowController

      let currInterval = activityTemplate.intervals[intervalsCount]

      row.intervalTypeLabel.setText(currInterval.intervalType.rawValue)
      let durationText = currInterval.duration.toMinutesAndSeconds()
      row.durationLabel.setText(durationText)

    }

  }

  func displayAlert (title: String, message: String) {

    //Alert user that Save has worked
    let okAction = WKAlertAction(title: "OK", style: WKAlertActionStyle.default, handler: {})

    WKExtension.shared().visibleInterfaceController?.presentAlert(withTitle: title, message: message, preferredStyle: WKAlertControllerStyle.alert, actions: [okAction])

  }

}
