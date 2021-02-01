//
//  Stopwatch.swift
//  FIT
//
//  Created by Richard English on 04/07/2020.
//  Copyright © 2020 Richard English. All rights reserved.
//
//  This class manages the stopwatch timer for the intervals
//

import Foundation

class Stopwatch {

  private var startTime: Date?

  var elapsedTime: TimeInterval {
    if let startTime = self.startTime {
      return -startTime.timeIntervalSinceNow
    } else {
      return 0
    }
  }

  var elapsedTimeAsString: String {
    return String(format: "%02d:%02d.%d",
                  Int(elapsedTime / 60), Int(elapsedTime.truncatingRemainder(dividingBy: 60)), Int((elapsedTime * 10).truncatingRemainder(dividingBy: 10)))

  }

  var isRunning: Bool {
    return startTime != nil
  }

  func start() {
    startTime = Date()
  }

  func stop() {
    startTime = nil
  }

  func startFromDate(date: Date) {
    startTime = date
  }

}
