//
//  HeatmapViewController.swift
//  Heatmapper
//
//  Created by Richard English on 08/01/2021.
//  Copyright © 2021 Richard English. All rights reserved.
//
//  This class is the developed Heatmap View Controller using my heatmap generation without the Tester functionality
//

import UIKit
import MapKit
import HealthKit
import CoreLocation


class HeatmapViewController: UIViewController, MyMapListener {

  var heatmapperCoordinatesArray  = [CLLocationCoordinate2D]()
  var heatmapperLocationsArray    = [CLLocation]()
  var heatmapWorkoutId            : UUID?
  var workoutMetadata             = WorkoutMetadata(workoutId: UUID.init(), activity: "", sport: "", venue: "", pitch: "")
  var workoutMetadataArray        =  [WorkoutMetadata]()

  var heatmapImage                : UIImage?
  var retrievedWorkout            : HKWorkout?
  var routeCoordinatesArray       = [CLLocation]()

  let workoutDateFormatter        = DateFormatter()
  var measurementFormatter        = MeasurementFormatter()
  var units                       : String = ""
  var unitLength                  : UnitLength = .meters
  var unitSpeed                   : UnitSpeed  = .metersPerSecond
  let defaults                    = UserDefaults.standard

  var resizeOn                    : Bool = true
  var playingAreaMapRect          : MKMapRect?
  var heatmapPointCircle          : MKCircle?
  var reHeatmapPoint              : REHeatmapPoint?
  var reHeatmapPointImage         : UIImage?

  let healthStore                 = HKHealthStore()
  let theme = ColourTheme()

  var innerColourRed              : String = "1.0"
  var innerColourGreen            : String = "0.0"
  var innerColourBlue             : String = "0.0"
  var innerColourAlpha            : String = "0.9"

  var middleColourRed             : String = "1.0"
  var middleColourGreen           : String = "0.5"
  var middleColourBlue            : String = "0.0"
  var middleColourAlpha           : String = "0.5"

  var outerColourRed              : String = "1.0"
  var outerColourGreen            : String = "1.0"
  var outerColourBlue             : String = "0.0"
  var outerColourAlpha            : String = "0.3"

  let blendMode                   = CGBlendMode.colorBurn
  var innerColourGradient         : String = "0.1"
  var middleColourGradient        : String = "0.3"
  var outerColourGradient         : String = "0.5"
  var radius                      : Int = 2

  var pitchRotationAtResizeOff    : CGFloat = 0.0
  var pitchRotationAtResizeOn     : CGFloat = 0.0

  var mapHeadingAtResizeOn        : Double = 0.0
  var mapHeadingAtResizeOff       : Double = 0.0

  var playingAreaAngleSaved       : CGFloat = 0.0
  var pitchAngleToApply           : CGFloat = 0.0

  var bottomLeftCoord             : CLLocationCoordinate2D?
  var topLeftCoord                : CLLocationCoordinate2D?
  var bottomRightCoord            : CLLocationCoordinate2D?
  var topRightCoord               : CLLocationCoordinate2D?

  var blendModeArray              = [BlendMode]()
  var activityArray               = [Activity]()
  var sportArray                  = [Sport]()

  var overlayCenter               : CLLocationCoordinate2D?


  @IBOutlet weak var mapStartRadiansField: ThemeMediumFontTextField!
  @IBOutlet weak var mapStartDegreesField: ThemeMediumFontTextField!
  @IBOutlet weak var pitchStartRadiansField: ThemeMediumFontTextField!
  @IBOutlet weak var pitchStartDegreesField: ThemeMediumFontTextField!
  @IBOutlet weak var mapEndRadiansField: ThemeMediumFontTextField!
  @IBOutlet weak var mapEndDegreesField: ThemeMediumFontTextField!
  @IBOutlet weak var pitchEndRadiansField: ThemeMediumFontTextField!
  @IBOutlet weak var pitchEndDegreesField: ThemeMediumFontTextField!

  @IBOutlet weak var playingAreaSavedAngleRadiansField: ThemeMediumFontTextField!
  @IBOutlet weak var playingAreaSavedAngleDegreesField: ThemeMediumFontTextField!

  @IBOutlet weak var playingAreaToSaveAngleRadiansField: ThemeMediumFontTextField!
  @IBOutlet weak var playingAreaToSaveAngleDegreesField: ThemeMediumFontTextField!


  @IBOutlet weak var resizeButton: UIButton!

  @IBAction func resetPitches(_ sender: Any) {
    MyFunc.deletePlayingAreas()
  }

  @IBOutlet weak var activityField      : ThemeMediumFontTextField!
  @IBOutlet weak var sportField         : ThemeMediumFontTextField!
  @IBOutlet weak var venueField         : ThemeMediumFontTextField!
  @IBOutlet weak var pitchField         : ThemeMediumFontTextField!

  @IBOutlet weak var distanceLabel      : ThemeMediumFontUILabel!
  @IBOutlet weak var caloriesLabel      : ThemeMediumFontUILabel!
  @IBOutlet weak var heartRateLabel     : ThemeMediumFontUILabel!
  @IBOutlet weak var paceLabel          : ThemeMediumFontUILabel!

  @IBOutlet weak var caloriesImageView  : UIImageView!
  @IBOutlet weak var paceImageView      : UIImageView!
  @IBOutlet weak var heartRateImageView : UIImageView!
  @IBOutlet weak var distanceImageView  : UIImageView!

  let activityPicker              = UIPickerView()
  let sportPicker                 = UIPickerView()

  @IBOutlet weak var mapView: MyMKMapView!

  @objc func resizeTap(_ sender: UITapGestureRecognizer? = nil) {
  }

  @objc func handleRotate(_ gesture: UIRotationGestureRecognizer) {
    guard let gestureView = gesture.view else {
      return
    }
    gestureView.transform = gestureView.transform.rotated(by: gesture.rotation)
    pitchRotationAtResizeOff += gesture.rotation
    updateAngleUI()
    gesture.rotation = 0
  }

  @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
    guard let gestureView = gesture.view else {
      return
    }
    gestureView.transform = gestureView.transform.scaledBy(x: gesture.scale, y: gesture.scale)
    gesture.scale = 1

  }

  @objc func handlePan(_ sender: UIPanGestureRecognizer) {

    let translation = sender.translation(in: view)
    guard let gestureView = sender.view else {
      return
    }

    gestureView.center = CGPoint(x: gestureView.center.x + translation.x, y: gestureView.center.y + translation.y)
    sender.setTranslation(.zero, in: view)
    guard sender.state == .ended else {
      return
    }

    let velocity = sender.velocity(in: view)
    let magnitude = sqrt((velocity.x * velocity.x) + (velocity.y * velocity.y))
    let slideMultiplier = magnitude / 200

    let slideFactor = 0.1 * slideMultiplier
    var finalPoint = CGPoint(x: gestureView.center.x + (velocity.x * slideFactor), y: gestureView.center.y + (velocity.y * slideFactor))
    finalPoint.x = min(max(finalPoint.x, 0), view.bounds.width)
    finalPoint.y = min(max(finalPoint.y, 0), view.bounds.height)

  }

  @IBAction func btnResize(_ sender: Any) {

    if resizeOn == true {
      // turn everything off (as it's on)

      resizeOn = false
      resizeButton.setTitle("Adjust Pitch Size", for: .normal)
      resizeButton.tintColor = UIColor.systemGreen

      // remove the pins and annotations
      removeAllPinsAndAnnotations()

      // record the map heading at end of resizing
      mapHeadingAtResizeOff = mapView.getRotation() ?? 0

      saveResizedPlayingArea()

      // get the image of the heatmap
      saveHeatmapPNG()

      // remove newPitchView
      removeViewWithTag(tag: 200)
      // update the metrics
      updateAngleUI()

      setMapViewZoom()

    } else {
      // turn everything on (as it's off)

      resizeOn = true
      resizeButton.setTitle("Save Pitch Size", for: .normal)
      resizeButton.tintColor = UIColor.systemRed
      removeAllPinsAndAnnotations()

      resizeGetSavedPlayingArea()
    }

  }


  func saveResizedPlayingArea() {

    // first get the corners on the pitch view
    guard let viewToSave = self.view.viewWithTag(200) else {
      MyFunc.logMessage(.debug, "Cannot find pitchView to save")
      return
    }
    let corners = ViewCorners(view: viewToSave)

    let pitchMapTopLeftCGPoint      : CGPoint = corners.topLeft
    let pitchMapBottomLeftCGPoint   : CGPoint = corners.bottomLeft
    let pitchMapBottomRightCGPoint  : CGPoint = corners.bottomRight
    let pitchMapTopRightCGPoint     : CGPoint = corners.topRight

    // this code pins the points onto the map - this should prove the conversion is the same
    addPinImage(point: pitchMapBottomLeftCGPoint, colour: .red, tag: 301)
    addPinImage(point: pitchMapBottomRightCGPoint, colour: .yellow, tag: 302)
    addPinImage(point: pitchMapTopLeftCGPoint, colour: .yellow, tag: 303)
    addPinImage(point: pitchMapTopRightCGPoint, colour: .yellow, tag: 304)


    // then workout out the corresponding co-ordinates at these points on the map view
    var pitchMapTopLeftCoordinate     : CLLocationCoordinate2D = mapView.convert(pitchMapTopLeftCGPoint, toCoordinateFrom: self.mapView)
    var pitchMapBottomLeftCoordinate  : CLLocationCoordinate2D = mapView.convert(pitchMapBottomLeftCGPoint, toCoordinateFrom: self.mapView)
    var pitchMapBottomRightCoordinate : CLLocationCoordinate2D = mapView.convert(pitchMapBottomRightCGPoint, toCoordinateFrom: self.mapView)
    var pitchMapTopRightCoordinate    : CLLocationCoordinate2D = mapView.convert(pitchMapTopRightCGPoint, toCoordinateFrom: self.mapView)

    // this code pins the coordinates onto the map
    setPinUsingMKAnnotation(coordinate: pitchMapBottomLeftCoordinate, title: "bl")
    setPinUsingMKAnnotation(coordinate: pitchMapTopLeftCoordinate, title: "tl")
    setPinUsingMKAnnotation(coordinate: pitchMapBottomRightCoordinate, title: "br")
    setPinUsingMKAnnotation(coordinate: pitchMapTopRightCoordinate, title: "tr")


    //this logic compares the TopLeft and BottomRight
    //if the TopLeft is south of the BottomRight swap them round
    let topLeftLatitude = pitchMapTopLeftCoordinate.latitude
    let bottomRightLatitude = pitchMapBottomRightCoordinate.latitude
//    if bottomRightLatitude < topLeftLatitude {
      print("Swapping TL and BR: SavePitchCoordinates")
      let topLeftToSwap = pitchMapTopLeftCoordinate
      pitchMapTopLeftCoordinate = pitchMapBottomRightCoordinate
      pitchMapBottomRightCoordinate = topLeftToSwap
      let bottomLeftToSwap = pitchMapBottomLeftCoordinate
      pitchMapBottomLeftCoordinate = pitchMapTopRightCoordinate
      pitchMapTopRightCoordinate = bottomLeftToSwap

//    }

    // update the overlayCenter as we will centre the map Zoom on this
    let midpointLatitude = (pitchMapTopLeftCoordinate.latitude + pitchMapBottomRightCoordinate.latitude) / 2
    let midpointLongitude = (pitchMapTopLeftCoordinate.longitude + pitchMapBottomRightCoordinate.longitude) / 2
    self.overlayCenter = CLLocationCoordinate2D(latitude: midpointLatitude, longitude: midpointLongitude)

    createPitchOverlay(topLeft: pitchMapTopLeftCoordinate, bottomLeft: pitchMapBottomLeftCoordinate, bottomRight: pitchMapBottomRightCoordinate)

    // save the pitch here
    // convert the CLLCoordinates to a subclass which allows us to code them ready for saving
    let topLeftCoordToSave = CodableCLLCoordinate2D(latitude: pitchMapTopLeftCoordinate.latitude, longitude: pitchMapTopLeftCoordinate.longitude)
    let bottomLeftCoordToSave = CodableCLLCoordinate2D(latitude: pitchMapBottomLeftCoordinate.latitude, longitude: pitchMapBottomLeftCoordinate.longitude)
    let bottomRightCoordToSave = CodableCLLCoordinate2D(latitude: pitchMapBottomRightCoordinate.latitude, longitude: pitchMapBottomRightCoordinate.longitude)
    let topRightCoordToSave = CodableCLLCoordinate2D(latitude: pitchMapTopRightCoordinate.latitude, longitude: pitchMapTopRightCoordinate.longitude)

    let playingAreaToSave = PlayingArea(workoutID: heatmapWorkoutId!, bottomLeft: bottomLeftCoordToSave, bottomRight: bottomRightCoordToSave, topLeft: topLeftCoordToSave, topRight: topRightCoordToSave)
    MyFunc.savePlayingArea(playingAreaToSave)


  }


  func resizeGetSavedPlayingArea() {

    // get the saved playing area coordinates
    MyFunc.getPlayingArea(workoutId: heatmapWorkoutId!, successClosure: { result in

      switch result {
      case .failure(let error):
        // no playing area retrieved so create a default area
        MyFunc.logMessage(.debug, "No playing area retrieved: \(error.localizedDescription) so creating default")

        // get the max and min latitude and longitudes from all the points to be displayed in the heatmap
        let maxLat = self.heatmapperCoordinatesArray.map {$0.latitude}.max()
        let minLat = self.heatmapperCoordinatesArray.map {$0.latitude}.min()
        let maxLong = self.heatmapperCoordinatesArray.map {$0.longitude}.max()
        let minLong = self.heatmapperCoordinatesArray.map {$0.longitude}.min()

        let minCoord = CLLocationCoordinate2D(latitude: minLat!, longitude: minLong!)
        let maxCoord = CLLocationCoordinate2D(latitude: maxLat!, longitude: maxLong!)

        let midpointLatitude = (minCoord.latitude + maxCoord.latitude) / 2
        let midpointLongitude = (minCoord.longitude + maxCoord.longitude) / 2
        self.overlayCenter = CLLocationCoordinate2D(latitude: midpointLatitude, longitude: midpointLongitude)

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
        let rectMarginScale = 0.1
        // set the rectangle origin as the plot dimensions plus the border
        let rectX = minX - (rectWidth * rectMarginScale)
        let rectY = minY + (rectHeight * rectMarginScale)
        // increase the rectangle width and height by the border * 2
        rectWidth = rectWidth + (rectWidth * rectMarginScale * 2)
        rectHeight = rectHeight + (rectHeight * rectMarginScale * 2)

        let pitchMKMapRect = MKMapRect.init(x: rectX, y: rectY, width: rectWidth, height: rectHeight)
        self.playingAreaMapRect = pitchMKMapRect

        //  create an overlay of the pitch based upon the rectangle
        let footballPitch11Overlay = FootballPitchOverlay(pitchRect: pitchMKMapRect)
        self.mapView.addOverlay(footballPitch11Overlay)
        self.setMapViewZoom()

        self.bottomLeftCoord = CLLocationCoordinate2D(latitude: maxLat!, longitude: maxLong!)
        self.topLeftCoord = CLLocationCoordinate2D(latitude: minLat!, longitude: maxLong!)
        self.bottomRightCoord = CLLocationCoordinate2D(latitude: maxLat!, longitude: minLong!)
        self.topRightCoord  = CLLocationCoordinate2D(latitude: minLat!, longitude: minLong!)

        // convert the coordinates to a codable subclass for saving
        let topLeftCoordToSave = CodableCLLCoordinate2D(latitude: self.topLeftCoord!.latitude, longitude: self.topLeftCoord!.longitude)
        let bottomLeftCoordToSave = CodableCLLCoordinate2D(latitude: self.bottomLeftCoord!.latitude, longitude: self.bottomLeftCoord!.longitude)
        let bottomRightCoordToSave = CodableCLLCoordinate2D(latitude: self.bottomRightCoord!.latitude, longitude: self.bottomRightCoord!.longitude)
        let topRightCoordToSave = CodableCLLCoordinate2D(latitude: self.topRightCoord!.latitude, longitude: self.topRightCoord!.longitude)

        let playingAreaToSave = PlayingArea(workoutID: self.heatmapWorkoutId!, bottomLeft:  bottomLeftCoordToSave, bottomRight: bottomRightCoordToSave, topLeft: topLeftCoordToSave, topRight: topRightCoordToSave)
        MyFunc.savePlayingArea(playingAreaToSave)

        self.updateAngleUI()


      case .success(let playingArea):
        MyFunc.logMessage(.debug, "Success retrieving PlayingArea! :")
        let playingAreaStr = String(describing: playingArea)
        MyFunc.logMessage(.debug, playingAreaStr)

        let midpointLatitude = (playingArea.topLeft.latitude + playingArea.bottomLeft.latitude) / 2
        let midpointLongitude = (playingArea.bottomLeft.longitude + playingArea.bottomRight.longitude) / 2
        self.overlayCenter = CLLocationCoordinate2D(latitude: midpointLatitude, longitude: midpointLongitude)
        // convert the stored playingArea coordinates from the codable class to the base CLLCoordinate2D
        let topLeftAsCoord = CLLocationCoordinate2D(latitude: playingArea.topLeft.latitude, longitude: playingArea.topLeft.longitude)
        let bottomLeftAsCoord = CLLocationCoordinate2D(latitude: playingArea.bottomLeft.latitude, longitude: playingArea.bottomLeft.longitude)
        let bottomRightAsCoord = CLLocationCoordinate2D(latitude: playingArea.bottomRight.latitude, longitude: playingArea.bottomRight.longitude)
        let topRightAsCoord = CLLocationCoordinate2D(latitude: playingArea.topRight.latitude, longitude: playingArea.topRight.longitude)

        self.bottomLeftCoord = bottomLeftAsCoord
        self.bottomRightCoord = bottomRightAsCoord
        self.topLeftCoord = topLeftAsCoord
        self.topRightCoord = topRightAsCoord

      }
    })

    // now need to size the pitchView from the MapView information
    // we have the mapView rect from the overlay and the coordinates

    let pitchViewBottomLeft   : CGPoint = self.mapView.convert(bottomLeftCoord!, toPointTo: self.mapView)
    let pitchViewTopLeft      : CGPoint = self.mapView.convert(topLeftCoord!, toPointTo: self.mapView)
    let pitchViewBottomRight  : CGPoint = self.mapView.convert(bottomRightCoord!, toPointTo: self.mapView)
    let pitchViewTopRight     : CGPoint = self.mapView.convert(topRightCoord!, toPointTo: self.mapView)

    // pin the coordinates onto the map
    setPinUsingMKAnnotation(coordinate: bottomLeftCoord!, title: "BL")
    setPinUsingMKAnnotation(coordinate: topLeftCoord!, title: "TL")
    setPinUsingMKAnnotation(coordinate: bottomRightCoord!, title: "BR")
    setPinUsingMKAnnotation(coordinate: topRightCoord!, title: "TR")

    // pin the points onto the map - this should prove the conversion is the same
    addPinImage(point: pitchViewBottomLeft, colour: .blue, tag: 101)
    addPinImage(point: pitchViewBottomRight, colour: .white, tag: 102)
    addPinImage(point: pitchViewTopLeft, colour: .white, tag: 103)
    addPinImage(point: pitchViewTopRight, colour: .white, tag: 104)

    let newWidth = CGPointDistance(from: pitchViewBottomLeft, to: pitchViewBottomRight)
    let newHeight = CGPointDistance(from: pitchViewBottomLeft, to: pitchViewTopLeft)

    // now add the view
    let newPitchView = UIImageView(frame: (CGRect(x: pitchViewBottomRight.x, y: pitchViewBottomRight.y, width: newWidth, height: newHeight)))
    let pitchImageGreen = UIImage(named: "Figma Pitch 11 Blue")
    newPitchView.image = pitchImageGreen
    newPitchView.layer.opacity = 0.5
    newPitchView.isUserInteractionEnabled = true
    newPitchView.tag = 200

    // add the gesture recognizers
    let rotator = UIRotationGestureRecognizer(target: self,action: #selector(self.handleRotate(_:)))
    let panner = UIPanGestureRecognizer(target: self,action: #selector(self.handlePan(_:)))
    let pincher = UIPinchGestureRecognizer(target: self, action: #selector(self.handlePinch(_:)))
    newPitchView.addGestureRecognizer(panner)
    newPitchView.addGestureRecognizer(rotator)
    newPitchView.addGestureRecognizer(pincher)

    // rotate the view
    // need to anchor this first by the origin in order to rotate around bottom left
    newPitchView.setAnchorPoint(CGPoint(x: 0, y: 0))
    let pitchAngle = angleInRadians(between: pitchViewBottomRight, ending: pitchViewBottomLeft)
    playingAreaAngleSaved = pitchAngle
    newPitchView.transform = newPitchView.transform.rotated(by: pitchAngle)
    mapView.addSubview(newPitchView)
    newPitchView.setAnchorPoint(CGPoint(x: 0.5, y: 0.5))

    mapHeadingAtResizeOn = mapView.camera.heading
    pitchRotationAtResizeOn = rotation(from: newPitchView.transform)
    updateAngleUI()

    //remove the pitch MKMapOverlay
    if let overlays = mapView?.overlays {
      for overlay in overlays {
        if overlay is FootballPitchOverlay {
          mapView?.removeOverlay(overlay)
        }
      }
    }

  }


  func getPlayingAreaOnLoad() {

    // original below - used in
    MyFunc.getPlayingArea(workoutId: heatmapWorkoutId!, successClosure: { result in
      switch result {
      case .failure(let error):
        // no playing area retrieved so create a default area
        MyFunc.logMessage(.debug, "No playing area retrieved: \(error.localizedDescription) so creating default")

        // get the max and min latitude and longitudes from all the points to be displayed in the heatmap
        let maxLat = self.heatmapperCoordinatesArray.map {$0.latitude}.max()
        let minLat = self.heatmapperCoordinatesArray.map {$0.latitude}.min()
        let maxLong = self.heatmapperCoordinatesArray.map {$0.longitude}.max()
        let minLong = self.heatmapperCoordinatesArray.map {$0.longitude}.min()

        let minCoord = CLLocationCoordinate2D(latitude: minLat!, longitude: minLong!)
        let maxCoord = CLLocationCoordinate2D(latitude: maxLat!, longitude: maxLong!)

        let midpointLatitude = (minCoord.latitude + maxCoord.latitude) / 2
        let midpointLongitude = (minCoord.longitude + maxCoord.longitude) / 2
        self.overlayCenter = CLLocationCoordinate2D(latitude: midpointLatitude, longitude: midpointLongitude)

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
        let rectMarginScale = 0.1
        // set the rectangle origin as the plot dimensions plus the border
        let rectX = minX - (rectWidth * rectMarginScale)
        let rectY = minY + (rectHeight * rectMarginScale)

        // increase the rectangle width and height by the border * 2
        rectWidth = rectWidth + (rectWidth * rectMarginScale * 2)
        rectHeight = rectHeight + (rectHeight * rectMarginScale * 2)

        let pitchMKMapRect = MKMapRect.init(x: rectX, y: rectY, width: rectWidth, height: rectHeight)
        self.playingAreaMapRect = pitchMKMapRect

        //  create an overlay of the pitch based upon the rectangle
//        let footballPitch11Overlay = FootballPitchOverlay(pitchRect: pitchMKMapRect)
//        self.mapView.addOverlay(footballPitch11Overlay)
        self.setMapViewZoom()


        // get the PlayingArea corner coordinates from the size of heatmap
        self.bottomLeftCoord = CLLocationCoordinate2D(latitude: maxLat!, longitude: maxLong!)
        self.topLeftCoord = CLLocationCoordinate2D(latitude: minLat!, longitude: maxLong!)
        self.bottomRightCoord = CLLocationCoordinate2D(latitude: maxLat!, longitude: minLong!)
        self.topRightCoord  = CLLocationCoordinate2D(latitude: minLat!, longitude: minLong!)

        // convert the coordinates to a codable subclass for saving
        let topLeftCoordToSave = CodableCLLCoordinate2D(latitude: self.topLeftCoord!.latitude, longitude: self.topLeftCoord!.longitude)
        let bottomLeftCoordToSave = CodableCLLCoordinate2D(latitude: self.bottomLeftCoord!.latitude, longitude: self.bottomLeftCoord!.longitude)
        let bottomRightCoordToSave = CodableCLLCoordinate2D(latitude: self.bottomRightCoord!.latitude, longitude: self.bottomRightCoord!.longitude)
        let topRightCoordToSave = CodableCLLCoordinate2D(latitude: self.topRightCoord!.latitude, longitude: self.topRightCoord!.longitude)

        // now save the auto-generated PlayingArea coordinates for future use
        let playingAreaToSave = PlayingArea(workoutID: self.heatmapWorkoutId!, bottomLeft:  bottomLeftCoordToSave, bottomRight: bottomRightCoordToSave, topLeft: topLeftCoordToSave, topRight: topRightCoordToSave)
        MyFunc.savePlayingArea(playingAreaToSave)

        self.updateAngleUI()


      case .success(let playingArea):
        MyFunc.logMessage(.debug, "Success retrieving PlayingArea! :")
        let playingAreaStr = String(describing: playingArea)
        MyFunc.logMessage(.debug, playingAreaStr)

        let midpointLatitude = (playingArea.topLeft.latitude + playingArea.bottomLeft.latitude) / 2
        let midpointLongitude = (playingArea.bottomLeft.longitude + playingArea.bottomRight.longitude) / 2
        self.overlayCenter = CLLocationCoordinate2D(latitude: midpointLatitude, longitude: midpointLongitude)

        // PlayingArea coordinates stored as Codable sub-class of CLLocationCoordinate2D so convert to original class (may be able to remove this?)
        let topLeftAsCoord = CLLocationCoordinate2D(latitude: playingArea.topLeft.latitude, longitude: playingArea.topLeft.longitude)
        let bottomLeftAsCoord = CLLocationCoordinate2D(latitude: playingArea.bottomLeft.latitude, longitude: playingArea.bottomLeft.longitude)
        let bottomRightAsCoord = CLLocationCoordinate2D(latitude: playingArea.bottomRight.latitude, longitude: playingArea.bottomRight.longitude)
        let topRightAsCoord = CLLocationCoordinate2D(latitude: playingArea.topRight.latitude, longitude: playingArea.topRight.longitude)

        self.bottomLeftCoord = bottomLeftAsCoord
        self.bottomRightCoord = bottomRightAsCoord
        self.topLeftCoord = topLeftAsCoord
        self.topRightCoord = topRightAsCoord

      }
    })


    // getting the angle to rotate the overlay by from the CGPoints
    // simply doing this as it seems to work better than using coordinate angles
    let pitchViewBottomLeft   : CGPoint = self.mapView.convert(bottomLeftCoord!, toPointTo: self.mapView)
    let pitchViewBottomRight  : CGPoint = self.mapView.convert(bottomRightCoord!, toPointTo: self.mapView)
    let pitchViewTopRight     : CGPoint = self.mapView.convert(topRightCoord!, toPointTo: self.mapView)
    let pitchViewTopLeft      : CGPoint = self.mapView.convert(topLeftCoord!, toPointTo: self.mapView)

    // pin the coordinates onto the map
    setPinUsingMKAnnotation(coordinate: bottomLeftCoord!, title: "BL")
    setPinUsingMKAnnotation(coordinate: topLeftCoord!, title: "TL")
    setPinUsingMKAnnotation(coordinate: bottomRightCoord!, title: "BR")
    setPinUsingMKAnnotation(coordinate: topRightCoord!, title: "TR")

    // pin the points onto the map - this should prove the conversion is the same
    addPinImage(point: pitchViewBottomLeft, colour: .blue, tag: 101)
    addPinImage(point: pitchViewBottomRight, colour: .white, tag: 102)
    addPinImage(point: pitchViewTopLeft, colour: .white, tag: 103)
    addPinImage(point: pitchViewTopRight, colour: .white, tag: 104)

    let newWidth = CGPointDistance(from: pitchViewBottomLeft, to: pitchViewBottomRight)
    let newHeight = CGPointDistance(from: pitchViewBottomLeft, to: pitchViewTopLeft)

    // now add the view
    let newPitchView = UIImageView(frame: (CGRect(x: pitchViewBottomRight.x, y: pitchViewBottomRight.y, width: newWidth, height: newHeight)))
    let pitchImageGreen = UIImage(named: "Figma Pitch 11 Blue")
    newPitchView.image = pitchImageGreen
    newPitchView.layer.opacity = 0.5
    newPitchView.isUserInteractionEnabled = true
    newPitchView.tag = 200

    // add the gesture recognizers
    let rotator = UIRotationGestureRecognizer(target: self,action: #selector(self.handleRotate(_:)))
    let panner = UIPanGestureRecognizer(target: self,action: #selector(self.handlePan(_:)))
    let pincher = UIPinchGestureRecognizer(target: self, action: #selector(self.handlePinch(_:)))
    newPitchView.addGestureRecognizer(panner)
    newPitchView.addGestureRecognizer(rotator)
    newPitchView.addGestureRecognizer(pincher)

    // rotate the view
    // need to anchor this first by the origin in order to rotate around bottom left
    newPitchView.setAnchorPoint(CGPoint(x: 0, y: 0))
    let pitchAngle = angleInRadians(between: pitchViewBottomRight, ending: pitchViewBottomLeft)
    playingAreaAngleSaved = pitchAngle
    newPitchView.transform = newPitchView.transform.rotated(by: pitchAngle)
    self.pitchAngleToApply = pitchAngle
//    mapView.addSubview(newPitchView)
//    newPitchView.isHidden = true
    newPitchView.setAnchorPoint(CGPoint(x: 0.5, y: 0.5))

    mapHeadingAtResizeOn = mapView.camera.heading
    pitchRotationAtResizeOn = rotation(from: newPitchView.transform)
    updateAngleUI()


    playingAreaAngleSaved = pitchAngle
    self.pitchAngleToApply = pitchAngle
    self.createPitchOverlay(topLeft: self.topLeftCoord!, bottomLeft: self.bottomLeftCoord!, bottomRight: self.bottomRightCoord!)
    self.setMapViewZoom()

  }

  func createPitchOverlay(topLeft: CLLocationCoordinate2D, bottomLeft: CLLocationCoordinate2D, bottomRight: CLLocationCoordinate2D) {

    // get the max and min X and Y points from the above coordinates as MKMapPoints
    let topLeftMapPoint = MKMapPoint(topLeft)
    let bottomLeftMapPoint = MKMapPoint(bottomLeft)
    let bottomRightMapPoint = MKMapPoint(bottomRight)

    let pitchRectHeight = MKMapPointDistance(from: bottomLeftMapPoint, to: topLeftMapPoint)
    let pitchRectWidth = MKMapPointDistance(from: bottomLeftMapPoint, to: bottomRightMapPoint)

    // using the bottom left as the origin of the rectangle (currently)
    let pitchMapOriginX = bottomLeftMapPoint.x
    let pitchMapOriginY = bottomLeftMapPoint.y

    // set up the rectangle
    let pitchMKMapRect = MKMapRect.init(x: pitchMapOriginX, y: pitchMapOriginY, width: pitchRectWidth, height: pitchRectHeight)

    //  create an overlay of the pitch based upon the rectangle
    let adjustedPitchOverlay = FootballPitchOverlay(pitchRect: pitchMKMapRect)
    self.mapView.addOverlay(adjustedPitchOverlay)
    self.playingAreaMapRect = pitchMKMapRect

  }



  func getMapRotation() -> CGFloat {

    var rotationToApply : CGFloat = 0.0

    let pitchAngleToApplyStr = String(describing: pitchAngleToApply.radiansToDegrees)
    print("pitchAngleToApply in getMapRotation: \(pitchAngleToApplyStr)")

    if let newPitchView = self.view.viewWithTag(200) {
      rotationToApply = rotation(from: newPitchView.transform.inverted())
      let pitchRotationDuringResize = pitchRotationAtResizeOn - pitchRotationAtResizeOff
      if pitchRotationDuringResize > .pi / 2  {
        print ("over 180 degree turn")
      } else {
      rotationToApply = rotationToApply + .pi
      }
      print("Rotation from newPitchView")
    } else {
      rotationToApply = 0 - (pitchAngleToApply + .pi)
      print("Rotation from pitchAngleToApply")

    }

    let rotationToApplyStr = String(describing: rotationToApply.radiansToDegrees)
    print("rotationToApplyStr \(rotationToApplyStr) º")
    let mapViewHeading = mapView.camera.heading

    let mapViewHeadingInt = Int(mapViewHeading)
    let mapViewHeadingRadians = mapViewHeadingInt.degreesToRadians
    let mapViewHeadingStr = String(describing: mapViewHeadingInt)
    print("mapViewHeadingStr: \(mapViewHeadingStr)")
    let angleIncMapRotation = rotationToApply - mapViewHeadingRadians
    let angleIncMapRotationStr = String(describing: angleIncMapRotation)
    print("angleIncMapRotation: \(angleIncMapRotationStr)")
    updateAngleUI()
    return angleIncMapRotation

  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.workoutMetadataArray = MyFunc.getWorkoutMetadata()
    if let workoutMetadataRow = self.workoutMetadataArray.firstIndex(where: {$0.workoutId == self.heatmapWorkoutId}) {
      self.workoutMetadata = self.workoutMetadataArray[workoutMetadataRow]
      self.loadMetadataUI()
    }

    mapView.delegate = self
    mapView.listener = self

    resizeOn = false
    resizeButton.setTitle("Adjust Pitch Size", for: .normal)
    resizeButton.tintColor = UIColor.systemGreen
    loadTesterData()
    getStaticData()

    // get workout data
    // Note: all UI work is called within this function as the data retrieval works asynchronously
    getWorkoutData()
    updateAngleUI()
  } /* viewDidLoad */

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    updateWorkout()
  }
  func mapView(_ mapView: MyMKMapView, rotationDidChange rotation: Double) {
    // this function just tracks any rotation changes in the map and prints them out
    mapHeadingAtResizeOff = rotation
    updateAngleUI()
  }

  func saveHeatmapPNG() {
    let mapSnapshot = mapView.snapshot()
    if let data = mapSnapshot.pngData() {
      if let workoutId = self.heatmapWorkoutId {
        let workoutIDString = String(describing: workoutId)
        let fileName = "Heatmap_" + workoutIDString + ".png"
        let fileURL = self.getDocumentsDirectory().appendingPathComponent(fileName)
        try? data.write(to: fileURL)
        //        MyFunc.logMessage(.debug, "Heatmap image \(fileName) saved to \(fileURL)")

      }
    }
  }

  func getDocumentsDirectory() -> URL {
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    let documentsDirectory = paths[0]
    return documentsDirectory
  }



  func getStaticData() {
    activityArray = MyFunc.getHeatmapperActivityDefaults()
    sportArray = Sport.allCases.map { $0 }
  }


  func updateAngleUI () {

    let mapStartRadiansStr = String(format: "%.2f", mapHeadingAtResizeOn.degreesToRadians)
    mapStartRadiansField.text = mapStartRadiansStr
    let mapStartDegreesStr = String(format: "%.2f", mapHeadingAtResizeOn)
    mapStartDegreesField.text = mapStartDegreesStr

    let mapEndRadiansStr = String(format: "%.2f", mapHeadingAtResizeOff.degreesToRadians)
    mapEndRadiansField.text = mapEndRadiansStr
    let mapEndDegreesStr = String(format: "%.2f", mapHeadingAtResizeOff)
    mapEndDegreesField.text = mapEndDegreesStr

    let pitchStartRadiansStr = String(format: "%.2f", pitchRotationAtResizeOn)
    pitchStartRadiansField.text = pitchStartRadiansStr
    let pitchStartDegreesStr = String(format: "%.2f", pitchRotationAtResizeOn.radiansToDegrees)
    pitchStartDegreesField.text = pitchStartDegreesStr

    let pitchEndRadiansStr = String(format: "%.2f", pitchRotationAtResizeOff)
    pitchEndRadiansField.text = pitchEndRadiansStr
    let pitchEndDegreesStr = String(format: "%.2f", pitchRotationAtResizeOff.radiansToDegrees)
    pitchEndDegreesField.text = pitchEndDegreesStr

    let playingAreaAngleSavedRadiansStr = String(format: "%.2f", playingAreaAngleSaved)
    playingAreaSavedAngleRadiansField.text = playingAreaAngleSavedRadiansStr
    let playingAreaAngleSavedDegreesStr = String(format: "%.2f", playingAreaAngleSaved.radiansToDegrees)
    playingAreaSavedAngleDegreesField.text = playingAreaAngleSavedDegreesStr


  }


  func loadTesterData() {
    let loadedTesterArray = MyFunc.getTesterData()
    if loadedTesterArray.isEmpty == false {

      innerColourRed = loadedTesterArray[0]
      innerColourGreen = loadedTesterArray[1]
      innerColourBlue = loadedTesterArray[2]
      innerColourAlpha = loadedTesterArray[3]
      innerColourGradient = loadedTesterArray[4]

      middleColourRed = loadedTesterArray[5]
      middleColourGreen = loadedTesterArray[6]
      middleColourBlue = loadedTesterArray[7]
      middleColourAlpha = loadedTesterArray[8]
      middleColourGradient = loadedTesterArray[9]

      outerColourRed = loadedTesterArray[10]
      outerColourGreen = loadedTesterArray[11]
      outerColourBlue = loadedTesterArray[12]
      outerColourAlpha = loadedTesterArray[13]
      outerColourGradient = loadedTesterArray[14]

    }
  }

  func loadMetadataUI() {
    activityPicker.delegate = self
    activityPicker.dataSource = self
    activityField.inputView = activityPicker

    sportPicker.delegate = self
    sportPicker.dataSource = self
    sportField.inputView = sportPicker

    // this code cancels the keyboard and profile picker when field editing finishes
    let tapGesture = UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing))
    tapGesture.cancelsTouchesInView = false
    self.view.addGestureRecognizer(tapGesture)

    let workoutActivity = workoutMetadata.activity
    let workoutVenue = workoutMetadata.venue
    let workoutPitch = workoutMetadata.pitch
    let workoutSport = workoutMetadata.sport

    activityField.text = workoutActivity
    venueField.text = workoutVenue
    pitchField.text = workoutPitch
    sportField.text = workoutSport

  }

  func loadSamplesUI() {

    // colour icons
    heartRateImageView.image = heartRateImageView.image?.withRenderingMode(.alwaysTemplate)
    heartRateImageView.tintColor = UIColor.systemRed

    caloriesImageView.image = caloriesImageView.image?.withRenderingMode(.alwaysTemplate)
    caloriesImageView.tintColor = UIColor.systemOrange

    paceImageView.image = paceImageView.image?.withRenderingMode(.alwaysTemplate)
    paceImageView.tintColor = UIColor.systemBlue

    distanceImageView.image = distanceImageView.image?.withRenderingMode(.alwaysTemplate)
    distanceImageView.tintColor = UIColor.systemGreen
    blendModeArray = BlendMode.allCases.map { $0 }


    guard let heatmapWorkout = retrievedWorkout else {
      MyFunc.logMessage(.error, "SavedHeatmapViewController : no workout returned")
      return
    }

    // total distance
    if let workoutDistance = heatmapWorkout.totalDistance?.doubleValue(for: .meter()) {
      let formattedDistance = String(format: "%.2f m", workoutDistance)
      distanceLabel.text = formattedDistance

      let pace = workoutDistance / heatmapWorkout.duration
      let paceString = MyFunc.getUnitSpeedAsString(value: pace, unitSpeed: unitSpeed, formatter: measurementFormatter)
      let paceUnitString = unitSpeed.symbol
      paceLabel.text = paceString + " " + paceUnitString

    } else {
      distanceLabel.text = nil
    }


    // total calories
    if let caloriesBurned =
        heatmapWorkout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) {
      let formattedCalories = String(format: "%.2f kCal", caloriesBurned)
      caloriesLabel.text = formattedCalories
    } else {
      caloriesLabel.text = nil
    }

    // run query and update label for average Heart Rate
    loadAverageHeartRateLabel(startDate: heatmapWorkout.startDate, endDate: heatmapWorkout.endDate, quantityType: HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!, option: [])

  }

  func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
    return true
  }



  func CGPointDistanceSquared(from: CGPoint, to: CGPoint) -> CGFloat {
    return (from.x - to.x) * (from.x - to.x) + (from.y - to.y) * (from.y - to.y)
  }

  func CGPointDistance(from: CGPoint, to: CGPoint) -> CGFloat {
    return sqrt(CGPointDistanceSquared(from: from, to: to))
  }

  func MKMapPointDistanceSquared(from: MKMapPoint, to: MKMapPoint) -> Double {
    return (from.x - to.x) * (from.x - to.x) + (from.y - to.y) * (from.y - to.y)
  }

  func MKMapPointDistance(from: MKMapPoint, to: MKMapPoint) -> Double {
    return sqrt(MKMapPointDistanceSquared(from: from, to: to))
  }

  // this function gets just the rotation from an affine transform
  func rotation(from transform: CGAffineTransform) -> Double {
    return atan2(Double(transform.b), Double(transform.a))
  }

  func setMapViewZoom() {
    let insets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    mapView.setVisibleMapRect(self.playingAreaMapRect!, edgePadding: insets, animated: false)
    let playingAreaMapRectStr = String(describing: playingAreaMapRect)
    print("playingAreaMapRect at setMapViewZoom: \(playingAreaMapRectStr)")
    mapView.setCenter(self.overlayCenter!, animated: false)
  }

  func createREHeatmap() {

    for heatmapperCoordinate in heatmapperCoordinatesArray {
      addHeatmapPoint(coordinate: heatmapperCoordinate)
    }

  }
  func loadAverageHeartRateLabel(startDate: Date, endDate: Date, quantityType: HKQuantityType, option: HKStatisticsOptions) {
    let quantityPredicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)
    let heartRateQuery = HKStatisticsQuery(quantityType: quantityType, quantitySamplePredicate: quantityPredicate, options: .discreteAverage) { (query, statisticsOrNil, errorOrNil) in

      guard let statistics = statisticsOrNil else {
        return
      }
      let average : HKQuantity? = statistics.averageQuantity()
      let heartRateBPM  = average?.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute())) ?? 0.0

      DispatchQueue.main.async {
        self.heartRateLabel.text = String(format: "%.2f", heartRateBPM) + " bpm"
      }
    }
    healthStore.execute(heartRateQuery)
  }

  func loadAverageSpeedLabel(startDate: Date, endDate: Date, quantityType: HKQuantityType, option: HKStatisticsOptions) {
    let quantityPredicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)
    let heartRateQuery = HKStatisticsQuery(quantityType: quantityType, quantitySamplePredicate: quantityPredicate, options: .discreteAverage) { (query, statisticsOrNil, errorOrNil) in

      guard let statistics = statisticsOrNil else {
        return
      }
      let average : HKQuantity? = statistics.averageQuantity()
      let pace  = average?.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute())) ?? 0.0

      DispatchQueue.main.async {
        self.paceLabel.text = String(format: "%.2f", pace) + " bpm"
      }
    }
    healthStore.execute(heartRateQuery)
  }


  func addHeatmapPoint(coordinate:CLLocationCoordinate2D){

    // create MKCircle for each heatmap point
    let heatmapPointCircle = MKCircle(center: coordinate, radius: CLLocationDistance(radius))
    mapView.addOverlay(heatmapPointCircle)

  }

  func addAnnotation(coordinate:CLLocationCoordinate2D){
    let annotation = MKPointAnnotation()
    annotation.coordinate = coordinate
    mapView.addAnnotation(annotation)
  }

  func getWorkoutData() {
    //    MyFunc.logMessage(.debug, "worko«utId: \(String(describing: heatmapWorkoutId))")

    guard let workoutId = heatmapWorkoutId else {
      MyFunc.logMessage(.error, "heatmapWorkoutId is invalid: \(String(describing: heatmapWorkoutId))")
      return
    }

    // get the workout
    getWorkout(workoutId: workoutId) { [self] (workouts, error) in
      let workoutReturned = workouts?.first

      guard let workout : HKWorkout = workoutReturned else {
        MyFunc.logMessage(.error, "workoutReturned invalid: \(String(describing: workoutReturned))")
        return
      }
      self.retrievedWorkout = workout
      self.getRouteSampleObject(workout: workout)
    }

  }

  func getWorkout(workoutId: UUID, completion:
                  @escaping ([HKWorkout]?, Error?) -> Void) {

    let predicate = HKQuery.predicateForObject(with: workoutId)

    let query = HKSampleQuery(sampleType: .workoutType(), predicate: predicate, limit: 0,sortDescriptors: nil) { (query, results, error) in
      DispatchQueue.main.async {
        guard let samples = results as? [HKWorkout], error == nil
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

      DispatchQueue.main.async {

        guard let routeReturned = samples?.first as? HKWorkoutRoute else {
          MyFunc.logMessage(.error, "Could not convert routeSamples to HKWorkoutRoute")
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

    healthStore.execute(routeQuery)
  }

  func getRouteLocationData(route: HKWorkoutRoute) {

    let query = HKWorkoutRouteQuery(route: route) { (query, locationsOrNil, done, errorOrNil) in
      // This block may be called multiple times.
      if errorOrNil != nil {
        MyFunc.logMessage(.error, "Error retrieving workout locations")
        return
      }
      guard let locations = locationsOrNil else {
        MyFunc.logMessage(.error, "Error retrieving workout locations")
        return
      }

      let locationsAsCoordinates = locations.map {$0.coordinate}
      self.heatmapperCoordinatesArray.append(contentsOf: locationsAsCoordinates)

      // if done = all data retrieved
      // only at this point can we start to build a heatmap overlay
      if done {

        // dispatch to the main queue as we are making UI updates
        DispatchQueue.main.async {
          self.loadSamplesUI()
//          self.resizeGetSavedPlayingArea()
          self.getPlayingAreaOnLoad()
          self.createREHeatmap()
//          self.setMapViewZoom()
        }
      }
    }
    healthStore.execute(query)
  }

  func angleInDegrees(between starting: CGPoint, ending: CGPoint) -> CGFloat {
    let center = CGPoint(x: ending.x - starting.x, y: ending.y - starting.y)
    let radians = atan2(center.y, center.x)
    var degrees = radians * 180 / .pi
    degrees = degrees > 0 ? degrees : degrees + degrees
    let degreesStr = String(describing: degrees)
    let startingStr = String(describing: starting)
    let endingStr = String(describing: ending)
    print("Angle between \(startingStr) and \(endingStr) = \(degreesStr) degrees")
    return degrees
  }

  func angleInRadians(between starting: CGPoint, ending: CGPoint) -> CGFloat {
    let center = CGPoint(x: ending.x - starting.x, y: ending.y - starting.y)
    let radians = atan2(center.y, center.x)
    return radians
  }


  func setPinUsingMKAnnotation(coordinate: CLLocationCoordinate2D, title: String) {
//    let annotation = MKPointAnnotation()
//    annotation.coordinate = coordinate
//    annotation.title = title
//    mapView.addAnnotation(annotation)
  }

  func addPinImage(point: CGPoint, colour: UIColor, tag: Int) {
//    let pinImageView = UIImageView()
//    pinImageView.frame = CGRect(x: point.x, y: point.y, width: 20, height: 20)
//    pinImageView.image = UIImage(systemName: "mappin")
//    pinImageView.tintColor = colour
//    pinImageView.tag = tag
//    mapView.addSubview(pinImageView)
  }

  func removeViewWithTag(tag: Int) {
    if let viewToRemove = self.view.viewWithTag(tag) {
      viewToRemove.removeFromSuperview()
    }
  }

  func removeAllPinsAndAnnotations () {

    let allAnnotations = self.mapView.annotations
    self.mapView.removeAnnotations(allAnnotations)

    removeViewWithTag(tag: 101)
    removeViewWithTag(tag: 102)
    removeViewWithTag(tag: 103)
    removeViewWithTag(tag: 301)
    removeViewWithTag(tag: 302)
    removeViewWithTag(tag: 303)
    removeViewWithTag(tag: 304)
  }


  func updateWorkout()  {

    guard let workoutId = heatmapWorkoutId else {
      MyFunc.logMessage(.error, "Invalid heatmapWorkoutId passed to SavedHeatmapViewController: \(String(describing: heatmapWorkoutId))")
      return
    }

    let activity = activityField.text ?? ""
    let venue = venueField.text ?? ""
    let sport = sportField.text ?? ""
    let pitch = pitchField.text ?? ""

    let workoutMetadataToSave = WorkoutMetadata(workoutId: workoutId, activity: activity, sport: sport, venue: venue, pitch: pitch)
    if let row = self.workoutMetadataArray.firstIndex(where: {$0.workoutId == workoutId}) {
      workoutMetadataArray[row] = workoutMetadataToSave
    } else {
      workoutMetadataArray.append(workoutMetadataToSave)
    }
    MyFunc.saveWorkoutMetadata(workoutMetadataArray)
    //    MyFunc.logMessage(.debug, "WorkoutMetadata saved in SavedHeatmapViewController \(String(describing: workoutMetadataToSave))")

  }

  func getMapRectFromCoordinates(maxLat: Double, minLat: Double, maxLong: Double, minLong: Double) -> MKMapRect {


    let minCoord = CLLocationCoordinate2D(latitude: minLat, longitude: minLong)
    let maxCoord = CLLocationCoordinate2D(latitude: maxLat, longitude: maxLong)

    let midpointLatitude = (minCoord.latitude + maxCoord.latitude) / 2
    let midpointLongitude = (minCoord.longitude + maxCoord.longitude) / 2
    self.overlayCenter = CLLocationCoordinate2D(latitude: midpointLatitude, longitude: midpointLongitude)

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
    let rectMarginScale = 0.1
    // set the rectangle origin as the plot dimensions plus the border
    let rectX = minX - (rectWidth * rectMarginScale)
    let rectY = minY + (rectHeight * rectMarginScale)

    // increase the rectangle width and height by the border * 2
    rectWidth = rectWidth + (rectWidth * rectMarginScale * 2)
    rectHeight = rectHeight + (rectHeight * rectMarginScale * 2)

    let pitchMKMapRect = MKMapRect.init(x: rectX, y: rectY, width: rectWidth, height: rectHeight)
    return pitchMKMapRect
  }

}
    extension HeatmapViewController: MKMapViewDelegate {

      func mapViewDidFinishRenderingMap(_ mapView: MKMapView, fullyRendered: Bool) {
      }

      func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {

        if overlay is MKCircle  {

          // convert UI values to CGFloats for the Renderer
          let innerColourRedFloat = Float(innerColourRed) ?? 0.0
          let innerColourGreenFloat = Float(innerColourGreen) ?? 0.0
          let innerColourBlueFloat = Float(innerColourBlue) ?? 0.0
          let innerColourAlphaFloat = Float(innerColourAlpha) ?? 0.0

          let innerColourRedCGFloat = CGFloat(innerColourRedFloat)
          let innerColourGreenCGFloat = CGFloat(innerColourGreenFloat)
          let innerColourBlueCGFloat = CGFloat(innerColourBlueFloat)
          let innerColourAlphaCGFloat = CGFloat(innerColourAlphaFloat)

          var innerColourArray = [CGFloat]()
          innerColourArray.append(innerColourRedCGFloat)
          innerColourArray.append(innerColourGreenCGFloat)
          innerColourArray.append(innerColourBlueCGFloat)
          innerColourArray.append(innerColourAlphaCGFloat)

          let middleColourRedFloat = Float(middleColourRed) ?? 0.0
          let middleColourGreenFloat = Float(middleColourGreen) ?? 0.0
          let middleColourBlueFloat = Float(middleColourBlue) ?? 0.0
          let middleColourAlphaFloat = Float(middleColourAlpha) ?? 0.0

          let middleColourRedCGFloat = CGFloat(middleColourRedFloat)
          let middleColourGreenCGFloat = CGFloat(middleColourGreenFloat)
          let middleColourBlueCGFloat = CGFloat(middleColourBlueFloat)
          let middleColourAlphaCGFloat = CGFloat(middleColourAlphaFloat)

          var middleColourArray = [CGFloat]()
          middleColourArray.append(middleColourRedCGFloat)
          middleColourArray.append(middleColourGreenCGFloat)
          middleColourArray.append(middleColourBlueCGFloat)
          middleColourArray.append(middleColourAlphaCGFloat)

          let outerColourRedFloat = Float(outerColourRed) ?? 0.0
          let outerColourGreenFloat = Float(outerColourGreen) ?? 0.0
          let outerColourBlueFloat = Float(outerColourBlue) ?? 0.0
          let outerColourAlphaFloat = Float(outerColourAlpha) ?? 0.0

          let outerColourRedCGFloat = CGFloat(outerColourRedFloat)
          let outerColourGreenCGFloat = CGFloat(outerColourGreenFloat)
          let outerColourBlueCGFloat = CGFloat(outerColourBlueFloat)
          let outerColourAlphaCGFloat = CGFloat(outerColourAlphaFloat)

          var outerColourArray = [CGFloat]()
          outerColourArray.append(outerColourRedCGFloat)
          outerColourArray.append(outerColourGreenCGFloat)
          outerColourArray.append(outerColourBlueCGFloat)
          outerColourArray.append(outerColourAlphaCGFloat)

          let gradientLocation1Float = Float(innerColourGradient) ?? 0.0
          let gradientLocation2Float = Float(middleColourGradient) ?? 0.0
          let gradientLocation3Float = Float(outerColourGradient) ?? 0.0

          let gradientLocationCG1Float = CGFloat(gradientLocation1Float)
          let gradientLocationCG2Float = CGFloat(gradientLocation2Float)
          let gradientLocationCG3Float = CGFloat(gradientLocation3Float)

          var gradientLocationsArray = [CGFloat]()
          gradientLocationsArray.append(gradientLocationCG1Float)
          gradientLocationsArray.append(gradientLocationCG2Float)
          gradientLocationsArray.append(gradientLocationCG3Float)

          let circleRenderer = HeatmapPointCircleRenderer(circle: overlay as! MKCircle,
                                                          innerColourArray: innerColourArray, middleColourArray: middleColourArray, outerColourArray: outerColourArray, gradientLocationsArray: gradientLocationsArray, blendMode: blendMode)

          return circleRenderer
        }

        if overlay is FootballPitchOverlay {
          if let pitchImage = UIImage(named: "Figma Pitch 11 Green.png")
          {

            // get the rotation of the pitchView
            let angleIncMapRotation = getMapRotation()
            let footballPitchOverlayRenderer = FootballPitchOverlayRenderer(overlay: overlay, overlayImage: pitchImage, angle: angleIncMapRotation, workoutId: heatmapWorkoutId!)

            footballPitchOverlayRenderer.alpha = 0.5


            return footballPitchOverlayRenderer
          }
        }

        // should never call this... needs to be fixed
        let defaultOverlayRenderer = MKOverlayRenderer()
        return defaultOverlayRenderer

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

    }

    extension HeatmapViewController: UIPickerViewDelegate, UIPickerViewDataSource {

      func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
      }

      func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView == activityPicker {
          return activityArray.count
        } else {
          return sportArray.count
        }
      }

      func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView == activityPicker {
          return activityArray[row].name
        } else {
          return sportArray[row].rawValue
        }
      }

      func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {

        if pickerView == activityPicker {
          activityField.text = activityArray[row].name
          sportField.text = activityArray[row].sport.rawValue
        } else {
          sportField.text = sportArray[row].rawValue
        }
        updateWorkout()

        self.view.endEditing(true)
      }

    }

