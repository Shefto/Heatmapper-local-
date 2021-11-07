//
//  TrackerViewController.swift
//  Heatmapper
//
//  Created by Richard English on 13/04/2021.
//  Copyright © 2021 Richard English. All rights reserved.
//

import UIKit
import MapKit
import HealthKit
import os

class TrackerViewController: UIViewController, MKMapViewDelegate {

  @IBOutlet var mapView: MKMapView!

  // MapKit variables
  var userAnnotationImage: UIImage?
  var userAnnotation: UserAnnotation?
  var accuracyRangeCircle: MKCircle?
  var polyline: MKPolyline?
  var isZooming: Bool?
  var isBlockingAutoZoom: Bool?
  var zoomBlockingTimer: Timer?
  var didInitialZoom: Bool?

  // HealthKit variables
  private let healthStore         = HKHealthStore()
  let workoutConfiguration        = HKWorkoutConfiguration()
  var builder                     : HKWorkoutBuilder!
  var routeBuilder                : HKWorkoutRouteBuilder!
  var workoutEventArray           : [HKWorkoutEvent] = []

  var distanceSampleArray         : [HKSample] = []
  var activeEnergySampleArray     : [HKSample] = []
  var basalEnergySampleArray      : [HKSample] = []
  var sampleArray                 : [HKSample] = []

//  var heatmapperCoordinatesArray = [CLLocationCoordinate2D]()

  let logger = Logger(subsystem: "com.wimbledonappcompany.Heatmapper", category: "TrackerViewController")


  @IBAction func btnStop(_ sender: Any) {
    endWorkout()
    navigationItem.hidesBackButton = false

  }

  override func viewDidLoad() {
    super.viewDidLoad()

    // create HealthKit workout and builder
    workoutConfiguration.activityType = .running
    workoutConfiguration.locationType = .outdoor

    builder = HKWorkoutBuilder(healthStore: healthStore, configuration: workoutConfiguration, device: .local())
    routeBuilder = HKWorkoutRouteBuilder(healthStore: healthStore, device: nil)

    // call function to start collecting workout data
    beginCollection()

    loadMapUI()

    NotificationCenter.default.addObserver(self, selector: #selector(updateMap(notification:)), name: Notification.Name(rawValue:"didUpdateLocation"), object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(showTurnOnLocationServiceAlert(notification:)), name: Notification.Name(rawValue:"showTurnOnLocationServiceAlert"), object: nil)
  }


  func beginCollection() {
    // begin collecting Workout data
    builder.beginCollection(withStart: Date(), completion: { (success, error) in
      guard success else {
        MyFunc.logMessage(.error, "Error beginning data collection in Workout Builder: \(String(describing: error))")
        return
      }
      MyFunc.logMessage(.debug, "TrackerViewController.builder.beginCollection success: \(success)")
    })
  }

  func loadMapUI() {
    mapView.delegate = self
    mapView.showsUserLocation = false
    userAnnotationImage = UIImage(named: "user_position_ball")!
    accuracyRangeCircle = MKCircle(center: CLLocationCoordinate2D.init(latitude: 41.887, longitude: -87.622), radius: 50)
    mapView.addOverlay(self.accuracyRangeCircle!)
    didInitialZoom = false
  }

  func endWorkout() {

    LocationManager.sharedInstance.stopUpdatingLocation()

    // end Workout Builder data collection
    self.builder.endCollection(withEnd: Date(), completion: { (success, error) in
      guard success else {
        MyFunc.logMessage(.error, "TrackerViewController.builder.endCollection error: \(String(describing: error))")
        return
      }

      // save the Workout
      self.builder.finishWorkout { [self] (savedWorkout, error) in

        guard savedWorkout != nil else {
          MyFunc.logMessage(.error, "TrackerViewController.builder.finishWorkout error: \(String(describing: error))")
          return
        }

        MyFunc.logMessage(.info, "Workout saved successfully:")
        MyFunc.logMessage(.info, String(describing: savedWorkout))

        // insert the route data from the Location array
        routeBuilder.insertRouteData(LocationManager.sharedInstance.locationDataArray) { (success, error) in
          if !success {
            MyFunc.logMessage(.error, "TrackerViewController.insertRouteData.finishWorkout error: \(String(describing: error))")
          }

          MyFunc.logMessage(.debug, "TrackerViewController.insertRouteData.finishWorkout success: \(String(describing: success))")

          // save the Workout Route
          routeBuilder.finishRoute(with: savedWorkout!, metadata: ["Activity Type": "Heatmapper"]) {(workoutRoute, error) in
            guard workoutRoute != nil else {
              MyFunc.logMessage(.error, "Failed to save Workout Route with error : \(String(describing: error))")
              return
            }

            MyFunc.logMessage(.info, "Workout Route saved successfully:")
            MyFunc.logMessage(.info, String(describing: workoutRoute))
            MyFunc.logMessage(.info, "Saved Events: \(String(describing: savedWorkout?.workoutEvents))")

            self.getRouteSampleObject(workout: savedWorkout!)


            exportLog()

          } // finishRoute

        } // insertRouteData

      } // finishWorkout

    }) // endCollection


    let completedTitle = NSLocalizedString("Workout completed", comment: "")
    let completedMessage = NSLocalizedString("Your workout has been saved successfully", comment: "")
    displayAlert(title: completedTitle, message: completedMessage)

    self.navigationItem.hidesBackButton = false
  } // endWorkout


  func exportLog() {

    let fileDateFormatter = DateFormatter()
    var log : String = ""

    // generate filename including timestamp
    let currDate = fileDateFormatter.string(from: Date())
    let fileName = "FiT_Log_" + currDate + ".txt"

    guard let path = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent(fileName) as NSURL else {
      return }

    do {
      try log.write(to: path as URL, atomically: true, encoding: String.Encoding.utf8)
      MyFunc.logMessage(.info, "Log data written to \(path)")
    } catch {
      MyFunc.logMessage(.error, "Failed to create file with error \(String(describing: error))")
    } // catch

  }


  func displayAlert (title: String, message: String) {

    //Alert user that Save has worked
    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
    let okAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: {(_: UIAlertAction!) in
      //      if MyFunc.removeAdsPurchased() == false {
      //        if self.interstitial.isReady {
      //          self.interstitial.present(fromRootViewController: self)
      //
      //        } else {
      //          MyFunc.logMessage(.debug, "Ad wasn't ready")
      //        }
      //      }
    })
    let healthActionTitle = NSLocalizedString("Open Health app", comment: "Open Health app")
    let healthAction = UIAlertAction(title: healthActionTitle,
                                     style: UIAlertAction.Style.default,
                                     handler: {(_: UIAlertAction!) in
                                      // open HealthKit app - note current URL only opens the app at root or where previous session was
                                      MyFunciOS.openUrl(urlString: "x-apple-health:root&path=BROWSE")
                                     })
    alert.addAction(okAction)

    alert.addAction(healthAction)

    present(alert, animated: true, completion: nil)

  }


  @objc func showTurnOnLocationServiceAlert(notification: NSNotification){
    let alert = UIAlertController(title: "Turn on Location Service", message: "To use location tracking feature of the app, please turn on the location service from the Settings app.", preferredStyle: .alert)

    let settingsAction = UIAlertAction(title: "Settings", style: .default) { (_) -> Void in
      let settingsUrl = URL(string: UIApplication.openSettingsURLString)
      if let url = settingsUrl {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
      }
    }

    let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil)
    alert.addAction(settingsAction)
    alert.addAction(cancelAction)
    present(alert, animated: true, completion: nil)
  }

  //MARK: Map functions
  func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {

    if overlay === self.accuracyRangeCircle {
      let circleRenderer = HeatmapPointCircleRenderer(circle: overlay as! MKCircle)
      return circleRenderer


//      let circleRenderer = MKCircleRenderer(circle: overlay as! MKCircle)
////      circleRenderer.fillColor = UIColor(white: 0.0, alpha: 0.25)
//      circleRenderer.fillColor = UIColor.brown
//
//      let gradientColour = CAGradientLayer()
//      gradientColour.type = .radial
//      gradientColour.colors = [UIColor.black, UIColor.clear]
//      gradientColour.startPoint
//      circleRenderer.fillColor = gradientColour
//
//      circleRenderer.lineWidth = 0
//      return circleRenderer
    }else{
      let polylineRenderer = MKPolylineRenderer(polyline: overlay as! MKPolyline)
      polylineRenderer.strokeColor = UIColor(rgb:0x1b60fe)
      polylineRenderer.alpha = 0.5
      polylineRenderer.lineWidth = 5.0
      return polylineRenderer
    }
  }

  func updatePolylines(){
    var coordinateArray = [CLLocationCoordinate2D]()

    for loc in LocationManager.sharedInstance.locationDataArray{
      coordinateArray.append(loc.coordinate)
    }

    self.clearPolyline()
    self.polyline = MKPolyline(coordinates: coordinateArray, count: coordinateArray.count)
    self.mapView.addOverlay(polyline!)

  }

  func clearPolyline(){
    if self.polyline != nil{
      self.mapView.removeOverlay(self.polyline!)
      self.polyline = nil
    }
  }

  func zoomTo(location: CLLocation){
    if self.didInitialZoom == false{
      let coordinate = location.coordinate
      let region = MKCoordinateRegion.init(center: coordinate, latitudinalMeters: 300, longitudinalMeters: 300)
      self.mapView.setRegion(region, animated: false)
      self.didInitialZoom = true
    }

    if self.isBlockingAutoZoom == false{
      self.isZooming = true
      self.mapView.setCenter(location.coordinate, animated: true)
    }

    var accuracyRadius = 50.0
    if location.horizontalAccuracy > 0{
      if location.horizontalAccuracy > accuracyRadius{
        accuracyRadius = location.horizontalAccuracy
      }
    }

    self.mapView.removeOverlay(self.accuracyRangeCircle!)
    self.accuracyRangeCircle = MKCircle(center: location.coordinate, radius: accuracyRadius as CLLocationDistance)
    self.mapView.addOverlay(self.accuracyRangeCircle!)

    if self.userAnnotation != nil{
      self.mapView.removeAnnotation(self.userAnnotation!)
    }

    self.userAnnotation = UserAnnotation(coordinate: location.coordinate, title: "", subtitle: "")
    self.mapView.addAnnotation(self.userAnnotation!)
  }

  func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
    if annotation is MKUserLocation{
      return nil
    }else{
      let identifier = "UserAnnotation"
      var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
      if annotationView != nil{
        annotationView!.annotation = annotation
      }else{
        annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
      }
      annotationView!.canShowCallout = false
      annotationView!.image = self.userAnnotationImage

      return annotationView
    }
  }

  func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
    if self.isZooming == true{
      self.isZooming = false
      self.isBlockingAutoZoom = false
    }else{
      self.isBlockingAutoZoom = true
      if let timer = self.zoomBlockingTimer{
        if timer.isValid{
          timer.invalidate()
        }
      }
      self.zoomBlockingTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false, block: { (Timer) in
        self.zoomBlockingTimer = nil
        self.isBlockingAutoZoom = false;
      })
    }
  }

  @objc func updateMap(notification: NSNotification){
    if let userInfo = notification.userInfo{
      updatePolylines()
      if let newLocation = userInfo["location"] as? CLLocation{
        zoomTo(location: newLocation)
      }
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

    healthStore.execute(query)

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

    healthStore.execute(routeQuery)

  }

  func getRouteLocationData(route: HKWorkoutRoute) {

    // Create the route query.
    let query = HKWorkoutRouteQuery(route: route) { (query, locationsOrNil, done, errorOrNil) in

      // This block may be called multiple times.

      if errorOrNil != nil {
        // Handle any errors here.
        return
      }

      guard let locations = locationsOrNil else {
        fatalError("*** Invalid State: This can only fail if there was an error. ***")
      }

      // Do something with this batch of location data.
      if done {
        MyFunc.logMessage(.debug, "Workout Location Data: \(String(describing: locations))")
        let locationsAsCoordinates = locations.map {$0.coordinate}
        MyFunc.logMessage(.debug, "locationsAsCoordinates: \(String(describing: locationsAsCoordinates))")
//        heatmapperCoordinatesArray = locationsAsCoordinates
//        MyFunc.logMessage(.debug, "heatmapperCoordinatesArray: \(String(describing: heatmapperCoordinatesArray))")
//        MyFunc.logMessage(.debug, "Number of coordinates: \(heatmapperCoordinatesArray.count)")

        // add JDHeatmap generation code here


      }

      // You can stop the query by calling:
      // store.stop(query)

    }
    healthStore.execute(query)
  }




}
