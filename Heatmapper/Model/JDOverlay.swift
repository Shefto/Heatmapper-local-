//
//  JDOverlay.swift
//  Heatmapper
//
//  Created by Richard English on 24/04/2021.
//  Copyright © 2021 Richard English. All rights reserved.
//
//  Sub-class of MKOverlay


import UIKit
import MapKit

//This class only needs to know the MapRect level, not the CGRect level.

// custom MKOverlay class for Heatmap
class JDHeatmapOverlay : NSObject, MKOverlay
{
  var heatmapPoint2DArray  : [heatmapPoint2D] = []
  var calculatedMapRect   : MKMapRect?

  // centre of Overlay
  var coordinate : CLLocationCoordinate2D
  {
    let midMKPoint = MKMapPoint(x: boundingMapRect.midX, y: boundingMapRect.midY)
    return midMKPoint.coordinate
  }

  // covered range of Overlay
  var boundingMapRect: MKMapRect
  {
    guard let beenCalculatedMapRect = calculatedMapRect else {
      fatalError("boundingMapRect Error")
    }
    return beenCalculatedMapRect
  }

  init(first Heatpoint: heatmapPoint2D)
  {
    super.init()
    calculateMapRect(newPoint: Heatpoint)
    heatmapPoint2DArray.append(Heatpoint)
  }

  func insertHeatpoint(input:heatmapPoint2D)
  {
    // recalculate the map rectangle incorporating the new point
    calculateMapRect(newPoint: input)
    //append the new point to the array
    heatmapPoint2DArray.append(input)
  }

  // this function simply recalculates the map rectangle incorporating the new point
  func calculateMapRect(newPoint: heatmapPoint2D)
  {
    var maxX:Double = -9999999999999
    var maxY:Double = -9999999999999
    var minX:Double = 99999999999999
    var minY:Double = 99999999999999

    if let beenCalculatedMapRect = calculatedMapRect
    {
      //Not the First Time
      maxX = beenCalculatedMapRect.maxX
      maxY = beenCalculatedMapRect.maxY
      minX = beenCalculatedMapRect.minX
      minY = beenCalculatedMapRect.minY

      let newPointMapRect = newPoint.mapRect
      let tMaxX = newPointMapRect.maxX
      let tMaxY = newPointMapRect.maxY
      let tMinX = newPointMapRect.minX
      let tMinY = newPointMapRect.minY
      maxX = (tMaxX > maxX) ? tMaxX : maxX
      maxY = (tMaxY > maxY) ? tMaxY : maxY
      minX = (tMinX < minX) ? tMinX : minX
      minY = (tMinY < minY) ? tMinY : minY
    }
    else
    {
      // first time calculate first point only
      let heatmapRect = newPoint.mapRect
      maxX = heatmapRect.maxX
      maxY = heatmapRect.maxY
      minX = heatmapRect.minX
      minY = heatmapRect.minY
    }
    let rect = MKMapRect.init(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    calculatedMapRect = rect
  }

}
