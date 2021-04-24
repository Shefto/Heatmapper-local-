//
//  HeatmapViewController.swift
//  Heatmapper
//
//  Created by Richard English on 24/04/2021.
//  Copyright © 2021 Richard English. All rights reserved.
//

import UIKit
import MapKit

class HeatmapViewController: UIViewController {

  // the view which renders the heatmap over the map
  @IBOutlet weak var mapsView: UIView!

  // Action buttons
  @IBAction func changeToRadiusDistinct(_ sender: Any) {
    heatMap?.setType(type: .RadiusDistinct)
  }

  @IBAction func ChangeToRadiusBlurry(_ sender: Any) {
    heatMap?.setType(type: .RadiusBlurry)
  }

  @IBAction func ChangeToFlatDistinct(_ sender: Any) {
    heatMap?.setType(type: .FlatDistinct)
  }

  // JDHeatmapView is our custom heatmap MapView class
  var heatMap:  JDHeatMapView?

  // this variable sets up an array of coordinates and populates with defaults
  var testCoordinatesArray = [
    CLLocationCoordinate2D(latitude: 27, longitude: 120),
    CLLocationCoordinate2D(latitude: 25.3, longitude: 121),
    CLLocationCoordinate2D(latitude: 27, longitude: 122),
    CLLocationCoordinate2D(latitude: 28, longitude: 119)
  ]

  var heatmapperCoordinatesArray = LocationManager.sharedInstance.locationDataAsCoordinates
    //    [
    //    CLLocationCoordinate2D(latitude: 51.41449267515113, longitude: -0.19706784747559303),
    //    CLLocationCoordinate2D(latitude: 51.41439037402292, longitude: -0.1968835294248507),
    //    CLLocationCoordinate2D(latitude: 51.41439037402325, longitude: -0.19688352942485077)
    //  ]

    // Collingwood rec
    //  [CLLocationCoordinate2D(latitude: 51.369115553082786, longitude: -0.2035283603596845), CLLocationCoordinate2D(latitude: 51.369115553082786, longitude: -0.2035283603596845), CLLocationCoordinate2D(latitude: 51.3694253852119, longitude: -0.20259317592378315), CLLocationCoordinate2D(latitude: 51.367907859432854, longitude: -0.20479847677071095), CLLocationCoordinate2D(latitude: 51.368035222451546, longitude: -0.20441433414835894), CLLocationCoordinate2D(latitude: 51.368345017592766, longitude: -0.20350003615040657), CLLocationCoordinate2D(latitude: 51.36847418272064, longitude: -0.20328143611569263)]

    //Apple test data
//    [CLLocationCoordinate2D(latitude: 37.33178632, longitude: -122.0306262), CLLocationCoordinate2D(latitude: 37.33178632, longitude: -122.0306262), CLLocationCoordinate2D(latitude: 37.33176143, longitude: -122.03066394), CLLocationCoordinate2D(latitude: 37.33172861, longitude: -122.03068446), CLLocationCoordinate2D(latitude: 37.33169352, longitude: -122.03069244), CLLocationCoordinate2D(latitude: 37.33165776, longitude: -122.03069996), CLLocationCoordinate2D(latitude: 37.33162007, longitude: -122.03070577), CLLocationCoordinate2D(latitude: 37.33158231, longitude: -122.03070604), CLLocationCoordinate2D(latitude: 37.33154229, longitude: -122.03071488), CLLocationCoordinate2D(latitude: 37.33150351, longitude: -122.03071596), CLLocationCoordinate2D(latitude: 37.3314643, longitude: -122.03072069), CLLocationCoordinate2D(latitude: 37.33142585, longitude: -122.03072774), CLLocationCoordinate2D(latitude: 37.33138836, longitude: -122.03072798), CLLocationCoordinate2D(latitude: 37.33135095, longitude: -122.03073463), CLLocationCoordinate2D(latitude: 37.33131509, longitude: -122.03073779), CLLocationCoordinate2D(latitude: 37.33128013, longitude: -122.03073774), CLLocationCoordinate2D(latitude: 37.33124551, longitude: -122.03073664), CLLocationCoordinate2D(latitude: 37.33121136, longitude: -122.03073097), CLLocationCoordinate2D(latitude: 37.33117775, longitude: -122.03072292), CLLocationCoordinate2D(latitude: 37.33114614, longitude: -122.03071071), CLLocationCoordinate2D(latitude: 37.3311133, longitude: -122.03069859), CLLocationCoordinate2D(latitude: 37.33108059, longitude: -122.03068245), CLLocationCoordinate2D(latitude: 37.33104629, longitude: -122.03067027), CLLocationCoordinate2D(latitude: 37.33101308, longitude: -122.03065487), CLLocationCoordinate2D(latitude: 37.33097983, longitude: -122.03063943), CLLocationCoordinate2D(latitude: 37.33094637, longitude: -122.0306305), CLLocationCoordinate2D(latitude: 37.33091383, longitude: -122.03061321), CLLocationCoordinate2D(latitude: 37.33087803, longitude: -122.0305999)]


  override func viewDidLoad() {
    super.viewDidLoad()
    //    addRandomData()

    // sets the heatmap frame to the size of the view and specifies the map type
    heatMap = JDHeatMapView(frame: mapsView.frame, delegate: self, mapType: .FlatDistinct)

    // set this VC as the delegate of the JDSwiftHeatMapView
    heatMap?.delegate = self
    // add the JDSwiftHeatMapView to the UI
    mapsView.addSubview(heatMap!)
  }

  // this function simply creates random test data
  func addRandomData()
  {
    for _ in 0..<20
    {
      // generate random longitude and latitude
      let longitude     : Double = Double(119) + Double(Float(arc4random()) / Float(UINT32_MAX))
      let latitude      : Double = Double(25 + arc4random_uniform(4)) + 2 * Double(Float(arc4random()) / Float(UINT32_MAX))
      testCoordinatesArray.append(CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
    }
    print("test data: \(testCoordinatesArray)")
  }
}

// these functions included as delegate of MKMapView
extension HeatmapViewController: MKMapViewDelegate
{
  // returns the renderer from the MKMapView and overlay passed in
  func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
    if let heatmapOverlay = heatMap?.heatmapView(mapView, rendererFor: overlay)
    {
      return heatmapOverlay
    }
    else
    {
      return MKOverlayRenderer()
    }
  }

  func mapViewWillStartRenderingMap(_ mapView: MKMapView) {
    heatMap?.heatmapViewWillStartRenderingMap(mapView)
  }
}

// these functions required as delegate of JDHeatMap
extension HeatmapViewController: JDHeatMapDelegate
{
  func heatmap(HeatPointCount heatmap:JDHeatMapView) -> Int
  {
    return heatmapperCoordinatesArray.count
  }

  func heatmap(HeatLevelFor index:Int) -> Int
  {
    return 1 + index
  }

  // this sets the radius - key to sizing the heatmap
  func heatmap(RadiusInKMFor: Int) -> Double {
    return 0.001
    //    return Double(1 + RadiusInKMFor * 2)
  }

  func heatmap(CoordinateFor index:Int) -> CLLocationCoordinate2D
  {
    return heatmapperCoordinatesArray[index]
  }
}
