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
import CoreLocation

class HeatmapViewController: UIViewController {

  let healthstore = HKHealthStore()
  // JDHeatmapView is our custom heatmap MapView class
  var jdHeatMapView:  JDHeatMapView?

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
//    jdHeatMapView?.setType(type: .RadiusDistinct)
  }

  @IBAction func ChangeToRadiusBlurry(_ sender: Any) {
//    jdHeatMapView?.setType(type: .RadiusBlurry)
  }

  @IBAction func ChangeToFlatDistinct(_ sender: Any) {
//    jdHeatMapView?.setType(type: .FlatDistinct)
  }


  override func viewDidLoad() {
    super.viewDidLoad()

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


}

// these functions included as delegate of MKMapView
extension HeatmapViewController: MKMapViewDelegate
{
  // returns the renderer from the MKMapView and overlay passed in
  func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
    if let heatmapOverlay = jdHeatMapView?.getMKOverlayRenderer(mapView, rendererFor: overlay)
    {
      return heatmapOverlay
    }
    else
    {
      return MKOverlayRenderer()
    }
  }

  func mapViewWillStartRenderingMap(_ mapView: MKMapView) {
    jdHeatMapView?.heatmapViewWillStartRenderingMap(mapView)
  }
}

// these functions required as delegate of JDHeatMap - called for each point being looped through
extension HeatmapViewController: JDHeatMapDelegate
{
  func heatmap(HeatPointCount heatmap:JDHeatMapView) -> Int
  {
    MyFunc.logMessage(.debug, "Number of coordinates: \(heatmapperCoordinatesArray.count)")
    return heatmapperCoordinatesArray.count

  }

  func heatmap(HeatLevelFor index:Int) -> Int
  {
    return 1 + index
  }

  // this sets the radius for each point - have set this to 1m
  // initial JD code used commented out line - can we restore?
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
        //4. Cast the samples as HKWorkout
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

      // Process updates or additions here.
    }

    healthstore.execute(routeQuery)

  }

  func getRouteLocationData(route: HKWorkoutRoute) {

    let samplesCount = route.count
    MyFunc.logMessage(.debug, "Number of samples: \(samplesCount)")

    // Create the route query.
    let query = HKWorkoutRouteQuery(route: route) { (query, locationsOrNil, done, errorOrNil) in

      // This block may be called multiple times.

      if errorOrNil != nil {
        // Handle any errors here.
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

      // Do something with this batch of location data.
      if done {
        MyFunc.logMessage(.debug, "heatmapperCoordinatesArray: \(String(describing: self.heatmapperCoordinatesArray))")

        DispatchQueue.main.async {
        // sets the heatmap frame to the size of the view and specifies the map type
          guard let workoutId = self.heatmapWorkoutId else {
            MyFunc.logMessage(.error, "No heatmapWorkoutId passed to JDHeatmapViewController")
            return
          }
          self.jdHeatMapView = JDHeatMapView(frame: self.mapsView.frame, delegate: self, mapType: .FlatDistinct, workoutId: workoutId)

        // set this VC as the delegate of the JDSwiftHeatMapView
          self.jdHeatMapView?.delegate = self
        // add the JDSwiftHeatMapView to the UI
          self.mapsView.addSubview(self.jdHeatMapView!)

        }

      }

      // You can stop the query by calling:
      // store.stop(query)

    }
    healthstore.execute(query)
  }


}
