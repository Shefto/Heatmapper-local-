//
//  PlayingArea.swift
//  Heatmapper
//
//  Created by Richard English on 02/10/2021.
//  Copyright © 2021 Richard English. All rights reserved.
//

import Foundation
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


struct PlayingArea: Codable, Equatable {
  static func == (lhs: PlayingArea, rhs: PlayingArea) -> Bool {
    return true
  }


  var name  : String
  var sport : Sport
  var minX  : CodableCLLCoordinate2D
  var maxX  : CodableCLLCoordinate2D
  var minY  : CodableCLLCoordinate2D
  var maxY  : CodableCLLCoordinate2D


  enum CodingKeys: String, CodingKey {
    case name = "Name"
    case sport = "Sport"
    case minX = "MinX"
    case maxX = "MaxX"
    case minY = "MinY"
    case maxY = "MaxY"
  }

  init (name: String, sport: Sport, minX: CodableCLLCoordinate2D, maxX: CodableCLLCoordinate2D, minY: CodableCLLCoordinate2D, maxY: CodableCLLCoordinate2D) {
    self.name = name
    self.sport = sport
    self.minX = minX
    self.maxX = maxX
    self.minY = minY
    self.maxY = maxY

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
