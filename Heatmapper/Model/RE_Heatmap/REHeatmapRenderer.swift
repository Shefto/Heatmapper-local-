//
//  RE_HeatmapRenderer.swift
//  Heatmapper
//
//  Created by Richard English on 08/07/2021.
//  Copyright © 2021 Richard English. All rights reserved.
//


import MapKit
import DTMHeatmap

private let kSBHeatRadiusInPoints = 48

class REHeatmapRenderer : MKOverlayRenderer {
  
  private var scaleMatrix: UnsafeMutablePointer<Float>?

  // standard protocol method to initialise the overlay
  override init(overlay: MKOverlay) {
    super.init(overlay: overlay)
    populateScaleMatrix()
  }


  func populateScaleMatrix() {
    for outerLoopCount in 0..<(2 * kSBHeatRadiusInPoints) {
      for innerLoopCount in 0..<(2 * kSBHeatRadiusInPoints) {
        let outerLoopSqrt = (outerLoopCount - kSBHeatRadiusInPoints) * (outerLoopCount - kSBHeatRadiusInPoints)
        let innerLoopSqrt = (innerLoopCount - kSBHeatRadiusInPoints) * (innerLoopCount - kSBHeatRadiusInPoints)
        let sqrtTotals : Double  = Double(outerLoopSqrt + innerLoopSqrt)
        let distance = sqrtTotals.squareRoot()
        let distanceFloat = Float(distance)
        
        var scaleFactor = 1 - distanceFloat / Float(kSBHeatRadiusInPoints)
        if scaleFactor < 0 {
          scaleFactor = 0
        } else {
          scaleFactor = (-distanceFloat / 10.0) - Float(-kSBHeatRadiusInPoints) / Float(10.0) / expf(0)
        }
        
        scaleMatrix?[innerLoopCount * 2 * kSBHeatRadiusInPoints + outerLoopCount] = scaleFactor
      }
    }
  }
  
//  override func draw(_ mapRectInput: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
//    
//    let userRect = rect(for: mapRectInput) //rect in user space coordinates (NOTE: not in screen points)
//    let visibleRect = overlay.boundingMapRect
//    let mapIntersect = mapRectInput.intersection(visibleRect)
//    let userIntersect = rect(for: mapIntersect) //rect in user space coordinates (NOTE: not in screen points)
//    
//    let columns = ceil(userRect.width * zoomScale)
//    let rows = ceil(userRect.height * zoomScale)
//    //    let arrayLen = columns * rows
//    
//    var pointValues = [Float]()
//    // allocate an array matching the screen point size of the rect
//    //    let pointValues = calloc(arrayLen, MemoryLayout<Float>.size)
//    
//    //    if let pointValues = pointValues {
//    // pad out the mapRect with the radius on all sides.
//    // we care about points that are not in (but close to) this rect
//    
//    let kSBHeatRadiusInPointsDouble = Double(kSBHeatRadiusInPoints)
//    let zooomScaleDouble = Double(zoomScale)
//    let radiusDividedByZoomDouble = kSBHeatRadiusInPointsDouble / zooomScaleDouble
//    let radiusDividedByZoomFloat = Float(radiusDividedByZoomDouble)
//    
//    var paddedRect = rect(for: mapRectInput)
//    paddedRect.origin.x -= CGFloat(radiusDividedByZoomFloat)
//    paddedRect.origin.y -= CGFloat(radiusDividedByZoomFloat)
//    paddedRect.size.width += 2 * CGFloat(radiusDividedByZoomFloat)
//    paddedRect.size.height += 2 * CGFloat(radiusDividedByZoomFloat)
//    let paddedMapRect = mapRect(for: paddedRect)
//    
//    
//    // Get the dictionary of heat points out of the model for this mapRect and zoomScale.
//    let reHeatmapOverlay = overlay as? REHeatmapOverlay
//    guard let heatmapOverlay = reHeatmapOverlay else {
//      return
//    }
////    let heatmapCellArray = heatmapOverlay.setData(coordinateArray: <#T##[CLLocationCoordinate2D]#>)
//    let mapPointsWithHeat = heatmapOverlay.mapPointsWithHeatInMapRect(rect: paddedMapRect, scale: zoomScale)
//    //    let mapPointsWithHeatKVO = heatmapOverlay?.mapPointsWithHeat(in: paddedMapRect, atScale: zoomScale)
//    
//    
//    for mapPoint in mapPointsWithHeat {
//
////      // type check for mapPointValue - bring back
////      guard let mapPointWithHeat = index as? MKMapPoint else {
////        MyFunc.logMessage(.debug, "mapPointValue in newHeatMapData does not conform to type MKMapPoint")
////        return
////      }
////
////      guard let valueDouble = value as? Double else {
////        MyFunc.logMessage(.debug, "value in newHeatMapData does not conform to type Double")
////        return
////      }
//
//      // figure out the corresponding array index
//      let userPoint = point(for: mapPoint)
//      
//      let matrixCoord = CGPoint(x: (userPoint.x - userRect.origin.x) * zoomScale,
//                                y: (userPoint.y - userRect.origin.y) * zoomScale)
//
//      if valueDouble != 0 && !valueDouble.isNaN {
//        // don't bother with 0 or NaN
//        // iterate through surrounding pixels and increase
//        for outerLoopCount in 0..<(2 * kSBHeatRadiusInPoints) {
//          for innerLoopCount in 0..<(2 * kSBHeatRadiusInPoints) {
//            // find the array index
//            let column = floor(matrixCoord.x - CGFloat(kSBHeatRadiusInPoints + outerLoopCount))
//            let row = floor(matrixCoord.y - CGFloat(kSBHeatRadiusInPoints + innerLoopCount))
//            
//            // make sure this is a valid array index
//            if row >= 0 && column >= 0 && row < rows && column < columns {
//              let index = columns * row + column
//              let addVal: Double = valueDouble * Double(scaleMatrix?[innerLoopCount * 2 * kSBHeatRadiusInPoints + outerLoopCount] ?? 1)
//              pointValues.append(Float(addVal))
//            }
//          }
//        }
//      }
//      
//      
//      var redDouble: Double = 0.0
//      var greenDouble: Double = 0.0
//      var blueDouble: Double = 0.0
//      var alphaDouble: Double = 0.0
//      var indexOrigin: Int
//
//      var rgba = [Double]()
//
//      let colorProvider = heatmapOverlay?.colorProvider
//      for counter in 0..<pointValues.count {
//        if pointValues[counter] != 0 {
//          indexOrigin = Int(4 * counter)
//
//          colorProvider?.color(forValue: Double(pointValues[counter]), red: redDouble, green: greenDouble, blue: blueDouble, alpha: alphaDouble)
//
//          rgba[indexOrigin] = redDouble
//          rgba[indexOrigin + 1] = greenDouble
//          rgba[indexOrigin + 2] = blueDouble
//          rgba[indexOrigin + 3] = alphaDouble
//        }
//      }
//      
//      //            free(pointValues);
//      
//      let colorSpace = CGColorSpaceCreateDeviceRGB()
//      let bitmapContext = CGContext(data: nil, width: Int(columns), height: Int(rows), bitsPerComponent: 8, bytesPerRow: Int(columns) * 4, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | 0)
//
//
//      
//      let cgImage = bitmapContext?.makeImage()
//      var img: UIImage? = nil
//      if let cgImage = cgImage {
//        img = UIImage(cgImage: cgImage)
//      }
//      UIGraphicsPushContext(context)
//      img?.draw(in: userIntersect)
//      UIGraphicsPopContext()
//
//    }
//    
//  }
  
}


