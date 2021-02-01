//
//  Extensions.swift
//  FIT WatchKit Extension
//
//  Created by Richard English on 10/08/2020.
//  Copyright © 2020 Richard English. All rights reserved.
//

import Foundation

extension TimeInterval {

  func minuteOfHour() -> Int {
    guard self > 0 && self < Double.infinity else {
      return 0
    }

    // using rounded function as simply truncatingRemainder does not cater for rounding
    let roundedTimeInterval = self.rounded(digits: 1)

    let minutes = (Int(roundedTimeInterval) / 60) % 60
    return minutes

  }

  func secondsOfMinute() -> Int {
    guard self > 0 && self < Double.infinity else {
      return 0
    }

    // using rounded function as simply truncatingRemainder does not cater for rounding
    let roundedTimeInterval = self.rounded(digits: 1)

    let seconds = Int(roundedTimeInterval) % 60
    return seconds
  }

  func toMinutesAndSeconds() -> String {

    guard self >= 0 && self < Double.infinity else {
      return "unknown"
    }

    // using rounded function as simply truncatingRemainder does not cater for rounding
    let roundedTimeInterval = self.rounded(digits: 1)

    // Seconds
    let seconds = Int(roundedTimeInterval) % 60
    // Minutes
    let minutes = (Int(roundedTimeInterval) / 60) % 60
    // Hours
    let hours = (Int(roundedTimeInterval) / 3600)

    if hours != 0 {
      return String(format: "%0.2d:%0.2d", minutes, seconds)
    }
    if minutes != 0 {
      return String(format: "%2d:%0.2d", minutes, seconds)
    }

    return String(format: "%1d:%0.2d", minutes, seconds)

  }

  func toReadableString() -> String {

    guard self > 0 && self < Double.infinity else {
      return "unknown"
    }

    // using rounded function as simply truncatingRemainder does not cater for rounding
    let roundedTimeInterval = self.rounded(digits: 1)

    // Deciseconds
    let deciseconds = Int((roundedTimeInterval.truncatingRemainder(dividingBy: 1)) * 10)

    // Seconds
    let seconds = Int(roundedTimeInterval) % 60
    // Minutes
    let minutes = (Int(roundedTimeInterval) / 60) % 60
    // Hours
    let hours = (Int(roundedTimeInterval) / 3600)

    if hours != 0 {
      return String(format: "%2d:%0.2d %0.2d", hours, minutes, seconds)
    }
    if minutes != 0 {
      return String(format: "%2d:%0.2d", minutes, seconds)
    }

    return String(format: "%2d.%0.1d", seconds, deciseconds)

  }

  var time: String {
    return String(format: "%02d:%02d", Int(self/60), Int(ceil(truncatingRemainder(dividingBy: 60))) )
  }

}

// extension for rounding Doubles to decimal places
extension Double {
  func rounded(digits: Int) -> Double {
    let multiplier = pow(10.0, Double(digits))
    return (self * multiplier).rounded() / multiplier
  }
}

extension UnitSpeed {
  class var secondsPerMeter: UnitSpeed {
    return UnitSpeed(symbol: "sec/m", converter: UnitConverterPace(coefficient: 1))
  }

  class var minutesPerKilometer: UnitSpeed {
    return UnitSpeed(symbol: "min/km", converter: UnitConverterPace(coefficient: 60.0 / 1000.0))
  }

  class var minutesPerMile: UnitSpeed {
    return UnitSpeed(symbol: "min/mi", converter: UnitConverterPace(coefficient: 60.0 / 1609.34))
  }
}


