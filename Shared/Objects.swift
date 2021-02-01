//
//  Objects.swift
//  FIT WatchKit Extension
//
//  Created by Richard English on 10/11/2020.
//  Copyright © 2020 Richard English. All rights reserved.
//

import Foundation

enum ActivityType: String, Codable {
  case auto         = "Auto Detect"
  case `repeat`     = "Flat Sets"
  case pyramid      = "Pyramid Sets"
  case random       = "Random"
  case tabata       = "Tabata"
  case custom       = "Custom"
  case none         = "None"
}

extension ActivityType {
  init() {
    self = .none
  }
}

enum IntervalType: String, Codable {
  case walk         = "Walking"
  case run          = "Running"
  case stationary   = "Stationary"
  case warmup       = "Warm up"
  case cooldown     = "Cool down"
  case work         = "Work"
  case rest         = "Rest"
  case none         = "None"
}

extension IntervalType {
  init() {
    self = .none
  }
}

enum ActivityLevel: String, Codable, CaseIterable {
  case light       = "Light"
  case moderate    = "Moderate"
  case hard        = "Hard"
  case harder      = "Harder"
  case hardest     = "Hardest"

  var localizedDescription : String {
    get {
      switch(self) {
      case .light:
        return LocalizableStrings.light
      case .moderate:
        return LocalizableStrings.moderate
      case .hard:
        return LocalizableStrings.hard
      case .harder:
        return LocalizableStrings.harder
      case .hardest:
        return LocalizableStrings.hardest
      }
    }
  }


}

struct LocalizableStrings {
  // ActivityLevel enum cases for localization
  static let light  = NSLocalizedString("Light", comment: "")
  static let moderate  = NSLocalizedString("Moderate", comment: "")
  static let hard  = NSLocalizedString("Hard", comment: "")
  static let harder  = NSLocalizedString("Harder", comment: "")
  static let hardest  = NSLocalizedString("Hardest", comment: "")

  // ActivityPattern enum cases for localization
  static let flat  = NSLocalizedString("Flat", comment: "")
  static let pyramid  = NSLocalizedString("Pyramid", comment: "")

}

extension ActivityLevel {
  init() {
    self = .light
  }
}

enum ActivityPattern: String, Codable, CaseIterable {
  case flat        = "Flat"
  case pyramid     = "Pyramid"

  var localizedDescription : String {
    get {
      switch(self) {
      case .flat:
        return LocalizableStrings.flat
      case .pyramid:
        return LocalizableStrings.pyramid
      }
    }
  }
}

extension ActivityPattern {
  init() {
    self = .flat
  }
}

enum DisplayView: String, Codable, CaseIterable {
  case settings    = "Settings"
  case routine     = "Routine"
}

extension DisplayView {
  init() {
    self = .settings
  }
}

struct ActivityTemplate: Codable {
  var activityType: ActivityType
  var warmup: IntervalTemplate
  var work: IntervalTemplate
  var rest: IntervalTemplate
  var sets: Int
  var cooldown: IntervalTemplate
  var intervals       = [IntervalTemplate]()
  var activityLevel: ActivityLevel?
  var activityPattern: ActivityPattern?
  var customIntervals: Bool = false

  enum CodingKeys: String, CodingKey {
    case activityType = "ActivityType"
    case warmup = "Warm up"
    case work = "Work"
    case rest = "Rest"
    case sets = "sets"
    case cooldown = "Cool down"
    case intervals = "Intervals"
    case activityLevel = "Level"
    case activityPattern = "Pattern"
    case customIntervals = "Custom Intervals"
  }

  init () {
    self.activityType = .none

    let warmup    = IntervalTemplate(activityType: .warmup, duration: 300)
    let work      = IntervalTemplate(activityType: .work, duration: 60)
    let rest      = IntervalTemplate(activityType: .rest, duration: 30)
    let cooldown  = IntervalTemplate(activityType: .cooldown, duration: 120)
    let setsInt: Int = 3

    self.warmup   = warmup
    self.work     = work
    self.rest     = rest
    self.cooldown = cooldown
    self.sets     = setsInt
    self.intervals = [IntervalTemplate]()
    self.activityPattern = .flat
    self.activityLevel = .none
    self.customIntervals = false
  }

}

extension ActivityTemplate {
  var dictionaryRepresentation: [String: Any] {
    let data = try! JSONEncoder().encode(self)
    return try! JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
  }
}

// Converting back to struct
extension ActivityTemplate {
  init?(dictionary: [String: Any]) {
    guard let data = try? JSONSerialization.data(withJSONObject: dictionary, options: []) else { return nil }
    guard let info = try? JSONDecoder().decode(ActivityTemplate.self, from: data) else { return nil }
    self = info
  }
}

struct IntervalTemplate: Codable {
  var intervalType: IntervalType
  var duration: TimeInterval = 0.0

  init(activityType: IntervalType, duration: TimeInterval) {
    self.intervalType = activityType
    self.duration = duration
  }
}

enum TimeFormat: String, Codable {
  case minutes
  case seconds
  case both

}

extension TimeFormat {
  init() {
    self = .both
  }
}

enum UnitType: String {
  case length
  case distance
}
