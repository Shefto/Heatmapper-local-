//
//  UserAnnotation.swift
//  Heatmapper
//
//  Created by Richard English on 13/04/2021.
//  Copyright © 2021 Richard English. All rights reserved.
//

import Foundation
import MapKit

// this classed used by TrackerViewController
class UserAnnotation: NSObject, MKAnnotation {
  var coordinate: CLLocationCoordinate2D
  var title: String?
  var subtitle: String?


  convenience override init() {
    self.init(coordinate:CLLocationCoordinate2DMake(41.887, -87.622), title:"", subtitle:"")
  }

  required init(coordinate: CLLocationCoordinate2D, title: String, subtitle: String) {
    self.title = title
    self.subtitle = subtitle
    self.coordinate = coordinate

    super.init()
  }



}
