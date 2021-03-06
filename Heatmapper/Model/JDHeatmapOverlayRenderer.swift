////
////  JDHeatmapOverlayRenderer.swift
////  Heatmapper
////
////  Created by Richard English on 24/04/2021.
////  Copyright © 2021 Richard English. All rights reserved.
////
//
//
//import Foundation
//import MapKit
//
///*
// Translation from Chinese original:
// This class only needs to know the related drawing, it doesn't need to remember any point data
// Just give it to HeatmapPoint class to manufacture and give it a Heatmap Point */
//
//// MKOverlayRenderer is the class that draws (renders) the overlays onto the map
//
//class JDHeatmapOverlayRenderer :  MKOverlayRenderer
//{
//
//  var lastImage         : CGImage?
//  var workoutId         : UUID?
//  // IntSize is a custom Struct with a width (Int) and height (Int) both defaulted to zero
//  var bitmapSize        : IntSize = IntSize()
//  var bitmapMemorySize  : Int {
//    return bitmapSize.width * bitmapSize.height * 4
//  }
//
//  var dataReference     : [UTF8Char] = []
//  var bytesPerRow       : Int = 0
//
//  init (heat overlay: JDHeatmapOverlay) {
//    super.init(overlay: overlay)
//    self.alpha = 0.6
//  }
//
//  // this function is overridden by both this class's subclasses
//  func calcHeatmapPointsAndRect(maxHeat level:Int) -> (heatmapPointCGArray: [HeatmapPointCG], heatmapCGect:CGRect)?
//  {
//    return nil
//  }
//
//  /**
//   drawMapRect is the real meat of this class; it defines how MapKit should render this view when given a specific MKMapRect, MKZoomScale, and the CGContextRef
//   */
//  // overriding the draw function is the standard approach to using the MKOverlayRenderer class when subclassing it
//  // MKMapRect is simply a rectangle on a 2D map
//  // MKZoomScale is the scale factor being used on the map
//  // CGContext is "a Quartz 2D drawing environment" - basically, the envt on which to draw the heatmap (in this case)
//  override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
//
//    // this checks the overlay conforms to the custom subclass of MKOverlay
//    guard let overlay = overlay as? JDHeatmapOverlay else {
//      return
//    }
//
//    // Last Time Created image have more resolution, so keep using it
//    // think this is only satisfied if the image has already been drawn i.e. this function has been called at least once
//    if let lastTimeMoreHighSolutionImage = lastImage
//    {
//      let mapCGRect = rect(for: overlay.boundingMapRect)
//      context.draw(lastTimeMoreHighSolutionImage, in: mapCGRect)
//
////      let fileDateFormatter = DateFormatter()
////      fileDateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
////      let currDate = fileDateFormatter.string(from: Date())
//
//      guard let internalWorkoutId = workoutId else {
//        MyFunc.logMessage(.error, "No workoutID received by JDHeatmapOverlayRenderer")
//        return
//
//      }
//
//      let workoutIDString = String(describing: internalWorkoutId)
//
//      let fileName = "JDHeatmap_" + workoutIDString + ".png"
//
//      let uiImage = UIImage(cgImage: lastTimeMoreHighSolutionImage)
//
//        if let data = uiImage.pngData() {
//          let fileURL = getDocumentsDirectory().appendingPathComponent(fileName)
//          try? data.write(to: fileURL)
//          MyFunc.logMessage(.debug, "Heatmap image \(fileName) saved to \(fileURL)")
//        }
//
//      return
//    }
//    else if (dataReference.count == 0 )
//    {
//      //The Data is not ready
//      return
//    }
//
//    if let tempImage = getHeatMapContextImage()
//    {
//      let mapCGRect = rect(for: overlay.boundingMapRect)
//      lastImage = tempImage
//      context.clear(mapCGRect)
//      self.dataReference.removeAll()
//      context.draw(lastImage!, in: mapCGRect)
//    }
//    else{
//      print("cgcontext error")
//    }
//  }
//
//
//  func getDocumentsDirectory() -> URL {
//    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
//    let documentsDirectory = paths[0]
//    return documentsDirectory
//  }
//
//  // this function used above to generate the image
//  // very technical and may be best to simply use it as a black box
//  func getHeatMapContextImage() -> CGImage?
//  {
//    //this function converts the MKMapRect into a CGImage
//    func createContextOldWay() -> CGImage?
//    {
//
//      if let cgImage = heatMapCGImage()
//      {
//        let cgSize : CGSize = CGSize(width: bitmapSize.width, height: bitmapSize.height)
//        // creates a bitmap-based graphics context and makes it the current context.
//        UIGraphicsBeginImageContext(cgSize)
//        if let contexts = UIGraphicsGetCurrentContext()
//        {
//          let rect = CGRect(origin: CGPoint.zero, size: cgSize)
//          contexts.draw(cgImage, in: rect)
//          return contexts.makeImage()
//        }
//      }
//      print("Create fail")
//      return nil
//    }
//
//    func heatMapCGImage() -> CGImage?
//    {
//      // creates a buffer to store the temporary image generated
//      let tempBuffer = malloc(bitmapMemorySize)
//      // this is very technical : memcpy suggests copying from one part of memory to another
//      memcpy(tempBuffer, &dataReference, bytesPerRow * bitmapSize.height)
//      defer
//      {
//        free(tempBuffer)
//      }
//      let rgbColorSpace : CGColorSpace = CGColorSpaceCreateDeviceRGB()
//      let alphaBitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
//      if let contextlayer : CGContext = CGContext(data: tempBuffer, width: bitmapSize.width, height: bitmapSize.height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: rgbColorSpace, bitmapInfo: alphaBitmapInfo)
//      {
//        return contextlayer.makeImage()
//      }
//      return nil
//    }
//
//    let imageToReturn = createContextOldWay()
//    UIGraphicsEndImageContext()
//
//    return imageToReturn
//  }
//
//} // func draw
//
//// subclass of the custom class based on MKOverlayRenderer
//class JDRadiusPointHeatmapOverlayRenderer : JDHeatmapOverlayRenderer
//{
//  // this function returns the array of heatmap points and the rectangle denoting the size of the heatmap
//  override func calcHeatmapPointsAndRect(maxHeat level : Int)->(data : [HeatmapPointCG], rect:CGRect)?
//  {
//    guard let heatmapOverlay = overlay as? JDHeatmapOverlay else {
//      return nil
//    }
//    var heatmapPointCGArray: [HeatmapPointCG] = []
//
//    for heatmapPoint in heatmapOverlay.heatmapPoint2DArray
//    {
//      // midMapPoint is the dead centre of the heatmapPoint's coordinate
//      let midMapPoint = heatmapPoint.midMapPoint
//
//      // this converts the MKMapPoint to a Core Graphics point
//      let globalCGPoint : CGPoint = self.point(for: midMapPoint)
//      let overlayCGRect = rect(for: heatmapOverlay.boundingMapRect)
//      let localX        = globalCGPoint.x - (overlayCGRect.origin.x)
//      let localY        = globalCGPoint.y - (overlayCGRect.origin.y)
//      let localCGPoint  = CGPoint(x: localX, y: localY)
//      // local CGPoint is the Core Graphics equivalent - i.e. where to place the map point on the CG map object
//
//      // this converts the MapKit radius to a Core Graphics radius
//      let radiusinMKDistance  : Double = heatmapPoint.radiusInMKDistance
//      let radiusMapRect       = MKMapRect(origin: MKMapPoint.init(), size: MKMapSize(width: radiusinMKDistance, height: radiusinMKDistance))
//      let radiusCGDistance    = rect(for: radiusMapRect).width
//
//      // Take the CG Point, CG radius above and create a HeatmapPointCG from it
//      let newHeatmapPointCG : HeatmapPointCG = HeatmapPointCG(heatlevel: Float(heatmapPoint.heatLevel) / Float(level), localCGpoint: localCGPoint, radius: radiusCGDistance)
//      // append the point to our CG Array
//      heatmapPointCGArray.append(newHeatmapPointCG)
//    }
//
//    let overlayRect = rect(for: heatmapOverlay.boundingMapRect)
//    return (data: heatmapPointCGArray, rect: overlayRect)
//  }
//}
//
//// subclass of the custom class based on MKOverlayRenderer
//// virtually identical to the other subclass - this duplication may be unnecessary
//class JDFlatPointHeatmapOverlayRenderer : JDHeatmapOverlayRenderer
//{
//
//  // this is the key logic for actually creating the heatmap
//  // it returns the set of HeatmapPointCGs and the rectangle (or our pitch, effectively)
//  override func calcHeatmapPointsAndRect(maxHeat level:Int) -> (data: [HeatmapPointCG], rect: CGRect)?
//  {
//    guard let overlay = overlay as? JDHeatmapOverlay else {
//      return nil
//    }
//
//    var heatmapPointCGArray : [HeatmapPointCG] = []
//    let overlayCGRect       : CGRect = rect(for: overlay.boundingMapRect)
//    for heatmapPoint2D in overlay.heatmapPoint2DArray
//    {
//      let heatmapMidMapPoint = heatmapPoint2D.midMapPoint
//      let globalCGpoint : CGPoint = self.point(for: heatmapMidMapPoint)
//
//      let localX = globalCGpoint.x - (overlayCGRect.origin.x)
//      let localY = globalCGpoint.y - (overlayCGRect.origin.y)
//      let localCGPoint = CGPoint(x: localX, y: localY)
//
//      let radiusinMKDistance    : Double = heatmapPoint2D.radiusInMKDistance
//      let radiusMapRect         = MKMapRect(origin: MKMapPoint.init(), size: MKMapSize(width: radiusinMKDistance, height: radiusinMKDistance))
//      let radiusCGDistance      = rect(for: radiusMapRect).width
//
//      let newHeatmapPointCG: HeatmapPointCG = HeatmapPointCG(heatlevel: Float(heatmapPoint2D.heatLevel) / Float(level), localCGpoint: localCGPoint, radius: radiusCGDistance)
//      heatmapPointCGArray.append(newHeatmapPointCG)
//    }
//    let cgSize = rect(for: overlay.boundingMapRect)
//    return (data: heatmapPointCGArray, rect: cgSize)
//  }
//
//
//}
//
