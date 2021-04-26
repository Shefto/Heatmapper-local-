//
//  CountdownInterfaceController.swift
//  Heatmapper WatchKit Extension
//
//  Created by Richard English on 17/11/2020.
//  Copyright © 2020 Richard English. All rights reserved.
//

import WatchKit
import Foundation
import os

class CountdownInterfaceController: WKInterfaceController {

  let logger = Logger(subsystem: "wimbledonappcompany.com.Heatmapper.watchkitapp.watchkitextension", category: "CountdownInterfaceController")
  var countdownTimeLeft: TimeInterval = 3.1
  var countdownEndTime: Date?
  var countdownTimer = Timer()
//  let audio = Audio()

  var activityTemplate    = ActivityTemplate()
  var activityType        = ActivityType()
  var intervalType        = IntervalType()

  @IBOutlet weak var countdownTimerLabel: WKInterfaceLabel!

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)

//
//      guard let contextReceived = context as? String
//      else {
//        MyFunc.logMessage(.error, "Invalid context received by CountdownInterfaceController : \(String(describing: context))")
//        return
//      }
//
//      let activityTypeFromContext = MyFunc.getContext(contextReceived).activityType
//      let intervalTypeFromContext = MyFunc.getContext(contextReceived).intervalType
//      activityType = activityTypeFromContext
//      intervalType = intervalTypeFromContext

    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        displayCountdownTimer()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
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
//          audio.playSound(filename: "FiT_second_beep", fileExtension: "aif")
        } else {

//          audio.playSound(filename: "FIT_minute_beep", fileExtension: "aif")

        }
      }

    } else {
//      let beginPhraseLocalized = NSLocalizedString("Begin activity", comment: "")
//      audio.speak(phrase: beginPhraseLocalized)
      countdownTimerLabel.setText("00:00")
      countdownTimer.invalidate()

      Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(startWorkout), userInfo: nil, repeats: false)

    }
  }

  @objc func startWorkout() {

    var screenArray   = [String]()
    var contextArray  = [Any]()


      screenArray = ["ActionsInterfaceController", "WorkoutInterfaceController"]
      contextArray = ["", activityType]

    // set up page-based navigation for 2 screens but with initial focus on second
    WKInterfaceController.reloadRootPageControllers(withNames:
                                                    screenArray,
                                                    contexts: contextArray,
                                                    orientation: WKPageOrientation.horizontal,
                                                    pageIndex: 1)
  }

}
