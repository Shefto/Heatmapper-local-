//
//  FootballPitchOverlay.swift
//  Heatmapper
//
//  Created by Richard English on 13/10/2021.
//  Copyright © 2021 Richard English. All rights reserved.
//

import MapKit

class FootballPitchOverlay: NSObject, MKOverlay {
//  let coordinate: CLLocationCoordinate2D
  let boundingMapRect: MKMapRect

//  init(pitch: FootballPitch) {
//    boundingMapRect = pitch.overlayBoundingMapRect
//    coordinate = pitch.midCoordinate
//  }

  init(pitchRect: MKMapRect) {
    boundingMapRect = pitchRect

  }
  // centre of Overlay
  var coordinate : CLLocationCoordinate2D
  {
    let midMKPoint = MKMapPoint(x: boundingMapRect.midX, y: boundingMapRect.midY)
    return midMKPoint.coordinate
  }

  // covered range of Overlay
//  var boundingMapRect: MKMapRect
//  {
//    guard let beenCalculatedMapRect = calculatedMapRect else {
//      fatalError("boundingMapRect Error")
//    }
//    return beenCalculatedMapRect
//
//
//
//  }

}
