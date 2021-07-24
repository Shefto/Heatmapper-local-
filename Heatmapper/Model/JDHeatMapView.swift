//
//  JDRealHeatmap.swift
//  Heatmapper
//
//  Created by Richard English on 24/04/2021.
//  Copyright © 2021 Richard English. All rights reserved.
//

import Foundation
import MapKit

public enum JDMapType
{
  case RadiusDistinct
  case FlatDistinct
  case RadiusBlurry
}

enum DataPointType
{
  case FlatPoint
  case RadiusPoint
}

// custom subclass of MKMapView supporting the heatmap
public class JDHeatMapView : MKMapView
{
  var heatmapDelegate       : JDHeatMapDelegate?
  var heatmapManager        : JDHeatMapManager!
  var inProgressWheel       : UIActivityIndicatorView?

  public var showIndicator  : Bool = true {
    didSet{
      if (!showIndicator)
      {
        inProgressWheel?.stopAnimating()
      }
    }
  }

  // initialiser called with BasicColors and divideLevel populated within the initialiser

  public init (frame: CGRect, delegate: JDHeatMapDelegate, mapType: JDMapType, BasicColors array: [UIColor] = [UIColor.systemGreen, UIColor.systemOrange, UIColor.systemRed], divideLevel: Int = 2)
  {
    super.init(frame: frame)
    // MKMapView attribute - set to true = shows scale information
    self.showsScale = true
    self.delegate = self
    self.heatmapDelegate = delegate

    // this class declared elsewhere
    // this declares the colour mixer as using the 3 primary colours and a divide level of 2
    JDHeatmapPointCreator.theColorMixer = JDHeatMapColorMixer(array: array, level: divideLevel)

    if (mapType == .RadiusBlurry)
    {
      heatmapManager = JDHeatMapManager(JDSwiftHeatMapView: self, datapointType: .RadiusPoint, mode: .BlurryMode)
    }
    else if (mapType == .FlatDistinct)
    {
      heatmapManager = JDHeatMapManager(JDSwiftHeatMapView: self, datapointType: .FlatPoint, mode: .DistinctMode)
    }
    else if (mapType == .RadiusDistinct)
    {
      heatmapManager = JDHeatMapManager(JDSwiftHeatMapView: self, datapointType: .RadiusPoint, mode: .DistinctMode)
    }
    refreshView()
    initialiseProgressWheel()
  }

  required public init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
//    fatalError("init(coder:) has not been implemented")
  }

  public func refreshView()
  {
    if (self.showIndicator)
    {
      self.inProgressWheel?.startAnimating()
    }
    heatmapManager.refresh()
  }

  // called by the buttons on the VC - each passes in a different type
  public func setType(type: JDMapType)
  {
    if (type == .RadiusBlurry)
    {
      heatmapManager = JDHeatMapManager(JDSwiftHeatMapView: self, datapointType: .RadiusPoint, mode: .BlurryMode)
    }
    else if (type == .FlatDistinct)
    {
      heatmapManager = JDHeatMapManager(JDSwiftHeatMapView: self, datapointType: .FlatPoint, mode: .DistinctMode)
    }
    else if (type == .RadiusDistinct)
    {
      heatmapManager = JDHeatMapManager(JDSwiftHeatMapView: self, datapointType: .RadiusPoint, mode: .DistinctMode)
    }
    refreshView ()
  }


  func initialiseProgressWheel()
  {
    inProgressWheel = UIActivityIndicatorView(style: .large)
    inProgressWheel?.translatesAutoresizingMaskIntoConstraints = false
    self.addSubview(inProgressWheel!)
    let sizeWidth = NSLayoutConstraint(item: inProgressWheel!, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 0.0, constant: 60)
    let sizeHeight = NSLayoutConstraint(item: inProgressWheel!, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 0.0, constant: 60)
    let CenterX = NSLayoutConstraint(item: inProgressWheel!, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1.0, constant: 0)
    let CenterY = NSLayoutConstraint(item: inProgressWheel!, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1.0, constant: 0)

    inProgressWheel?.addConstraints([sizeWidth,sizeHeight])
    self.addConstraints([CenterX,CenterY])
    self.updateConstraints()
  }
}

extension JDHeatMapView: MKMapViewDelegate
{

  public func getMKOverlayRenderer(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer?
  {
    if let flatOverlay = overlay as? JDHeatmapOverlay
    {
      let flatPointRenderer = JDFlatPointHeatmapOverlayRenderer(heat: flatOverlay)
      return flatPointRenderer
    }
    else if let radiusOverlay = overlay as? JDHeatmapOverlay
    {
      let radiusPointRenderer = JDRadiusPointHeatmapOverlayRenderer(heat: radiusOverlay)
      return radiusPointRenderer
    }
    return MKOverlayRenderer()
  }

  public func heatmapViewWillStartRenderingMap(_ mapView: MKMapView)
  {
    heatmapManager.mapViewWillStartRenderingMap()
  }

  public func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer
  {
    if let heatmapRenderer = self.getMKOverlayRenderer(mapView, rendererFor: overlay)
    {
      return heatmapRenderer
    }
    else
    {
      return MKOverlayRenderer()
    }
  }

  public func mapViewWillStartRenderingMap(_ mapView: MKMapView) {
    self.heatmapViewWillStartRenderingMap(mapView)
  }
}

public protocol JDHeatMapDelegate {
  func heatmap(HeatPointCount heatmap : JDHeatMapView) -> Int
  func heatmap(HeatLevelFor index     : Int) -> Int
  func heatmap(RadiusInKMFor index    : Int) -> Double
  func heatmap(CoordinateFor index    : Int) -> CLLocationCoordinate2D
}

extension JDHeatMapDelegate
{
  // the default behaviour for the protocol's heatmap function is to return 1km
  // do not believe this is used in the existing project
  func heatmap(RadiusInKMFor index:Int) -> Double
  {
    return 0.001
  }
}

// this structure contains a co-ordinate, heat level and radius
// all these Heatmap Points together make the Heatmap
struct heatmapPoint2D
{
  var heatLevel   : Int = 0
  var coordinate  : CLLocationCoordinate2D = CLLocationCoordinate2D.init()
  var radiusInKM  : Double = 1

  var midMapPoint : MKMapPoint
  {
    return MKMapPoint.init(self.coordinate)
  }

  var radiusInMKDistance : Double
  {
    let locationDegrees               : CLLocationDegrees = coordinate.latitude
    let metersPerMapPointAtLatitude   : Double            = MKMetersPerMapPointAtLatitude(locationDegrees)
    let kmPerMapPointAtLatitude       : Double            = metersPerMapPointAtLatitude / 1000
    let mapPointsPerKM                : Double            = 1 / kmPerMapPointAtLatitude
    return  radiusInKM * mapPointsPerKM
  }

  var mapRect : MKMapRect
  {
    let origin  : MKMapPoint = MKMapPoint(x: midMapPoint.x - radiusInMKDistance, y: midMapPoint.y - radiusInMKDistance)
    let size    : MKMapSize = MKMapSize(width: 2 * radiusInMKDistance, height: 2 * radiusInMKDistance)
    return      MKMapRect(origin: origin, size: size)
  }

  init()
  {
  }

  init (heatLevel : Int, coordinate : CLLocationCoordinate2D , radiusInKM : Double)
  {
    self.radiusInKM  = radiusInKM
    self.heatLevel   = heatLevel
    self.coordinate  = coordinate
  }


  func distanceTo(another point : heatmapPoint2D) -> CGFloat
  {
    // effectively this uses Pythagorean calculation to get the hypotenuse distance

    let latidiff = (point.coordinate.latitude - self.coordinate.latitude)
    let longdiff = (point.coordinate.longitude - self.coordinate.longitude)
    let squareRoots = sqrt((latidiff * latidiff) + (longdiff * longdiff))
    return CGFloat(squareRoots)
  }


}
