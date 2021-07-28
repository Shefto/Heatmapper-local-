
//  DTMHeatmapViewController.swift
//  Heatmapper
//
//  Created by Richard English on 03/07/2021.
//  Copyright © 2021 Richard English. All rights reserved.
//
//  Heatmap view controller using DTMHeatmap
//

import UIKit
import MapKit
import HealthKit
import CoreLocation
import DTMHeatmap

class DTMHeatmapViewController: UIViewController, MKMapViewDelegate {

  @IBOutlet weak var mapView: MKMapView!
  var dtmHeatmap = DTMHeatmap()
  //  var heatmapperCoordinatesArray = LocationManager.sharedInstance.locationDataAsCoordinates
  var heatmapperCoordinatesArray = [CLLocationCoordinate2D]()
  var heatmapWorkoutId : UUID?

  let healthstore = HKHealthStore()

  override func viewDidLoad() {
    super.viewDidLoad()

    self.mapView.delegate = self

    getWorkoutData()

    setMapViewCentre()

        setMapViewZoom()

  }

  func setMapViewZoom() {
    let insets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    //    let insets = UIEdgeInsets(top: 50, left: 50, bottom: 50, right: 50)
    let heatmapRect = dtmHeatmap.boundingMapRect()

    mapView.setVisibleMapRect(heatmapRect, edgePadding: insets, animated: true)

  }


  func createHeatmap() {

    var heatmapdata:[NSObject: Double] = [:]
    for coordinate in heatmapperCoordinatesArray {
      var point = MKMapPoint.init(coordinate)
      let type = "{MKMapPoint=dd}"
      let value = NSValue(bytes: &point, objCType: type)
      heatmapdata[value] = 1.0
    }

    self.dtmHeatmap.setData(heatmapdata as [NSObject : AnyObject])
    self.mapView.addOverlay(self.dtmHeatmap)

    self.setMapViewZoom()

  }


  func setMapViewCentre() {
    let currentLocationCoordinate = LocationManager.sharedInstance.currentLocation.coordinate
    let region = MKCoordinateRegion(center: currentLocationCoordinate, span: MKCoordinateSpan(latitudeDelta: 10, longitudeDelta: 10))
    self.mapView.setRegion(region, animated: true)

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

        DispatchQueue.main.async {
          self.createHeatmap()
          // sets the heatmap frame to the size of the view and specifies the map
        }

      }

      // You can stop the query by calling:
      // store.stop(query)

    }
    healthstore.execute(query)
  }

  func mapViewDidFinishRenderingMap(_ mapView: MKMapView, fullyRendered: Bool) {
  }

  func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
    return DTMHeatmapRenderer.init(overlay: overlay)
  }

}
