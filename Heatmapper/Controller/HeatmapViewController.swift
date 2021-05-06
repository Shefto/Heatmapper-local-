//
//  HeatmapViewController.swift
//  Heatmapper
//
//  Created by Richard English on 24/04/2021.
//  Copyright © 2021 Richard English. All rights reserved.
//

import UIKit
import MapKit
import HealthKit

class HeatmapViewController: UIViewController {

  let healthstore = HKHealthStore()
  // JDHeatmapView is our custom heatmap MapView class
  var heatMap:  JDHeatMapView?

  // this variable sets up an array of coordinates and populates with defaults
  var testCoordinatesArray = [
    CLLocationCoordinate2D(latitude: 27, longitude: 120),
    CLLocationCoordinate2D(latitude: 25.3, longitude: 121),
    CLLocationCoordinate2D(latitude: 27, longitude: 122),
    CLLocationCoordinate2D(latitude: 28, longitude: 119)
  ]

  //  var heatmapperCoordinatesArray = LocationManager.sharedInstance.locationDataAsCoordinates
  var heatmapperCoordinatesArray = [CLLocationCoordinate2D]()
  var heatmapWorkoutId : UUID?


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


  override func viewDidLoad() {
    super.viewDidLoad()

    MyFunc.logMessage(.debug, "workoutId: \(String(describing: heatmapWorkoutId))")
    // get the route data for the heatmap

    guard let workoutId = heatmapWorkoutId else {
      MyFunc.logMessage(.error, "heatmapWorkoutId is invalid: \(String(describing: heatmapWorkoutId))")
      return
    }

    var workout : HKWorkout?
    getWorkout(workoutId: workoutId) { (workouts, error) in
      let workoutReturned = workouts?.first
      MyFunc.logMessage(.debug, "workoutReturned:")
      MyFunc.logMessage(.debug, String(describing: workoutReturned))
      workout = workoutReturned
    }
    MyFunc.logMessage(.debug, "Workouts:")

    MyFunc.logMessage(.debug, String(describing: workout))






//        addRandomData()

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



  func getWorkout(workoutId: UUID, completion:
                      @escaping ([HKWorkout]?, Error?) -> Void) {

    let predicate = HKQuery.predicateForObject(with: workoutId)
//    let explicitUUID = NSPredicate(format: "%K == %@", HKPredicateKeyPathUUID, uuid)

    let query = HKSampleQuery(
      sampleType: .workoutType(),
      predicate: predicate,
      limit: 0,
      sortDescriptors: nil
    )
    { (query, results, error) in
      DispatchQueue.main.async {
        //4. Cast the samples as HKWorkout
        guard
          let samples = results as? [HKWorkout],
          error == nil
        else {
          completion(nil, error)
          return
        }

        completion(samples, nil)
      }
    }

    healthstore.execute(query)

  }

  
}
