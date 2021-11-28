//
//  Objects.swift
//  Heatmapper WatchKit Extension
//
//  Created by Richard English on 10/11/2020.
//  Copyright © 2020 Richard English. All rights reserved.
//

import Foundation
import MapKit

enum BlendMode: String, Codable, CaseIterable {
  case normal       = "normal"
  case multiply     = "multiply"
  case screen       = "screen"
  case overlay      = "overlay"
  case darken       = "darken"
  case lighten      = "lighten"
  case colorDodge   = "colorDodge"
  case colorBurn    = "colorBurn"
  case softLight    = "softLight"
  case hardLight    = "hardLight"
  case difference   = "difference"
  case exclusion    = "exclusion"
  case hue          = "hue"
  case saturation   = "saturation"
  case color        = "color"
  case luminosity   = "luminosity"
  case clear        = "clear"
  case copy         = "copy"
  case sourceIn     = "sourceIn"
  case sourceOut    = "sourceOut"
  case sourceAtop   = "sourceAtop"
  case destinationOver    = "destinationOver"
  case destinationIn      = "destinationIn"
  case destinationOut     = "destinationOut"
  case destinationAtop    = "destinationAtop"
  case xor                = "xor"
  case plusDarker         = "plusDarker"
  case plusLighter        = "plusLighter"

}

extension BlendMode {
  init() {
    self = .normal
  }
}


enum Sport: String, Codable, CaseIterable {
  case football    = "Football"
  case rugby       = "Rugby"
  case basketball  = "Basketball"
  case tennis      = "Tennis"
  case none        = "None"
}

extension Sport {
  init() {
    self = .none
  }
}


struct WorkoutMetadata: Codable {
  var workoutId = UUID()
  var activity  : String?
  var sport     : String?
  var venue     : String?
  var pitch     : String?
  var pitchArea : MKMapRect?

  enum CodingKeys: String, CodingKey {
    case workoutId  = "WorkoutId"
    case activity   = "Activity"
    case sport      = "Sport"
    case venue      = "Venue"
    case pitch      = "Pitch"
  }
//
//  init (workoutId: UUID, activity: String? = nil, sport: String? = nil, venue: String? = nil, pitch: String? = nil) {
//    self.workoutId  = workoutId
//    self.activity   = activity
//    self.sport      = sport
//    self.venue      = venue
//    self.pitch      = pitch
//  }

}


struct Team: Codable, Equatable {
  var name  : String
  var sport : Sport

  enum CodingKeys: String, CodingKey {
    case name = "Name"
    case sport = "Sport"
  }

  init (name: String, sport: Sport) {
    self.name = name
    self.sport = sport
  }

}

// extension to encode
extension Team {
  var dictionaryRepresentation: [String: Any] {
    let data = try! JSONEncoder().encode(self)
    return try! JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
  }
}

// extension to decode back to Struct
extension Team {
  init?(dictionary: [String: Any]) {
    guard let data = try? JSONSerialization.data(withJSONObject: dictionary, options: []) else { return nil }
    guard let info = try? JSONDecoder().decode(Team.self, from: data) else { return nil }
    self = info
  }
}



struct Activity: Codable, Equatable {
  var name  : String
  var sport : Sport

  enum CodingKeys: String, CodingKey {
    case name = "Name"
    case sport = "Sport"
  }

  init (name: String, sport: Sport) {
    self.name = name
    self.sport = sport
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


//MARK: Heatmap objects

struct REHeatmapPoint {
  var mapPoint  : MKMapPoint
  var radius    : CGFloat
  var heatLevel : Double = 0.0

  init(mapPoint: MKMapPoint, radius:  CGFloat, heatLevel: Double) {
    self.mapPoint   = mapPoint
    self.radius     = radius
    self.heatLevel  = heatLevel
  }
}
