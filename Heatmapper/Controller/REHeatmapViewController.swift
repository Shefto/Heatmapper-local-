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
  var angle                       : CGFloat = 0.0
  var pointsDistance              : CGFloat = 0.0
  var dtmRect                     = MKMapRect()

  var heatmapPointCircle          : MKCircle?
  var reHeatmapPoint              : REHeatmapPoint?
  var reHeatmapPointImage         : UIImage?

  let healthstore                 = HKHealthStore()

  // this gesture created to enable user to tap points on which the overlay size will be based
  // not currently in use
  @IBAction func tapGesture(_ sender: UITapGestureRecognizer) {
    if sender.state == .ended {
      let tapGestureEndedLocation = sender.location(in: mapView)
      print("tapGestureEndedLocation: \(tapGestureEndedLocation)")
//      let tappedCoordinate = mapView.convert(tapGestureEndedLocation, toCoordinateFrom: mapView)
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
    reHeatmapPointImage = UIImage(systemName: "circle.fill")

    // get workout data
    // all UI work is called within the function as the data retrieval works asynchronously
    getWorkoutData()

//    MyFunc.logMessage(.debug, "heatmapperCoordinatesArray:")
//    MyFunc.logMessage(.debug, String(describing: heatmapperCoordinatesArray))



  }

  func setMapViewZoom(rect: MKMapRect) {
    let insets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
    //    let insets = UIEdgeInsets(top: 50, left: 50, bottom: 50, right: 50)

    mapView.setVisibleMapRect(rect, edgePadding: insets, animated: true)

  }

  func createREHeatmap() {

    for heatmapperCoordinate in heatmapperCoordinatesArray {
      addHeatmapPoint(coordinate: heatmapperCoordinate)
    }

  }


  func createPitchOverlay() {

    // get the max and min latitude and longitudes from all the points to be displayed in the heatmap
    let maxLat = heatmapperCoordinatesArray.map {$0.latitude}.max()
    let minLat = heatmapperCoordinatesArray.map {$0.latitude}.min()
    let maxLong = heatmapperCoordinatesArray.map {$0.longitude}.max()
    let minLong = heatmapperCoordinatesArray.map {$0.longitude}.min()

    let minCoord = CLLocationCoordinate2D(latitude: minLat!, longitude: minLong!)
    let maxCoord = CLLocationCoordinate2D(latitude: maxLat!, longitude: maxLong!)

    // pinning these purely for reference - remove when ready to ship
    addAnnotation(coordinate: minCoord)
    addAnnotation(coordinate: maxCoord)

    // get the max and min X and Y points from the above coordinates as MKMapPoints
    let minX = MKMapPoint(minCoord).x
    let maxX = MKMapPoint(maxCoord).x
    let minY = MKMapPoint(minCoord).y
    let maxY = MKMapPoint(maxCoord).y

    // this code ensures the pitch size is larger than the heatmap by adding a margin
    // get the dimensions of the rectangle from the distance between the point extremes
    var rectWidth = maxX - minX
    var rectHeight = minY - maxY
    // set the scale of the border
    let rectMarginScale = 0.2
    // set the rectangle origin as the plot dimensions plus the border
    let rectX = minX - (rectWidth * rectMarginScale)
    let rectY = minY + (rectHeight * rectMarginScale)

    // increase the rectangle width and height by the border * 2
    rectWidth = rectWidth + (rectWidth * rectMarginScale * 2)
    rectHeight = rectHeight + (rectHeight * rectMarginScale * 2)

    // this rectangle covers the area of all points
//    let rect = MKMapRect.init(x: minX, y: minY, width: maxX - minX, height: minY - maxY)
    let rect = MKMapRect.init(x: rectX, y: rectY, width: rectWidth, height: rectHeight)

    // get the angle we want to set the pitch at
//    let rectTopLeftX = rect.minX
//    let rectTopLeftY = rect.minY
//    let rectBottomRightX = rect.maxX
//    let rectBottomRightY = rect.maxY
//
//    let rectTopLeftPoint = CGPoint(x: rectTopLeftX, y: rectTopLeftY)
//    let rectBottomRightPoint = CGPoint(x: rectBottomRightX, y: rectBottomRightY)
//    let rectAngle = MyFunc.angle(between: rectTopLeftPoint, ending: rectBottomRightPoint)
//
//    MyFunc.logMessage(.debug, "rect: \(rect)")
//    MyFunc.logMessage(.debug, "rectAngle: \(rectAngle)")
//    angle = rectAngle

//    pointsDistance = MyFunc.distanceBetween(point1: rectTopLeftPoint, point2: rectBottomRightPoint)

    //  create an overlay of the pitch based upon the rectangle
    let footballPitch11Overlay = FootballPitchOverlay(pitchRect: rect)
//    self.mapView.addOverlay(footballPitch11Overlay)


    self.setMapViewZoom(rect: rect)

  }

  func addHeatmapPoint(coordinate:CLLocationCoordinate2D){

    // create MKCircle for each heatmap point
    let heatmapPointCircle = MKCircle(center: coordinate, radius: 2)
    mapView.addOverlay(heatmapPointCircle)
//    self.accuracyRangeCircle = MKCircle(center: location.coordinate, radius: accuracyRadius as CLLocationDistance)

//    let annotation = REHeatmapPointAnnotation()
//    annotation.coordinate = coordinate
//    mapView.addAnnotation(annotation)
  }

  func addAnnotation(coordinate:CLLocationCoordinate2D){
    let annotation = MKPointAnnotation()
    annotation.coordinate = coordinate
    mapView.addAnnotation(annotation)
  }

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

          self.createPitchOverlay()
          self.createREHeatmap()
//          self.createDTMHeatmap()


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

    if overlay is MKCircle  {
      let circleRenderer = HeatmapPointCircleRenderer(circle: overlay as! MKCircle)
      return circleRenderer
    }

    if overlay is FootballPitchOverlay {
      if let pitchImage = UIImage(named: "football pitch 11.png")
      {
        let footballPitchOverlayView = FootballPitchOverlayView(overlay: overlay, overlayImage: pitchImage, angle: self.angle, pointsDistance: self.pointsDistance)
        return footballPitchOverlayView
      }
    }


    return DTMHeatmapRenderer.init(overlay: overlay)
//    return REHeatmapRenderer.init(overlay: overlay)
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

    if annotation is UserAnnotation {
      MyFunc.logMessage(.debug, "UserAnnotation")

    }

    let reuseId = "heatmapPoint"
    var heatmapPointAnnotationView: MKAnnotationView? = self.mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKAnnotationView

    if heatmapPointAnnotationView == nil {
        heatmapPointAnnotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
        heatmapPointAnnotationView?.image = self.reHeatmapPointImage
        heatmapPointAnnotationView?.frame.size = CGSize(width: 3, height: 3)

    } else {
      heatmapPointAnnotationView?.annotation = annotation
    }

//    var pinAnnotationView: MKPinAnnotationView? = self.mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
//    if pinAnnotationView == nil {
//      pinAnnotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
//      pinAnnotationView?.isDraggable = true
//      pinAnnotationView?.canShowCallout = true
//      pinAnnotationView?.pinTintColor = .blue
//    } else {
//      pinAnnotationView?.annotation = annotation
//    }

    return heatmapPointAnnotationView
  }


  func createDTMHeatmap() {

    var heatmapdata:[NSObject: Double] = [:]
    for coordinate in heatmapperCoordinatesArray {
      var point = MKMapPoint.init(coordinate)
      let type = "{MKMapPoint=dd}"
      let value = NSValue(bytes: &point, objCType: type)
      heatmapdata[value] = 1.0
    }

    self.dtmHeatmap.setData(heatmapdata as [NSObject : AnyObject])
    self.mapView.addOverlay(self.dtmHeatmap)
    let dtmBoundingRect = self.dtmHeatmap.boundingRect
    dtmRect = dtmBoundingRect
    let dtmCoordinate = self.dtmHeatmap.coordinate
    MyFunc.logMessage(.debug, "dtmBoundingRect: \(dtmBoundingRect)")
    MyFunc.logMessage(.debug, "dtmCoordinate: \(dtmCoordinate)")

  }



}
