//
//  PlayingAreaOverlay.swift
//  Heatmapper
//
//  Created by Richard English on 13/10/2021.
//  Copyright © 2021 Richard English. All rights reserved.
//

import MapKit

class PlayingAreaOverlay: NSObject, MKOverlay {

  let boundingMapRect: MKMapRect

  init(pitchRect: MKMapRect) {
    boundingMapRect = pitchRect
  }

  // centre of Overlay
  var coordinate : CLLocationCoordinate2D
  {
    let midMKPoint = MKMapPoint(x: boundingMapRect.midX, y: boundingMapRect.midY)
    return midMKPoint.coordinate
  }


}
