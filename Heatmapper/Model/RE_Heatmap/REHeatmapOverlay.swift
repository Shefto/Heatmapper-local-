////
////  RE_DTMHeatmap.swift
////  Heatmapper
////
////  Created by Richard English on 08/07/2021.
////  Copyright © 2021 Richard English. All rights reserved.
////
////  This is a conversion of DTMHeatmap Swift 5
////
//
//import UIKit
//import MapKit
//
//class REHeatmapOverlay:  NSObject, MKOverlay {
//
//  // these variables are parameters which can be altered to configure the heatmaps
//  private let kSBMapRectPadding     : Double = 100000.0
//  private let kSBZoomZeroDimension           = 256         /* 2 to the power 8 */
//  private let kSBMapKitPoints                = 536870912   /* 2 to the power 28 */
//  private let kSBZoomLevels                  = 20          /* zoom levels - 28 minus 8 */
//
////  var mapPointArray = [MKMapPoint]()
//  var mapPointArray = [REHeatmapPoint]()
//
//  // Alterable constant to change look of heat map
//  private let kSBScalePower = 4
//
//  // Alterable constant to trade off accuracy with performance
//  // Increase for big data sets which draw slowly
//  private let kSBScreenPointsPerCell = 10
//
//
//  // declares a local version of the class that controls the colour setting for the heat points
//  var colorProvider: REColourProvider?
//
//  private var maxValue        : Double = 0.0
//  private var zoomedOutMax    : Double = 0.0
//
//
//  //  private var mapRectCentre   : CLLocationCoordinate2D?
//  private var boundingRect    : MKMapRect!
//
//  override init() {
//    super.init()
//    colorProvider = REColourProvider()
//  }
//
//  // coordinate is required by the MKOverlay protocol
//  var coordinate : CLLocationCoordinate2D
//  {
//    let midMKPoint = MKMapPoint(x: boundingMapRect.midX, y: boundingMapRect.midY)
//    return midMKPoint.coordinate
//  }
//
//  // required by MKOverlay protocol
//  var boundingMapRect: MKMapRect {
//    return boundingRect
//  }
//
//  // this takes in an array of coordinates
//  // it uses them to calculate the heatmap heat at each point in a 256 * 256 matrix
//  // then (unlike DTMHeatmap) it needs to return the heatmap cell array
//  func setData(reHeatmapPointArray: [REHeatmapPoint]) -> [Double] {
//
//    // convert the set of coordinates to MKMapPoints
////    self.mapPointArray = reHeatmapPointArray.map({ $0.mapPoint})
//    self.mapPointArray = reHeatmapPointArray
//
//    // these map points mark out the two opposite points of the rectangle
//    var upperLeftPoint: MKMapPoint
//    var lowerRightPoint: MKMapPoint
//
//
//    // start with both the upper left and lower right points identical - we will start from a point and expand outwards as each new point is processed
//    guard let firstMapPoint = mapPointArray.first else
//    {
//      MyFunc.logMessage(.error, "No coordinates received by REHeatmap_Overlay.setData")
//      return [0.0]
//    }
//    upperLeftPoint = firstMapPoint.mapPoint
//    lowerRightPoint = upperLeftPoint
//
//
//
//    // loop round every mapPoint and get the most extreme 4 x and y coordinates
//    let highestX = mapPointArray.map {$0.mapPoint.x}.max() ?? 0.0
//    let lowestX = mapPointArray.map {$0.mapPoint.x}.min() ?? 0.0
//    let highestY = mapPointArray.map {$0.mapPoint.y}.max() ?? 0.0
//    let lowestY = mapPointArray.map {$0.mapPoint.y}.min() ?? 0.0
//
//    upperLeftPoint.x = highestX
//    upperLeftPoint.y = highestY
//    lowerRightPoint.x = lowestX
//    lowerRightPoint.y = lowestY
//
//    // this variable not in DTM - added to break up complex logic
//    let kSBPointsDividedByZoom  = kSBMapKitPoints / kSBZoomZeroDimension
//    let kSBPointsDividedByZoomDouble  = Double(kSBPointsDividedByZoom)
//
//
//    // heatmapCellSequence is a 256 * 256 sized array
//    // essentially divides the view into a 256*256 matrix
//    // named "buckets" in the original DTMHeatmap
//    var heatmapCellArray = [Double](repeating: 0.0, count: kSBZoomZeroDimension * kSBZoomZeroDimension)
//
//    for reMapPoint in mapPointArray {
//
//
//      // get the column and row into which the map point would fall
//      // effectively this is dividing the map into a matrix and putting the map point in a cell
//      let col = Int(reMapPoint.mapPoint.x / kSBPointsDividedByZoomDouble)
//      let row = Int(reMapPoint.mapPoint.y / kSBPointsDividedByZoomDouble)
//
//      // below line assigns each cell in the matrix a sequential number
//      // i.e. like numbering squares on a chessboard from 1 to 64
//      let cellSequenceNumber = kSBZoomZeroDimension * row + col
//      MyFunc.logMessage(.debug, "cellSequenceNumber: \(String(describing: cellSequenceNumber))")
//
//      // once the number is calculated, increment the value of that bucket by the value
//      heatmapCellArray[cellSequenceNumber] = heatmapCellArray[cellSequenceNumber] + 1
//    }
//
//
//    // now get the highest value in the array
//    // using set function here to replace the original's obj-C loop
//    let highestValue = heatmapCellArray.max()
//    self.zoomedOutMax = highestValue ?? 0.0
//
//    // set the width and height required for the map rectangle from the
//    // lowerRightPoint and upperLeftPoint as calculated above
//    // and include the padding
//    let width = lowerRightPoint.x - upperLeftPoint.x + kSBMapRectPadding
//    let height = lowerRightPoint.y - upperLeftPoint.y + kSBMapRectPadding
//
//    // now use the above to set the map rectangle
//    self.boundingRect = MKMapRect(x: upperLeftPoint.x - kSBMapRectPadding / 2,
//                                  y: upperLeftPoint.y - kSBMapRectPadding / 2, width: width, height: height)
//
//    // finally return the cell array
//    return heatmapCellArray
//  }
//
//  // this function takes the rectangle size and scale passed in and returns a set of RE Heatmap Points
//  func mapPointsWithHeatInMapRect(rect: MKMapRect, scale: MKZoomScale) -> [REHeatmapPoint] {
//
//    // kSBScreenPointsPerCell is a constant set at class level above to manage performance
//    let pointsPerCellAtScale : Int = kSBScreenPointsPerCell / Int(scale)
//
//
//    // this gets the binary logarithm of 1 over the scale passed in
//    // https://en.wikipedia.org/wiki/Binary_logarithm
//    let zoomScale : Double = Double(log2(1 / scale))
//
//    // lots happening here that needs unpicking
//    // essentially all calculations used to produce a scaleFactor
//    let slope : Double = (self.zoomedOutMax - self.maxValue) / Double((kSBZoomLevels - 1))
//    let zoomScalePower : Double = pow(zoomScale, Double(kSBScalePower))
//    let zoomLevelsPower : Double = pow(Double(kSBZoomLevels), Double(kSBScalePower - 1))
//    let zoomScaleDividedByZoomLevels: Double = zoomScalePower / zoomLevelsPower
//
//    var scaleFactor = Double(zoomScaleDividedByZoomLevels - 1) * slope + self.maxValue
//
//    if (scaleFactor < self.maxValue) {
//      scaleFactor = self.maxValue
//    }
//
//    // clear the dictionary to remove all points
//    var pointsToReturn = [REHeatmapPoint]()
//
//
//    // loop through each map point in the heatmap point array
//    for heatmapPoint in mapPointArray  {
//
//      if !rect.contains(heatmapPoint.mapPoint) {
//        continue
//      }
//
//      // Scale the value down by the max and add it to the return dictionary
//      let heatPointValue = heatmapPoint.heatLevel
//
//      let scaledHeatPointValue = heatPointValue / scaleFactor
//
//      let originalX = Int(heatmapPoint.mapPoint.x)
//      let originalY = Int(heatmapPoint.mapPoint.y)
//      let pointToReturnX = Double(originalX - originalX % pointsPerCellAtScale + pointsPerCellAtScale / 2)
//      let pointToReturnY = Double(originalY - originalY % pointsPerCellAtScale + pointsPerCellAtScale / 2)
//
//      let mapPointToReturn = MKMapPoint(x: pointToReturnX, y: pointToReturnY)
//
//
//      let pointToReturn = REHeatmapPoint(mapPoint: mapPointToReturn, radius: 1, heatLevel: scaledHeatPointValue)
//      pointsToReturn.append(pointToReturn)
//
////      pointsToReturn.append(mapPointToReturn)
//    }
//
//    return pointsToReturn
//
//  }
//
//}
