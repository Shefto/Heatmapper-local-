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

  var workoutID   : UUID
  var id          : UUID
  var name        : String?
  var venueId     : UUID?
  var venueName   : String?
  var comments    : String?
  var sport       : String?
  var bottomLeft  : CodableCLLCoordinate2D
  var bottomRight : CodableCLLCoordinate2D
  var topLeft     : CodableCLLCoordinate2D
  var topRight    : CodableCLLCoordinate2D

  enum CodingKeys: String, CodingKey {
    case workoutID = "WorkoutId"
    case id = "Id"
    case name = "Name"
    case venueId = "VenueId"
    case venueName = "VenueName"
    case comments = "Comments"
    case sport = "Sport"
    case bottomLeft = "BottomLeft"
    case bottomRight = "BottomRight"
    case topLeft = "TopLeft"
    case topRight = "TopRight"

  }

  init (workoutID: UUID, bottomLeft: CodableCLLCoordinate2D, bottomRight: CodableCLLCoordinate2D, topLeft: CodableCLLCoordinate2D, topRight: CodableCLLCoordinate2D, name: String?, venueId: UUID?, sport: String?, comments: String?) {
    self.workoutID  = workoutID
    self.name = name
    self.id = UUID()
    self.venueId = venueId
    self.sport = sport
    self.comments = comments
    self.bottomLeft = bottomLeft
    self.bottomRight = bottomRight
    self.topLeft = topLeft
    self.topRight = topRight
  }

  init (workoutID: UUID, bottomLeft: CodableCLLCoordinate2D, bottomRight: CodableCLLCoordinate2D, topLeft: CodableCLLCoordinate2D, topRight: CodableCLLCoordinate2D) {
    self.workoutID  = workoutID
    self.id = UUID()
    self.bottomLeft = bottomLeft
    self.bottomRight = bottomRight
    self.topLeft = topLeft
    self.topRight = topRight
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

