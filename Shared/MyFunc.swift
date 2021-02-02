//
//  MyFunc.swift
//  Heatmapper
//
//  Created by Richard English on 09/09/2020.
//  Copyright © 2020 Richard English. All rights reserved.
//
//  This class contains custom functions shared across iOS and watchOS platforms
//

import Foundation

enum LogLevel: String {
  case debug
  case info
  case `default`
  case error
  case fault
  case critical
}

class MyFunc {

  static var log: String = {
    var log = String()
    return log
  }()

  static func logMessage(_ level: LogLevel, _ message: String) {

    // this custom function added to ensure all watchOS logging stored as oslog not working
    let logDateFormatter      = DateFormatter()
    logDateFormatter.dateFormat = "HH:mm:ss"
    let currDate = logDateFormatter.string(from: Date())
    let logStr = currDate + " : " + level.rawValue + " : " + message + "\n"
    self.log.append(logStr)

    // print only when debugging
    switch level {
    case .error, .critical, .fault, .debug:
      print(logStr)
    default: break

    }

  }

  static func getActivityDefaults(_ activityType: ActivityType) -> ActivityTemplate {

    var templateToReturn = ActivityTemplate()
    let defaults = UserDefaults.standard

    if let savedTemplate = defaults.object(forKey: activityType.rawValue) as? Data {
      let decoder = JSONDecoder()
      if let loadedTemplate = try? decoder.decode(ActivityTemplate.self, from: savedTemplate) {
        templateToReturn = loadedTemplate
      }

    } else {

      // no saved Repeat Set so default to initial values and save these
      switch activityType {
      case .tabata:
        templateToReturn.activityType = .tabata
        templateToReturn.warmup   = IntervalTemplate(activityType: .warmup, duration: 300)
        templateToReturn.work     = IntervalTemplate(activityType: .work, duration: 20)
        templateToReturn.rest     = IntervalTemplate(activityType: .rest, duration: 10)
        templateToReturn.sets     = 8
        templateToReturn.cooldown = IntervalTemplate(activityType: .cooldown, duration: 120)
      case .random:
        templateToReturn.activityType = .random
        templateToReturn.warmup   = IntervalTemplate(activityType: .warmup, duration: 120)
        templateToReturn.work     = IntervalTemplate(activityType: .work, duration: 300)
        templateToReturn.activityLevel = .moderate
        templateToReturn.cooldown = IntervalTemplate(activityType: .cooldown, duration: 120)

      case .repeat:
        templateToReturn.activityType = .repeat
        templateToReturn.warmup   = IntervalTemplate(activityType: .warmup, duration: 180)
        templateToReturn.work     = IntervalTemplate(activityType: .work, duration: 60)
        templateToReturn.rest     = IntervalTemplate(activityType: .rest, duration: 30)
        templateToReturn.sets     = 4
        templateToReturn.cooldown = IntervalTemplate(activityType: .cooldown, duration: 180)

      case .pyramid:
        templateToReturn.activityType = .pyramid
        templateToReturn.warmup   = IntervalTemplate(activityType: .warmup, duration: 180)
        templateToReturn.work     = IntervalTemplate(activityType: .work, duration: 60)
        templateToReturn.rest     = IntervalTemplate(activityType: .rest, duration: 30)
        templateToReturn.sets     = 5
        templateToReturn.cooldown = IntervalTemplate(activityType: .cooldown, duration: 180)

      case .custom:
        templateToReturn.activityType = .custom
        templateToReturn.warmup   = IntervalTemplate(activityType: .warmup, duration: 60)
        templateToReturn.work     = IntervalTemplate(activityType: .work, duration: 60)
        templateToReturn.rest     = IntervalTemplate(activityType: .rest, duration: 30)
        templateToReturn.sets     = 4
        templateToReturn.cooldown = IntervalTemplate(activityType: .cooldown, duration: 60)

        let warmupSet = IntervalTemplate(activityType: .warmup, duration: 60)
        let workSet = IntervalTemplate(activityType: .work, duration: 60)
        let restSet = IntervalTemplate(activityType: .rest, duration: 30)
        let cooldownSet = IntervalTemplate(activityType: .cooldown, duration: 60)
        templateToReturn.intervals.append(warmupSet)
        for _ in 1...3 {
          templateToReturn.intervals.append(workSet)
          templateToReturn.intervals.append(restSet)
        }
        templateToReturn.intervals.append(cooldownSet)

      default:
        logMessage(.error, "No default values available for activityType: \(activityType)")
      }

      saveActivityDefaults(templateToReturn)

    }
    return templateToReturn
  }

  static func saveActivityDefaults(_ activityTemplate: ActivityTemplate) {
    let defaults = UserDefaults.standard
    let encoder = JSONEncoder()
    do {
      let encoded = try encoder.encode(activityTemplate)
      defaults.set(encoded, forKey: activityTemplate.activityType.rawValue)
    } catch {

      logMessage(.error, "Error in MyFunc.saveActivityDefaults")
    }

  }

  static func setContext(_ activityType: ActivityType, _ intervalType: IntervalType) -> String {
    return activityType.rawValue + "~" + intervalType.rawValue

  }

  static func getContext(_ context: String) -> (activityType: ActivityType, intervalType: IntervalType) {

    let contextDelimiter = context.firstIndex(of: "~") ?? context.endIndex
    let activityValue = context[..<contextDelimiter]
    let contextDelimiterOffset = context.index(contextDelimiter, offsetBy: 1)

    let intervalValue = context[contextDelimiterOffset...]
    let activityType = ActivityType(rawValue: String(activityValue)) ?? ActivityType.none
    let intervalType = IntervalType(rawValue: String(intervalValue)) ?? IntervalType.none
    let activityTypeToReturn: ActivityType = activityType
    let intervalTypeToReturn: IntervalType = intervalType

    return (activityTypeToReturn, intervalTypeToReturn)

  }

  static func createRepeatIntervalSet(_ activityTemplate: ActivityTemplate) -> [IntervalTemplate] {

    var arrayToReturn = [IntervalTemplate]()
    arrayToReturn.append(activityTemplate.warmup)
    for count in 1...activityTemplate.sets {
      arrayToReturn.append(activityTemplate.work)
      // if it's the last set don't add a rest interval
      if count < activityTemplate.sets {
        arrayToReturn.append(activityTemplate.rest)
      }
    }
    arrayToReturn.append(activityTemplate.cooldown)

    return arrayToReturn

  }

  static func createCustomIntervalSet(_ activityTemplate: ActivityTemplate) -> [IntervalTemplate] {

    var arrayToReturn = [IntervalTemplate]()
    arrayToReturn.append(activityTemplate.warmup)
    var previousWorkDuration = TimeInterval()
    var previousRestDuration = TimeInterval()

    for count in 1...activityTemplate.sets {
      var workDuration = TimeInterval()
      var restDuration = TimeInterval()

      switch activityTemplate.activityPattern {
      case .pyramid:
        if count == 1 || count == activityTemplate.sets {
          workDuration = activityTemplate.work.duration
          restDuration = activityTemplate.rest.duration
        } else {
          let workSetsFloat = Float(activityTemplate.sets)
          let restSetsFloat = workSetsFloat - 1

          let countMinusOne = Float(count) - 1
          let workSetsHalf = workSetsFloat / 2
          let restSetsHalf = restSetsFloat / 2

          // calculate Work Duration
          if countMinusOne < workSetsHalf {
            workDuration = previousWorkDuration / 2
          } else if countMinusOne == workSetsHalf {
            workDuration = previousWorkDuration
          } else {
            workDuration = previousWorkDuration * 2
          }

          // calculate Rest Duration
          if countMinusOne < restSetsHalf {
            restDuration = previousRestDuration / 2
          } else if countMinusOne == restSetsHalf {
            restDuration = previousRestDuration
          } else {
            restDuration = previousRestDuration * 2
          }

        }
        previousWorkDuration = workDuration
        previousRestDuration = restDuration

      default:
        workDuration = activityTemplate.work.duration
        restDuration = activityTemplate.rest.duration

      }

      var intervalToAdd = IntervalTemplate(activityType: .work, duration: workDuration)
      let intervalToAddStr = String(describing: intervalToAdd)
      logMessage(.debug, intervalToAddStr)
      arrayToReturn.append(intervalToAdd)

      // if it's the last set don't add a rest interval
      if count < activityTemplate.sets {
        intervalToAdd = IntervalTemplate(activityType: .rest, duration: restDuration)
        arrayToReturn.append(intervalToAdd)
      }
    }

    arrayToReturn.append(activityTemplate.cooldown)

    return arrayToReturn

  }

  static func getTimeIntervalFromScale(scale: Float, stride: Float, sliderSize: Float) -> TimeInterval {
    let newValue = sliderSize * scale
    let newDuration = round(newValue / stride) * stride
    let durationTimeInterval = TimeInterval(newDuration)
    return durationTimeInterval
  }

  static func createRandomIntervalSet(_ activityTemplate: ActivityTemplate) -> [IntervalTemplate] {
    var arrayToReturn = [IntervalTemplate]()

    // first divide Activity duration by number of sets
    let workSets = activityTemplate.sets

    let restSets = workSets - 1
    let totalSets = workSets + restSets

    // first divide Activity duration by number of sets
    let setsDouble = Double(totalSets)
    let activitySetsDuration = activityTemplate.work.duration / setsDouble

    var splitsRatio: Double = 0.0
    // then calculate the work / rest split depending upon the difficulty level

    switch activityTemplate.activityLevel {
    case .light:
      splitsRatio = 0.6
    case .moderate:
      splitsRatio = 0.7
    case .hard:
      splitsRatio = 0.8
    case .harder:
      splitsRatio = 0.85
    case .hardest:
      splitsRatio = 0.9
    default:
      MyFunc.logMessage(.error, "Invalid activityLevel \(String(describing: activityTemplate.activityLevel)) received by createRandomIntervalSet")
    }

    // set the total duration for all work sets depending upon the ratio
    let workSetsDuration = activitySetsDuration * splitsRatio
    // the rest sets duration will be the remainder
    let restSetsDuration = activitySetsDuration - workSetsDuration

    // now set the average workSet duration for calculating random durations
    let workRangeCentre = workSetsDuration / Double(workSets)
    // next set a range in which to generate a random number
    let workRangeLower = workRangeCentre * 0.75
    let workRangeUpper = workRangeCentre * 1.25

    // next set the average restkSet duration for calculating random durations
    let restRangeCentre = restSetsDuration / Double(restSets)
    // next set a range in which to generate a random number
    let restRangeLower = restRangeCentre * 0.6
    let restRangeUpper = restRangeCentre * 1.4

    var workDurationSet = [Double](repeating: 0.0, count: workSets)
    var restDurationSet = [Double](repeating: 0.0, count: restSets)

    workDurationSet = workDurationSet.map({_ in Double.random(in: workRangeLower...workRangeUpper)})
    restDurationSet = restDurationSet.map({_ in Double.random(in: restRangeLower...restRangeUpper)})

    var workDurationSum = workDurationSet.reduce(0, {$0 + $1})
    var restDurationSum = restDurationSet.reduce(0, {$0 + $1})
    var totalDurationSum = workDurationSum + restDurationSum

    let varianceFromWorkSetting = totalDurationSum - activitySetsDuration

    var adjustmentMultiplier: Double = 1
    // set the multiplier by which all values will be adjusted
    if activitySetsDuration != 0 {
      adjustmentMultiplier = 1 + (varianceFromWorkSetting / activitySetsDuration)
    }
    workDurationSet = workDurationSet.map({$0 / adjustmentMultiplier * 5})
    restDurationSet = restDurationSet.map({$0 / adjustmentMultiplier * 5})
    workDurationSum = workDurationSet.reduce(0, {$0 + $1})
    restDurationSum = restDurationSet.reduce(0, {$0 + $1})
    totalDurationSum = workDurationSum + restDurationSum

    // round the durations to the nearest multiple of 5
    workDurationSet = workDurationSet.map({5 * (round($0 / 5.0))})
    restDurationSet = restDurationSet.map({5 * (round($0 / 5.0))})
    workDurationSum = workDurationSet.reduce(0, {$0 + $1})
    restDurationSum = restDurationSet.reduce(0, {$0 + $1})
    totalDurationSum = workDurationSum + restDurationSum
    // combine these into a single set

    let sets = workDurationSet.count
    for setCounter in 0..<sets {

      let workIntervalToAppend = IntervalTemplate(activityType: .work, duration: workDurationSet[setCounter])
      arrayToReturn.append(workIntervalToAppend)
      if setCounter < sets - 1 {
        let restIntervalToAppend = IntervalTemplate(activityType: .rest, duration: restDurationSet[setCounter])
        arrayToReturn.append(restIntervalToAppend)

      }
    }

    arrayToReturn.insert(activityTemplate.warmup, at: 0)
    arrayToReturn.append(activityTemplate.cooldown)

    return arrayToReturn

  }

  static func getDefaultsUnitLength() -> UnitLength {

    let defaults = UserDefaults.standard
    let unitLengthDefault = defaults.object(forKey: "Units") as? String ?? ""

    switch unitLengthDefault {
    case "km/h", "mins/km":
      return UnitLength.meters
    case "mph", "mins/mi":
      return UnitLength.yards
    default:
      let locale = Locale.current
      if locale.usesMetricSystem == true {
        return UnitLength.meters
      } else {
        return UnitLength.yards
      }
    }
  }

  static func getDefaultsUnitSpeed() -> UnitSpeed {

    let defaults = UserDefaults.standard
    let unitSpeedDefault = defaults.object(forKey: "Units") as? String ?? ""

    switch unitSpeedDefault {
    case "km/h":
      return UnitSpeed.kilometersPerHour
    case "mph":
      return UnitSpeed.milesPerHour
    case "mins/km":
      return UnitSpeed.minutesPerKilometer
    case "mins/mi":
      return UnitSpeed.minutesPerMile
    case "sec/m":
      return UnitSpeed.secondsPerMeter

    default:
      let locale = Locale.current
      if locale.usesMetricSystem == true {
        return UnitSpeed.kilometersPerHour
      } else {
        return UnitSpeed.milesPerHour
      }
    }
  }

  static func getUnitLengthAsString(value: Double, unitLength: UnitLength, formatter: MeasurementFormatter) -> String {

    // initial distance from CMPedometerData will be in meters
    let length = Measurement<UnitLength>(value: value, unit: UnitLength.meters)

    // convert distance as required
    let lengthString = formatter.string(from: length.converted(to: unitLength))

    // split the resulting string into the distance (i.e. length) and unit
    let lengthStringArray = lengthString.components(separatedBy: .whitespaces)
    let distance = lengthStringArray.first ?? ""
//    let unit = lengthStringArray.last ?? ""

    return distance
//    return (distance: lengthString, unit: unit)
  }

  static func getUnitSpeedAsString(value: Double, unitSpeed: UnitSpeed, formatter: MeasurementFormatter) -> String {

    MyFunc.logMessage(.debug, "Converting to unitSpeed: \(unitSpeed)")
    // initial pace from CMPedometerData is in seconds per meter
    // in order to convert this, first needs to be converted into meters per second
    var speedMPS: Double = 0.0
    if value > 0 {
       speedMPS = 1/value
    }

    let speed = Measurement<UnitSpeed>(value: speedMPS, unit: UnitSpeed.metersPerSecond)

    MyFunc.logMessage(.debug, "SpeedMPS: \(speedMPS)")
    // convert distance as required
    let speedString = formatter.string(from: speed.converted(to: unitSpeed))

    // split the resulting string into the distance (i.e. length) and unit
    let speedStringArray = speedString.components(separatedBy: .whitespaces)
    let speedStr = speedStringArray.first ?? ""
    let unitStr = speedStringArray.last ?? ""

    MyFunc.logMessage(.debug, "speedStr: \(speedStr)")
    MyFunc.logMessage(.debug, "unitStr: \(unitStr)")
    return speedStr
//    return (speed: speedString, unit: unitStr)
  }

  static func removeAdsPurchased() -> Bool {
    let productID = "wimbledonappcompany.com.Heatmapper.RemoveAds"
    let purchaseStatus = UserDefaults.standard.bool(forKey: productID)

    if purchaseStatus {
      MyFunc.logMessage(.debug, "Previously purchased")
      return true
    } else {
      MyFunc.logMessage(.debug, "Never purchased")
      return false
    }
  }

}
