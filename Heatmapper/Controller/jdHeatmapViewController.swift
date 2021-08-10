//
//  jdHeatmapViewController.swift
//  Heatmapper
//
//  Created by Richard English on 24/07/2021.
//  Copyright © 2021 Richard English. All rights reserved.
//



import UIKit
import MapKit
import HealthKit
import CoreLocation

class jdHeatmapViewController: UIViewController {

  let healthstore = HKHealthStore()
  // JDHeatmapView is our custom heatmap MapView class
  var heatMap:  JDHeatMapView?

  //  var heatmapperCoordinatesArray = LocationManager.sharedInstance.locationDataAsCoordinates
  var heatmapperCoordinatesArray = [CLLocationCoordinate2D]()
  var heatmapWorkoutId : UUID?


  // the view which renders the heatmap over the map
  @IBOutlet weak var mapsView: UIView!

  // Action buttons
  @IBAction func changeToRadiusDistinct(_ sender: Any) {
    guard let workoutId = heatmapWorkoutId else {
      MyFunc.logMessage(.error, "No heatmapWorkoutId passed to JDHeatmapViewController")
      return
    }
    heatMap?.setType(type: .RadiusDistinct, workoutId: workoutId)
  }

  @IBAction func ChangeToRadiusBlurry(_ sender: Any) {
    guard let workoutId = heatmapWorkoutId else {
      MyFunc.logMessage(.error, "No heatmapWorkoutId passed to JDHeatmapViewController")
      return
    }
    heatMap?.setType(type: .RadiusBlurry, workoutId: workoutId)
  }

  @IBAction func ChangeToFlatDistinct(_ sender: Any) {
    guard let workoutId = heatmapWorkoutId else {
      MyFunc.logMessage(.error, "No heatmapWorkoutId passed to JDHeatmapViewController")
      return
    }
    heatMap?.setType(type: .FlatDistinct, workoutId: workoutId)
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    heatmapperCoordinatesArray.removeAll()
    getWorkoutData()


  }

  func createHeatmap() {

    guard let workoutId = heatmapWorkoutId else {
      MyFunc.logMessage(.error, "No heatmapWorkoutId passed to JDHeatmapViewController")
      return
    }
    // sets the heatmap frame to the size of the view and specifies the map type
    heatMap = JDHeatMapView(frame: mapsView.frame, delegate: self, mapType: .FlatDistinct, workoutId: workoutId)

    // set this VC as the delegate of the JDSwiftHeatMapView
    heatMap?.delegate = self

    mapsView.addSubview(heatMap!)

  }

  func getWorkoutData() {

    MyFunc.logMessage(.debug, "workoutId: \(String(describing: heatmapWorkoutId))")
    // get the route data for the heatmap

    guard let workoutId = heatmapWorkoutId else {
      MyFunc.logMessage(.error, "heatmapWorkoutId is invalid: \(String(describing: heatmapWorkoutId))")
      return
    }

    getWorkout(workoutId: workoutId) { [self] (workouts, error) in
      let workoutReturned = workouts?.first
      MyFunc.logMessage(.debug, "workoutReturned:")
      MyFunc.logMessage(.debug, String(describing: workoutReturned))

      guard let workout : HKWorkout = workoutReturned else {
        MyFunc.logMessage(.debug, "workoutReturned invalid: \(String(describing: workoutReturned))")
        return
      }

      self.getRouteSampleObject(workout: workout)

    }

  }

  func getWorkout(workoutId: UUID, completion:
                    @escaping ([HKWorkout]?, Error?) -> Void) {

    let predicate = HKQuery.predicateForObject(with: workoutId)

    let query = HKSampleQuery(
      sampleType: .workoutType(),
      predicate: predicate,
      limit: 0,
      sortDescriptors: nil
    )
    { (query, results, error) in
      DispatchQueue.main.async {
        // cast the samples as HKWorkout
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


  func getRouteSampleObject(workout: HKWorkout) {

    let runningObjectQuery = HKQuery.predicateForObjects(from: workout)

    let routeQuery = HKAnchoredObjectQuery(type: HKSeriesType.workoutRoute(), predicate: runningObjectQuery, anchor: nil, limit: HKObjectQueryNoLimit) { (query, samples, deletedObjects, anchor, error) in

      guard error == nil else {
        // Handle any errors here.
        fatalError("The initial query failed.")
      }

      // Process the initial route data here.
      MyFunc.logMessage(.debug, "routeQuery returned samples:")
      MyFunc.logMessage(.debug, String(describing: samples))

      DispatchQueue.main.async {
        // cast the samples as HKWorkout
        guard
          let routeSamples = samples as? [HKWorkoutRoute],
          error == nil
        else {
          return
        }
        MyFunc.logMessage(.debug, "routeSamples:")
        MyFunc.logMessage(.debug, String(describing: routeSamples))
        guard let routeReturned = samples?.first as? HKWorkoutRoute else {
          MyFunc.logMessage(.debug, "Could not convert routeSamples to HKWorkoutRoute")
          return
        }
        self.getRouteLocationData(route: routeReturned)

      }

    }

    routeQuery.updateHandler = { (query, samples, deleted, anchor, error) in
      guard error == nil else {
        // Handle any errors here.
        fatalError("The update failed.")
      }
    }

    healthstore.execute(routeQuery)
  }

  func getRouteLocationData(route: HKWorkoutRoute) {

    let samplesCount = route.count
    MyFunc.logMessage(.debug, "Number of samples: \(samplesCount)")

    // Create the route query
    let query = HKWorkoutRouteQuery(route: route) { [self] (query, locationsOrNil, done, errorOrNil) in

      // This block may be called multiple times
      if errorOrNil != nil {
        MyFunc.logMessage(.debug, "Error retrieving workout locations")
        return
      }

      guard let locations = locationsOrNil else {
        fatalError("*** Invalid State: This can only fail if there was an error. ***")
      }

      MyFunc.logMessage(.debug, "Workout Location Data: \(String(describing: locations))")
      let locationsAsCoordinates = locations.map {$0.coordinate}
      MyFunc.logMessage(.debug, "Locations retrieved: \(locationsAsCoordinates)")

      self.heatmapperCoordinatesArray.append(contentsOf: locationsAsCoordinates)
      let coordinatesTotal = self.heatmapperCoordinatesArray.count
      MyFunc.logMessage(.debug, "Heatmapper Array count: \(coordinatesTotal)")

      // if all data retrieved, status = done so we can process it
      if done {

        // UI work so dispatch to the main queue
        DispatchQueue.main.async {
          self.createHeatmap()
        }

      }

    }
    healthstore.execute(query)
  }




}

// these functions included as delegate of MKMapView
extension jdHeatmapViewController: MKMapViewDelegate
{
  // returns the renderer from the MKMapView and overlay passed in
  func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
    if let heatmapOverlay = heatMap?.getMKOverlayRenderer(mapView, rendererFor: overlay)
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
extension jdHeatmapViewController: JDHeatMapDelegate
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

