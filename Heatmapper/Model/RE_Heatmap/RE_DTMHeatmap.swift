////
////  RE_DTMHeatmap.swift
////  Heatmapper
////
////  Created by Richard English on 08/07/2021.
////  Copyright © 2021 Richard English. All rights reserved.
////
//
//import UIKit
//import MapKit
//
//private let kSBMapRectPadding: CGFloat = 100000
//private let kSBZoomZeroDimension = 256
//private let kSBMapKitPoints = 536870912
//private let kSBZoomLevels = 20
//
//// Alterable constant to change look of heat map
//private let kSBScalePower = 4
//
//// Alterable constant to trade off accuracy with performance
//// Increase for big data sets which draw slowly
//private let kSBScreenPointsPerBucket = 10
//
//class DTMHeatmap: NSObject, MKOverlay {
//  private(set) var coordinate: CLLocationCoordinate2D?
//  var colorProvider: DTMColorProvider?
//
//
//  private var maxValue = 0.0
//  private var zoomedOutMax = 0.0
//  private var pointsWithHeat: [AnyHashable : Any]?
//  private var center: CLLocationCoordinate2D?
//  private var boundingRect: MKMapRect!
//
//  init() {
//    super.init()
//    colorProvider = DTMColorProvider()
//  }
//
//  func coordinate() -> CLLocationCoordinate2D {
//    return center
//  }
//
//  var boundingMapRect: MKMapRect {
//    return boundingRect
//  }
//
//  func setData(_ newHeatMapData: [AnyHashable : Any]?) {
//    var upperLeftPoint: MKMapPoint
//    var lowerRightPoint: MKMapPoint
//    newHeatMapData?.keys.last?.getValue(&upperLeftPoint)
//    lowerRightPoint = upperLeftPoint
//
//    let buckets = calloc(kSBZoomZeroDimension * kSBZoomZeroDimension, MemoryLayout<Float>.size)
//
//    for mapPointValue in newHeatMapData ?? [:] {
//      guard let mapPointValue = mapPointValue as? NSValue else {
//        continue
//      }
//      
//      var point: MKMapPoint
//
//      mapPointValue.getValue(&point)
//      let value = (newHeatMapData?[mapPointValue] as? NSNumber)?.doubleValue ?? 0.0
//
//      if point.x < upperLeftPoint.x {
//        upperLeftPoint.x = point.x
//      }
//      if point.y < upperLeftPoint.y {
//        upperLeftPoint.y = point.y
//      }
//      if point.x > lowerRightPoint.x {
//        lowerRightPoint.x = point.x
//      }
//      if point.y > lowerRightPoint.y {
//        lowerRightPoint.y = point.y
//      }
//
//      let abs = Double(abs(value))
//      if abs > maxValue {
//        maxValue = abs
//      }
//
//      //bucket the map point:
//      let col = Int(point.x / (kSBMapKitPoints / kSBZoomZeroDimension))
//      let row = Int(point.y / (kSBMapKitPoints / kSBZoomZeroDimension))
//
//      let offset = kSBZoomZeroDimension * row + col
//
//      buckets[offset] += value
//    }
//
//    let kSBZoomZeroDimensionSquared = kSBZoomZeroDimension * kSBZoomZeroDimension
//
//    for count in 0..<kSBZoomZeroDimensionSquared {
//
//      let abs = Double(abs(buckets[count]))
//      if abs > self.zoomedOutMax {
//        self.zoomedOutMax
//      }
//
//    }
//
//    let width = lowerRightPoint.x - upperLeftPoint.x + kSBMapRectPadding
//    //      double width = lowerRightPoint.x - upperLeftPoint.x + kSBMapRectPadding;
//
//    let height = lowerRightPoint.y - upperLeftPoint.y + kSBMapRectPadding
//    //    double height = lowerRightPoint.y - upperLeftPoint.y + kSBMapRectPadding;
//
//    self.boundingRect = MKMapRect(upperLeftPoint.x - kSBMapRectPadding / 2,
//                                  upperLeftPoint.y - kSBMapRectPadding / 2, width, height)
//    self.center = MKCoordinateForMapPoint(MKMapPointMake(upperLeftPoint.x + width / 2, upperLeftPoint.y + height / 2))
//    self.pointsWithHeat = newHeatMapData
//
//  }
//
//  func mapPointsWithHeatInMapRect(rect: MKMapRect, scale: MKZoomScale) {
//    //      NSMutableDictionary *toReturn = [[NSMutableDictionary alloc] init];
//
//
//    var bucketDelta: Int = kSBScreenPointsPerBucket / scale
//    //      int bucketDelta = kSBScreenPointsPerBucket / scale;
//
//    var zoomScale : Double = log2(1 / scale)
//    //      double zoomScale = log2(1/scale);
//
//    var slope : Double = (self.zoomedOutMax - self.maxValue) / (kSBZoomLevels - 1)
//    //    double x = pow(zoomScale, kSBScalePower) / pow(kSBZoomLevels, kSBScalePower - 1);
//
//    var x = pow(zoomScale, kSBScalePower) / pow(kSBZoomLevels, kSBScalePower - 1)
//    //      double x = pow(zoomScale, kSBScalePower) / pow(kSBZoomLevels, kSBScalePower - 1);
//
//    var scaleFactor : Double = (x - 1) * slope + self.maxValue
//    //      double scaleFactor = (x - 1) * slope + self.maxValue;
//
//    if (scaleFactor < self.maxValue) {
//      scaleFactor = self.maxValue
//    }
//
//    for key in pointsWithHeat {
//      var point: MKMapPoint
//      key.getValue(&point)
//
//      if !rect.contains(point) {
//        continue
//      }
//
//      // Scale the value down by the max and add it to the return dictionary
//      let value = pointsWithHeat[key] as? NSNumber
//      let unscaled = value?.doubleValue ?? 0.0
//      var scaled = unscaled / scaleFactor
//
//      var bucketPoint: MKMapPoint
//      let originalX = Int(point.x)
//      let originalY = Int(point.y)
//      bucketPoint.x = Double(originalX - originalX % bucketDelta + bucketDelta / 2)
//      bucketPoint.y = Double(originalY - originalY % bucketDelta + bucketDelta / 2)
//      let bucketKey = NSValue(&bucketPoint, withObjCType: "MKMapPoint")
//
//      let existingValue = toReturn[bucketKey]
//      if let existingValue = existingValue {
//        scaled += existingValue.doubleValue
//      }
//
//      toReturn[bucketKey] = NSNumber(value: scaled)
//    }
//
//    return toReturn
//
//  }
//
//}
