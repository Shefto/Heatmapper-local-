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
  var builder: HKWorkoutBuilder!
  var routeBuilder: HKWorkoutRouteBuilder!
  var workoutEventArray: [HKWorkoutEvent] = []

  var distanceSampleArray: [HKSample] = []
  var activeEnergySampleArray: [HKSample] = []
  var basalEnergySampleArray: [HKSample] = []
  var sampleArray: [HKSample] = []


  let logger = Logger(subsystem: "com.wimbledonappcompany.Heatmapper", category: "TrackerViewController")


  override func viewDidLoad() {
    super.viewDidLoad()

    // create HealthKit workout and builder
    workoutConfiguration.activityType = .soccer
    workoutConfiguration.locationType = .outdoor

    builder = HKWorkoutBuilder(healthStore: healthStore, configuration: workoutConfiguration, device: .local())
    routeBuilder = HKWorkoutRouteBuilder(healthStore: healthStore, device: nil)
    // call function to start collecting workout data
    beginCollection()

    // set up map view UI elements
    self.mapView.delegate = self
    self.mapView.showsUserLocation = false
    self.userAnnotationImage = UIImage(named: "user_position_ball")!
    self.accuracyRangeCircle = MKCircle(center: CLLocationCoordinate2D.init(latitude: 41.887, longitude: -87.622), radius: 50)
    self.mapView.addOverlay(self.accuracyRangeCircle!)
    self.didInitialZoom = false

    NotificationCenter.default.addObserver(self, selector: #selector(updateMap(notification:)), name: Notification.Name(rawValue:"didUpdateLocation"), object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(showTurnOnLocationServiceAlert(notification:)), name: Notification.Name(rawValue:"showTurnOnLocationServiceAlert"), object: nil)
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
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

  @objc func updateMap(notification: NSNotification){
    if let userInfo = notification.userInfo{

      updatePolylines()

      if let newLocation = userInfo["location"] as? CLLocation{
        zoomTo(location: newLocation)
      }

    }
  }


  func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {

    if overlay === self.accuracyRangeCircle{
      let circleRenderer = MKCircleRenderer(circle: overlay as! MKCircle)
      circleRenderer.fillColor = UIColor(white: 0.0, alpha: 0.25)
      circleRenderer.lineWidth = 0
      return circleRenderer
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

  @IBAction func filterSwitchAction(_ sender: UISwitch) {
    if sender.isOn{
      LocationManager.sharedInstance.useFilter = true
    }else{
      LocationManager.sharedInstance.useFilter = false
    }
  }

  @IBAction func btnStop(_ sender: Any) {


    endWorkout()

  }


  func endWorkout() {

    MyFunc.logMessage(.debug, "btnStop pressed")
    self.navigationItem.hidesBackButton = false
    LocationManager.sharedInstance.stopUpdatingLocation()

    // if workout was running or is paused, stop and then save workout
    // (otherwise workout will be cancelled)
    //    if fartlekTimer.isRunning  || workoutStatus == .paused {

    // if auto-detection is on, record the final interval
    //      workoutEndDate = Date()
    //      workoutStatus = .stopped
    //      fartlekTimer.stop()
    //      intervalTimer.invalidate()
    //      let finishPhraseLocalized = NSLocalizedString("Finishing workout", comment: "")
    //      audio.speak(phrase: finishPhraseLocalized)

    // remove any pauses from the workout total
    //      let pausedTotal = self.workoutPausedTotal ?? 0
    //
    //      let workoutEndMinusPauses = Date(timeInterval: -(pausedTotal), since: workoutEndDate!)
    //      workoutDurationDateInterval = DateInterval(start: workoutStartDate!, end: workoutEndMinusPauses)


    // get average pace and distance for entire Workout
    // code below from FIT deleted

    // get the full workout Duration
    //      if workoutStartDate! >= workoutEndMinusPauses {
    //        MyFunc.logMessage(.critical, "Error setting workoutDurationDateInterval: wsd: \(self.workoutStartDate! as NSObject), wed: \(self.workoutEndDate! as NSObject)")
    //      }
    //      let workoutDurationTimeInterval = workoutDurationDateInterval?.duration
    //      let workoutDurationStr = workoutDurationTimeInterval!.toReadableString()


    // add each Sample Array to the Workout
    //      addSamplesToWorkout(sampleArray: activeEnergySampleArray)
    //      addSamplesToWorkout(sampleArray: distanceSampleArray)
    //      addSamplesToWorkout(sampleArray: basalEnergySampleArray)

    // create Workout Events for each Interval
    //      for fartlek in 0..<fartlekArray.count {
    //        let fartlekInterval = fartlekArray[fartlek]
    //
    //        let workoutEvent = HKWorkoutEvent(type: HKWorkoutEventType.segment, dateInterval: fartlekInterval.duration!, metadata: ["Type": fartlekInterval.activity])
    //        workoutEventArray.append(workoutEvent)
    //      }

    // add the Workout Events to the Workout
    //    self.builder.addWorkoutEvents(self.workoutEventArray, completion: {(success, error) in
    //
    //      guard success == true else {
    //        MyFunc.logMessage(.debug, "Error appending workout event to array: \(String(describing: error))")
    //        return
    //      }
    //      MyFunc.logMessage(.debug, "Events added to Workout:")
    //      MyFunc.logMessage(.debug, String(describing: self.workoutEventArray))

    // end Workout Builder data collection
    self.builder.endCollection(withEnd: Date(), completion: { (success, error) in
      guard success else {
        MyFunc.logMessage(.error, "Error ending Workout Builder data collection: \(String(describing: error))")
        return
      }

      // save the Workout
      self.builder.finishWorkout { [self] (savedWorkout, error) in

        guard savedWorkout != nil else {
          MyFunc.logMessage(.error, "Failed to save Workout with error : \(String(describing: error))")
          return
        }

        MyFunc.logMessage(.debug, "Workout saved successfully:")
        MyFunc.logMessage(.debug, String(describing: savedWorkout))

        // save the Workout Route
        routeBuilder.finishRoute(with: savedWorkout!, metadata: ["Activity Type": "Fartleks"]) {(workoutRoute, error) in
          guard workoutRoute != nil else {
            MyFunc.logMessage(.error, "Failed to save Workout Route with error : \(String(describing: error))")
            return
          }

          MyFunc.logMessage(.info, "Workout Route saved successfully:")
          MyFunc.logMessage(.info, String(describing: workoutRoute))
          MyFunc.logMessage(.info, "Saved Events: \(String(describing: savedWorkout?.workoutEvents))")
          exportLog()

        } // self.routeBuilder

      } // self.builder.finishWorkout

    }) // self.builder.endCollection

    //    }) // self.builder.addWorkoutEvents
    let completedTitle = NSLocalizedString("Workout completed", comment: "")
    let completedMessage = NSLocalizedString("Your workout has been saved successfully", comment: "")
    displayAlert(title: completedTitle, message: completedMessage)

    self.navigationItem.hidesBackButton = false
  } // endWorkout


  func exportLog() {

    let fileDateFormatter = DateFormatter()
    var log: String = ""

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
    //    if workoutStatus != .cancelled {
    //      alert.addAction(healthAction)
    //    }
    present(alert, animated: true, completion: nil)

  }


  func beginCollection() {
    // begin collecting Workout data
    self.builder.beginCollection(withStart: Date(), completion: { (success, error) in
      guard success else {
        MyFunc.logMessage(.error, "Error beginning data collection in Workout Builder: \(String(describing: error))")
        return
      }

    })

  }

}
