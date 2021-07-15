//
//  RE_DTMHeatmap.swift
//  Heatmapper
//
//  Created by Richard English on 08/07/2021.
//  Copyright © 2021 Richard English. All rights reserved.
//

import UIKit
import MapKit

private let kSBMapRectPadding: Double = 100000.0
private let kSBZoomZeroDimension = 256
private let kSBMapKitPoints = 536870912
private let kSBZoomLevels = 20

// Alterable constant to change look of heat map
private let kSBScalePower = 4

// Alterable constant to trade off accuracy with performance
// Increase for big data sets which draw slowly
private let kSBScreenPointsPerBucket = 10

class RE_Heatmap:  NSObject, MKOverlay {

  var colorProvider: RE_ColorProvider?

  private var maxValue : Double = 0.0
  private var zoomedOutMax = 0.0
  private var pointsWithHeat: [AnyHashable : MKMapPoint]?
  private var pointsToReturn: [AnyHashable : MKMapPoint]?
  private var center: CLLocationCoordinate2D?
  private var boundingRect: MKMapRect!

  override init() {
    super.init()
    colorProvider = RE_ColorProvider()
  }

  // required by MKOverlay protocol
  var coordinate : CLLocationCoordinate2D
  {
    let midMKPoint = MKMapPoint(x: boundingMapRect.midX, y: boundingMapRect.midY)
    return midMKPoint.coordinate
  }

  // required by MKOverlay protocol
  var boundingMapRect: MKMapRect {
    return boundingRect
  }

  // this function sets the size of the map rectangle
  func setData(_ newHeatMapData: [AnyHashable : MKMapPoint]?) {


    // these map points mark out the two opposite points of the rectangle
    var upperLeftPoint: MKMapPoint
    var lowerRightPoint: MKMapPoint

    guard let firstValue = (newHeatMapData?.first?.value) as? MKMapPoint else
    {
      MyFunc.logMessage(.error, "newHeatMapData cannot be converted to MKMapPoint")
      return
    }
    upperLeftPoint = firstValue
    // start with them identical
    lowerRightPoint = upperLeftPoint

    // buckets appears to be a set of floats
    var buckets = [Float]()
//    let buckets = calloc(kSBZoomZeroDimension * kSBZoomZeroDimension, MemoryLayout<Float>.size)

    // loop through each map point in the heatmap point array
    for (index, value) in newHeatMapData ?? [:] {

      // type check for mapPointValue - bring back
      guard let mapPointValue = value as? NSValue else {
        continue
      }

      guard let mapPoint = mapPointValue as? MKMapPoint else {
        MyFunc.logMessage(.debug, "value in newHeatMapData does not conform to type MKMapPoint")
        return
      }


      // if the point being checked is further left than the current furthest left point, update that
      if mapPoint.x < upperLeftPoint.x {
        upperLeftPoint.x = mapPoint.x
      }
      // if the point being checked is further up than the current furthest up point, update that
      if mapPoint.y < upperLeftPoint.y {
        upperLeftPoint.y = mapPoint.y
      }
      // if the point being checked is further right than the current furthest right point, update that
      if mapPoint.x > lowerRightPoint.x {
        lowerRightPoint.x = mapPoint.x
      }
      // if the point being checked is further down than the current furthest down point, update that
      if mapPoint.y > lowerRightPoint.y {
        lowerRightPoint.y = mapPoint.y
      }

      // get absolute for value being looped through

      guard let valueDouble = Double(value as! Substring) else
      {
        return
      }

      let valueDoubleAbsolute = abs(valueDouble)

      if valueDoubleAbsolute > maxValue {
        maxValue = valueDoubleAbsolute
      }

      let kSBPointsDividedByZoom = Double(kSBMapKitPoints / kSBZoomZeroDimension)
      let col = Int(mapPoint.x / kSBPointsDividedByZoom)
      let row = Int(mapPoint.y / kSBPointsDividedByZoom)

      let offset = kSBZoomZeroDimension * row + col

      buckets[offset] = buckets[offset] + Float(valueDouble)
    }

    let kSBZoomZeroDimensionSquared = kSBZoomZeroDimension * kSBZoomZeroDimension

    for count in 0..<kSBZoomZeroDimensionSquared {

      let abs = Double(abs(buckets[count]))
      if abs > self.zoomedOutMax {
        self.zoomedOutMax = abs
      }

    }

    let width = lowerRightPoint.x - upperLeftPoint.x + kSBMapRectPadding
    //      double width = lowerRightPoint.x - upperLeftPoint.x + kSBMapRectPadding;

    let height = lowerRightPoint.y - upperLeftPoint.y + kSBMapRectPadding
    //    double height = lowerRightPoint.y - upperLeftPoint.y + kSBMapRectPadding;

    self.boundingRect = MKMapRect(x: upperLeftPoint.x - kSBMapRectPadding / 2,
                                  y: upperLeftPoint.y - kSBMapRectPadding / 2, width: width, height: height)
    self.center = MKMapPoint(x: upperLeftPoint.x + width / 2, y: upperLeftPoint.y + height / 2).coordinate
    self.pointsWithHeat = newHeatMapData

  }

  func mapPointsWithHeatInMapRect(rect: MKMapRect, scale: MKZoomScale) -> [AnyHashable : Any]? {
    //      NSMutableDictionary *toReturn = [[NSMutableDictionary alloc] init];


    var bucketDelta : Int = kSBScreenPointsPerBucket / Int(scale)
    //      int bucketDelta = kSBScreenPointsPerBucket / scale;

    var zoomScale : Double = Double(log2(1 / scale))
    //      double zoomScale = log2(1/scale);

    var slope : Double = (self.zoomedOutMax - self.maxValue) / Double((kSBZoomLevels - 1))
    //    double x = pow(zoomScale, kSBScalePower) / pow(kSBZoomLevels, kSBScalePower - 1);

    let zoomScalePower : Double = pow(zoomScale, Double(kSBScalePower))
    let zoomLevelsPower : Double = pow(Double(kSBZoomLevels), Double(kSBScalePower - 1))

    let x: Double = zoomScalePower / zoomLevelsPower

    var scaleFactor = Double(x - 1) * slope + self.maxValue


    if (scaleFactor < self.maxValue) {
      scaleFactor = self.maxValue
    }

    // clear the dictionary to remove all points
    pointsToReturn?.removeAll()
    // loop through each map point in the heatmap point array
    for (index, heatPoint) in pointsWithHeat ?? [:] {

//      // type check for mapPointValue - bring back
//      guard let mapPointValue = value as? NSValue else {
//        continue
//      }
//
//      guard let mapPoint = mapPointValue as? MKMapPoint else {
//        MyFunc.logMessage(.debug, "value in newHeatMapData does not conform to type MKMapPoint")
//        return
//      }

      if !rect.contains(heatPoint) {
        continue
      }

      // Scale the value down by the max and add it to the return dictionary
      let heatPointValue = pointsWithHeat?[index] as? NSNumber
      let unscaled = heatPointValue?.doubleValue ?? 0.0
      var scaled = unscaled / scaleFactor

      let originalX = Int(heatPoint.x)
      let originalY = Int(heatPoint.y)
      let pointToReturnX = Double(originalX - originalX % bucketDelta + bucketDelta / 2)
      let pointToReturnY = Double(originalY - originalY % bucketDelta + bucketDelta / 2)

      let mapPointToReturn = MKMapPoint(x: pointToReturnX, y: pointToReturnY)
      let pointsToReturnCount = pointsToReturn?.count
      pointsToReturn?.updateValue(mapPointToReturn, forKey: pointsToReturnCount)
    }

    return pointsToReturn

  }

}
