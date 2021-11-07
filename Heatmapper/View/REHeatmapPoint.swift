//
//  REHeatmapPoint.swift
//  Heatmapper
//
//  Created by Richard English on 01/11/2021.
//  Copyright © 2021 Richard English. All rights reserved.
//

import Foundation
import MapKit

// custom heatmap point class
class REHeatmapPointAnnotation: NSObject, MKAnnotation {
  var coordinate: CLLocationCoordinate2D
  var title: String?


  convenience override init() {
    self.init(coordinate:CLLocationCoordinate2DMake(0, 0), title:"", subtitle:"")
  }

  required init(coordinate: CLLocationCoordinate2D, title: String, subtitle: String) {
    self.title = title
    self.coordinate = coordinate
    super.init()
  }



}

