//
//  MyFunc.swift
//  Heatmapper
//
//  Created by Richard English on 09/09/2020.
//  Copyright © 2020 Richard English. All rights reserved.
//
//  This class contains custom functions shared across iOS and watchOS platforms
//

import UIKit

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

  static func getTesterData() -> [String] {

    var metadataToReturn = [String]()
    let defaults = UserDefaults.standard

    if let savedTemplate = defaults.object(forKey: "Tester Metadata") as? Data {
      let decoder = JSONDecoder()
      if let loadedTemplate = try? decoder.decode([String].self, from: savedTemplate) {
        metadataToReturn = loadedTemplate
      }
    }
    return metadataToReturn

  }

  static func saveTesterData(_ testerDataArray: [String]) {
    let defaults = UserDefaults.standard
    let encoder = JSONEncoder()
    do {

      let encoded = try encoder.encode(testerDataArray)
      defaults.set(encoded, forKey: "Tester Metadata")
    } catch {
      logMessage(.error, "Error in MyFunc.saveTesterData")
    }

  }


  static func getPlayingArea(workoutId: UUID, successClosure: @escaping (Result<PlayingArea,dataRetrievalError>) -> Void) {

//  static func getPlayingArea(workoutId: UUID) -> PlayingArea {
   let defaults = UserDefaults.standard

    let workoutIdStr = String(describing: workoutId)
    let keyStr : String = "Playing Area: " + workoutIdStr
    if let savedTemplate = defaults.object(forKey: keyStr) as? Data {
      let decoder = JSONDecoder()
      if let loadedTemplate = try? decoder.decode(PlayingArea.self, from: savedTemplate) {
        let playingAreaToReturn = loadedTemplate
        successClosure(.success(playingAreaToReturn))
      }
    } else {
      successClosure(.failure(.dataError))
    }

  }


  static func deletePlayingAreas() {
    let defaults = UserDefaults.standard
    let allUserDefaults = defaults.dictionaryRepresentation()

    allUserDefaults.forEach{
      let defaultName = $0.key
      let prefixStr = defaultName.prefix(7)
      if prefixStr == "Playing" {
      defaults.removeObject(forKey: defaultName)
      MyFunc.logMessage(.debug, "Playing area \(defaultName) deleted")
      }
      }

  }


  static func savePlayingArea(_ playingArea: PlayingArea) {
    let defaults = UserDefaults.standard
    let encoder = JSONEncoder()

    let workoutIdStr = String(describing: playingArea.workoutID)
    let keyStr : String = "Playing Area: " + workoutIdStr
    do {
      let encoded = try encoder.encode(playingArea)
      defaults.set(encoded, forKey: keyStr)
      let playingAreaStr = String(describing: playingArea)
      logMessage(.debug, "Playing Area saved:")
      logMessage(.debug, playingAreaStr)
    } catch {
      logMessage(.error, "Error in MyFunc.savePlayingArea")
    }

  }


  static func getWorkoutMetadata() -> [WorkoutMetadata] {

    var metadataToReturn = [WorkoutMetadata]()
    let defaults = UserDefaults.standard

    if let savedTemplate = defaults.object(forKey: "Workout Metadata") as? Data {
      let decoder = JSONDecoder()
      if let loadedTemplate = try? decoder.decode([WorkoutMetadata].self, from: savedTemplate) {
        metadataToReturn = loadedTemplate
      }
    }
    return metadataToReturn

  }

  static func saveWorkoutMetadata(_ workoutMetadataArray: [WorkoutMetadata]) {
    let defaults = UserDefaults.standard
    let encoder = JSONEncoder()
    do {

      let encoded = try encoder.encode(workoutMetadataArray)
      defaults.set(encoded, forKey: "Workout Metadata")
    } catch {
      logMessage(.error, "Error in MyFunc.saveWorkoutMetadata")
    }

  }

  static func getHeatmapperActivityDefaults() -> [Activity] {

    var activitySetToReturn = [Activity]()
    let defaults = UserDefaults.standard

    if let savedTemplate = defaults.object(forKey: "Heatmapper Activity") as? Data {
      let decoder = JSONDecoder()
      if let loadedTemplate = try? decoder.decode([Activity].self, from: savedTemplate) {
        activitySetToReturn = loadedTemplate
      }
    }
    return activitySetToReturn

  }

  static func saveHeatmapActivityDefaults(_ activityArray: [Activity]) {
    let defaults = UserDefaults.standard
    let encoder = JSONEncoder()
    do {
      let encoded = try encoder.encode(activityArray)
      defaults.set(encoded, forKey: "Heatmapper Activity")
    } catch {
      logMessage(.error, "Error in MyFunc.saveHeatmapActivityDefaults")
    }

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

  // Function to verify file exists at location.
  static func checkFileExists(filename: String) -> Bool {

    let documentDirectory = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
    let checkingURL = documentDirectory.appendingPathComponent(filename)
    let checkingString = checkingURL.path
    let fileExists = FileManager.default.fileExists(atPath: checkingString)
    return fileExists

  }

  static func angle(between starting: CGPoint, ending: CGPoint) -> CGFloat {
    let center = CGPoint(x: ending.x - starting.x, y: ending.y - starting.y)
    let radians = atan2(center.y, center.x)
    let degrees = radians * 180 / .pi
    return degrees > 0 ? degrees : degrees + degrees
  }

  static func distanceBetween (point1: CGPoint, point2: CGPoint) -> CGFloat
  {
    // effectively this uses Pythagorean calculation to get the hypotenuse distance
    let distance = hypotf(Float((point1.x - point2.x)), Float((point1.y - point2.y)))
    return CGFloat(distance)
  }

}
