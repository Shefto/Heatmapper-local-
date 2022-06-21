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

  var id          : UUID
//  var workoutID   : UUID?
  var name        : String?
  var venue       : String?
  var sport       : String?
  var comments    : String?
  var isFavourite : Bool
  var bottomLeft  : CodableCLLCoordinate2D
  var bottomRight : CodableCLLCoordinate2D
  var topLeft     : CodableCLLCoordinate2D
  var topRight    : CodableCLLCoordinate2D

  enum CodingKeys: String, CodingKey {

    case id = "Id"
//    case workoutID = "WorkoutId"
    case name = "Name"
    case venue = "Venue"
    case sport = "Sport"
    case isFavourite = "IsFavourite"
    case comments = "Comments"
    case bottomLeft = "BottomLeft"
    case bottomRight = "BottomRight"
    case topLeft = "TopLeft"
    case topRight = "TopRight"

  }

  init (playingAreaId: UUID?, bottomLeft: CodableCLLCoordinate2D, bottomRight: CodableCLLCoordinate2D, topLeft: CodableCLLCoordinate2D, topRight: CodableCLLCoordinate2D, name: String?, venue: String?, sport: String?, comments: String?, isFavourite: Bool) {

    if playingAreaId != nil {
      self.id = playingAreaId!
    } else {
      self.id = UUID()
    }
    self.name = name
    self.venue = venue
    self.sport = sport
    self.comments = comments
    self.bottomLeft = bottomLeft
    self.bottomRight = bottomRight
    self.topLeft = topLeft
    self.topRight = topRight
    self.isFavourite = isFavourite
  }

  init (bottomLeft: CodableCLLCoordinate2D, bottomRight: CodableCLLCoordinate2D, topLeft: CodableCLLCoordinate2D, topRight: CodableCLLCoordinate2D, name: String?, venue: String?, sport: String?, comments: String?, isFavourite: Bool) {

    self.id = UUID()

    self.name = name
    self.venue = venue
    self.sport = sport
    self.comments = comments
    self.bottomLeft = bottomLeft
    self.bottomRight = bottomRight
    self.topLeft = topLeft
    self.topRight = topRight
    self.isFavourite = isFavourite
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

