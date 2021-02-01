//
//  Fartlek.swift
//  FIT WatchKit Extension
//
//  Created by Richard English on 08/10/2020.
//  Copyright © 2020 Richard English. All rights reserved.
//

import Foundation
import HealthKit

class FartlekWorkout {

  static var intervalArray: [Interval] = {
    var array = [Interval]()
    return array
  }()

  static var sampleArray: [HKSample] = {
    var sampleArray = [HKSample]()
    return sampleArray
  }()

  static var totalDuration: Double {
    get {
      var totalIntervalTime           = [Double]()
      var durationTotal: Double = 0

      // to get the workout duration, get the full TimeInterval since the workout started
      totalIntervalTime =  FartlekWorkout.intervalArray.map({$0.duration!.duration})

      // sum the total
      durationTotal = totalIntervalTime.reduce(0, {$0 + $1})
      totalIntervalTime.removeAll()
      return durationTotal
    }

  }

  static var startDate: Date = {
    var startDate = Date()
    return startDate
  }()

  static var lastIntervalEndDate: Date =  {

    var intervalEndDate = Date()
    return intervalEndDate
  }()

}
