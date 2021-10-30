//
//  FootballPitchOverlay.swift
//  Heatmapper
//
//  Created by Richard English on 13/10/2021.
//  Copyright © 2021 Richard English. All rights reserved.
//

import MapKit

class FootballPitchOverlay: NSObject, MKOverlay {

  let boundingMapRect: MKMapRect

  init(pitchRect: MKMapRect) {
    boundingMapRect = pitchRect
    MyFunc.logMessage(.debug, "FootballPitchOverlay initialised with boundingMapRect = \(boundingMapRect)")
  }

  // centre of Overlay
  var coordinate : CLLocationCoordinate2D
  {
    let midMKPoint = MKMapPoint(x: boundingMapRect.midX, y: boundingMapRect.midY)
    MyFunc.logMessage(.debug, "FootballPitchOverlay coordinate set to \(String(describing: midMKPoint.coordinate))")
    return midMKPoint.coordinate
  }


}
