//
//  REHeatmapViewController.swift
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

class REHeatmapViewController: UIViewController {

  var reHeatmapOverlay            = REHeatmapOverlay()

  var dtmHeatmap                  = DTMHeatmap()
  var heatmapperCoordinatesArray  = [CLLocationCoordinate2D]()
  var heatmapperLocationsArray    = [CLLocation]()
  var heatmapWorkoutId            : UUID?
  var pointCount                  : Int = 0


  let healthstore = HKHealthStore()

  @IBAction func tapGesture(_ sender: UITapGestureRecognizer) {
    if sender.state == .ended {
      let tapGestureEndedLocation = sender.location(in: mapView)
      print("tapGestureEndedLocation: \(tapGestureEndedLocation)")
      let tappedCoordinate = mapView.convert(tapGestureEndedLocation, toCoordinateFrom: mapView)
      //      addAnnotation(coordinate: tappedCoordinate)
      pointCount += 1

      if pointCount == 2 {

        print("pointCount = 2 - time to insert the overlay")

      }
    }
  }

  @IBOutlet weak var mapView: MKMapView!

  override func viewDidLoad() {
    super.viewDidLoad()

    self.mapView.delegate = self

    // start getting workout data before anything else - this will take time
    getWorkoutData()

    MyFunc.logMessage(.debug, "REHeatmapViewController.viewdidLoad")
    MyFunc.logMessage(.debug, "heatmapperCoordinatesArray:")
    MyFunc.logMessage(.debug, String(describing: heatmapperCoordinatesArray))

    //    setMapViewCentre()

    //    setMapViewZoom()

  }

  func setMapViewZoom(rect: MKMapRect) {
    let insets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    //    let insets = UIEdgeInsets(top: 50, left: 50, bottom: 50, right: 50)

    mapView.setVisibleMapRect(rect, edgePadding: insets, animated: true)
//    mapView.userTrackingMode = .follow

  }

  func createREHeatmap() {

    // create an array of Heatmap points based upon the coordinates mapped
    var heatmapPointsArray = [REHeatmapPoint]()

    let heatmapMKPointsArray = heatmapperCoordinatesArray.map {MKMapPoint($0)}
    heatmapPointsArray = heatmapMKPointsArray.map { REHeatmapPoint.init(mapPoint: $0, radius: 0, heatLevel: 0.0) }

    let minX = heatmapMKPointsArray.map {$0.x}.min()
    let maxX = heatmapMKPointsArray.map {$0.x}.max()
    let minY = heatmapMKPointsArray.map {$0.y}.min()
    let maxY = heatmapMKPointsArray.map {$0.y}.max()

    MyFunc.logMessage(.debug, "minX: \(String(describing: minX))")
    MyFunc.logMessage(.debug, "maxX: \(String(describing: maxX))")
    MyFunc.logMessage(.debug, "minY: \(String(describing: minY))")
    MyFunc.logMessage(.debug, "maxY: \(String(describing: maxY))")

    // this rectangle covers the area of all points
    let rect = MKMapRect.init(x: minX!, y: minY!, width: maxX! - minX!, height: maxY! - minY!)

    // next create an overlay of the pitch based upon the rectangle

    // get the array of heatmap cells based upon the co-ordinates passed in
    let heatmapCellArray = reHeatmapOverlay.setData(reHeatmapPointArray: heatmapPointsArray)
    MyFunc.logMessage(.debug, "heatmapCellArray")
    MyFunc.logMessage(.debug, String(describing: heatmapCellArray))

    let pitch = FootballPitch()
    let footballPitch11Overlay = FootballPitchOverlay(pitchRect: rect)
    self.mapView.addOverlay(footballPitch11Overlay)
    //    let pitchRect = footballPitch11Overlay.boundingMapRect
    self.setMapViewZoom(rect: rect)

  }

  //  commenting this out for now as using user's location as centre - restore when replacing with a drawn map
  //  func setMapViewCentre() {
  //    let currentLocationCoordinate = LocationManager.sharedInstance.currentLocation.coordinate
  //    let region = MKCoordinateRegion(center: currentLocationCoordinate, span: MKCoordinateSpan(latitudeDelta: 10, longitudeDelta: 10))
  //    self.mapView.setRegion(region, animated: true)
  //
  //  }






  //  func addPitchAnnotation(coordinate:CLLocationCoordinate2D){
  //    let annotation = MKPointAnnotation()
  //    annotation.coordinate = coordinate
  //    mapView.addAnnotation(annotation)
  //  }
  //
  //
  //  func addAnnotation(coordinate:CLLocationCoordinate2D){
  //    let annotation = MKPointAnnotation()
  //    annotation.coordinate = coordinate
  //    mapView.addAnnotation(annotation)
  //  }
  //



  // *** WORKOUT CALLS - RESTORE WHEN DATA REQUIRED ***
  //  //MARK: call to get workout data
  func getWorkoutData() {
    MyFunc.logMessage(.debug, "worko«utId: \(String(describing: heatmapWorkoutId))")

    // check Workout Id passed in is valid
    guard let workoutId = heatmapWorkoutId else {
      MyFunc.logMessage(.error, "heatmapWorkoutId is invalid: \(String(describing: heatmapWorkoutId))")
      return
    }

    // get the workout
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

      MyFunc.logMessage(.debug, "Locations retrieved: \(String(describing: locations))")

      let locationsAsCoordinates = locations.map {$0.coordinate}
      MyFunc.logMessage(.debug, "Coordinates retrieved: \(locationsAsCoordinates)")

      self.heatmapperCoordinatesArray.append(contentsOf: locationsAsCoordinates)
      let coordinatesTotal = self.heatmapperCoordinatesArray.count
      MyFunc.logMessage(.debug, "Total coordinates: \(coordinatesTotal)")

      // if done = all data retrieved
      // only at this point can we start to build a heatmap overlay
      if done {

        // dispatch to the main queue as we are making UI updates
        DispatchQueue.main.async {

          self.createREHeatmap()
          // sets the heatmap frame to the size of the view and specifies the map
        }

      }

      // You can stop the query by calling:
      // store.stop(query)

    }
    healthstore.execute(query)
  }


}

extension REHeatmapViewController: MKMapViewDelegate {

  func mapViewDidFinishRenderingMap(_ mapView: MKMapView, fullyRendered: Bool) {
  }

  func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {

    if overlay is FootballPitchOverlay {
      if let pitchImage = UIImage(named: "football pitch 11.png")
      {
        let footballPitchOverlayView = FootballPitchOverlayView(overlay: overlay, overlayImage: pitchImage)
        return footballPitchOverlayView

      }
    }
    return REHeatmapRenderer.init(overlay: overlay)
  }


  func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, didChange newState: MKAnnotationView.DragState, fromOldState oldState: MKAnnotationView.DragState) {
    switch newState {
    case .starting:
      view.dragState = .dragging

    case .ending, .canceling:
      view.dragState = .none
    default: break
    }
  }

  func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
    if annotation is MKUserLocation {
      return nil
    }

    let reuseId = "pin"
    var pinAnnotationView: MKPinAnnotationView? = self.mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
    if pinAnnotationView == nil {
      pinAnnotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
      pinAnnotationView?.isDraggable = true
      pinAnnotationView?.canShowCallout = true
      pinAnnotationView?.pinTintColor = .blue
    } else {
      pinAnnotationView?.annotation = annotation
    }

    return pinAnnotationView
  }

}
