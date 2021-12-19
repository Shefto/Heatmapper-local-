//
//  PlayingArea.swift
//  Heatmapper
//
//  Created by Richard English on 02/10/2021.
//  Copyright © 2021 Richard English. All rights reserved.
//

import UIKit
import CoreLocation

// this struct created to provide a Codable equivalent for CLLocationCoordinate2D
// see https://programmingwithswift.com/easily-conform-to-codable/
struct CodableCLLCoordinate2D: Codable {
  let latitude: Double
  let longitude: Double

  func locationCoordinate() -> CLLocationCoordinate2D {
    return CLLocationCoordinate2D(latitude: self.latitude,
                                  longitude: self.longitude)
  }
}


struct PlayingArea: Codable {
//  static func == (lhs: PlayingArea, rhs: PlayingArea) -> Bool {
//    return true
//  }

  var workoutID : UUID
  var bottomLeft  : CodableCLLCoordinate2D
  var bottomRight  : CodableCLLCoordinate2D
  var topLeft  : CodableCLLCoordinate2D
  var rotation : CGFloat

  enum CodingKeys: String, CodingKey {
    case workoutID = "WorkoutId"
    case bottomLeft = "BottomLeft"
    case bottomRight = "BottomRight"
    case topLeft = "TopLeft"
    case rotation = "Rotation"
  }

//  init() {
//    var coord = CodableCLLCoordinate2D(
//    self.workoutID    = UUID.init()
//    self.bottomLeft   = CodableCLLCoordinate2D
//    self.bottomRight  = CodableCLLCoordinate2D()
//    self.topLeft      = CodableCLLCoordinate2D()
//    self.rotation     = 0.0
//  }


  init (workoutID: UUID, bottomLeft: CodableCLLCoordinate2D, bottomRight: CodableCLLCoordinate2D, topLeft: CodableCLLCoordinate2D, rotation: CGFloat) {
    self.workoutID  = workoutID
    self.bottomLeft = bottomLeft
    self.bottomRight = bottomRight
    self.topLeft = topLeft
    self.rotation = rotation

  }

}

// extension to encode
extension PlayingArea {
  var dictionaryRepresentation: [String: Any] {
    let data = try! JSONEncoder().encode(self)
    return try! JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
  }
}


// extension to decode back to Struct
extension PlayingArea {
  init?(dictionary: [String: Any]) {
    guard let data = try? JSONSerialization.data(withJSONObject: dictionary, options: []) else { return nil }
    guard let info = try? JSONDecoder().decode(PlayingArea.self, from: data) else { return nil }
    self = info
  }
}

