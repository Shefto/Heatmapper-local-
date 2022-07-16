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
  var workoutMetadata             = WorkoutMetadata(workoutId: UUID.init(), activity: "", sport: "", playingAreaVenue: "", playingAreaName: "")
  var workoutMetadataArray        =  [WorkoutMetadata]()
  var retrievedWorkout            : HKWorkout?
  private var geocoder            : CLGeocoder!

  var measurementFormatter        = MeasurementFormatter()
  var unitSpeed                   : UnitSpeed  = .metersPerSecond

  var isFavourite                 : Bool = false
  var resizeOn                    : Bool = true
  var playingAreaMapRect          : MKMapRect?
  var heatmapPointCircle          : MKCircle?

  let healthStore                 = HKHealthStore()
  let theme                       = ColourTheme()

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

  var playingAreaAngleSavedAfterResize       : CGFloat = 0.0
  var playingAreaAngleSaved       : CGFloat = 0.0
  var pitchAngleToApply           : CGFloat = 0.0

  var playingArea                 : PlayingArea?
  var bottomLeftCoord             : CLLocationCoordinate2D?
  var topLeftCoord                : CLLocationCoordinate2D?
  var bottomRightCoord            : CLLocationCoordinate2D?
  var topRightCoord               : CLLocationCoordinate2D?
  var playingAreaBearing          : Double = 0.0
  var overlayCenter               : CLLocationCoordinate2D?

  var activityArray               = [Activity]()
  var sportArray                  = [Sport]()

  let activityPicker              = UIPickerView()
  let sportPicker                 = UIPickerView()
  var pitchImage                  = UIImage()


  @IBOutlet weak var mapStartRadiansField               : ThemeMediumFontTextField!
  @IBOutlet weak var mapStartDegreesField               : ThemeMediumFontTextField!
  @IBOutlet weak var pitchStartRadiansField             : ThemeMediumFontTextField!
  @IBOutlet weak var pitchStartDegreesField             : ThemeMediumFontTextField!
  @IBOutlet weak var mapEndRadiansField                 : ThemeMediumFontTextField!
  @IBOutlet weak var mapEndDegreesField                 : ThemeMediumFontTextField!
  @IBOutlet weak var pitchEndRadiansField               : ThemeMediumFontTextField!
  @IBOutlet weak var pitchEndDegreesField               : ThemeMediumFontTextField!

  @IBOutlet weak var playingAreaSavedAngleRadiansField  : ThemeMediumFontTextField!
  @IBOutlet weak var playingAreaSavedAngleDegreesField  : ThemeMediumFontTextField!

  @IBOutlet weak var playingAreaToSaveAngleRadiansField : ThemeMediumFontTextField!
  @IBOutlet weak var playingAreaToSaveAngleDegreesField : ThemeMediumFontTextField!

  @IBOutlet weak var activityField                      : ThemeMediumFontTextField!
  @IBOutlet weak var sportField                         : ThemeMediumFontTextField!
  @IBOutlet weak var venueField                         : ThemeMediumFontTextField!
  @IBOutlet weak var pitchField                         : ThemeMediumFontTextField!
  @IBOutlet weak var placemarkField                     : ThemeMediumFontTextField!

  @IBOutlet weak var distanceLabel                      : ThemeMediumFontUILabel!
  @IBOutlet weak var caloriesLabel                      : ThemeMediumFontUILabel!
  @IBOutlet weak var heartRateLabel                     : ThemeMediumFontUILabel!
  @IBOutlet weak var paceLabel                          : ThemeMediumFontUILabel!

  @IBOutlet weak var caloriesImageView                  : UIImageView!
  @IBOutlet weak var paceImageView                      : UIImageView!
  @IBOutlet weak var heartRateImageView                 : UIImageView!
  @IBOutlet weak var distanceImageView                  : UIImageView!

  @IBOutlet weak var mapView                            : MyMKMapView!
  @IBOutlet weak var resetPlayingAreaButton             : UIButton!
  @IBOutlet weak var resizeButton                       : UIButton!
  @IBOutlet weak var favouritesButton                   : ThemeActionButton!

  @IBOutlet weak var widthStepper                       : UIStepper!
  @IBOutlet weak var heightStepper                      : UIStepper!
  @IBOutlet weak var heightAndWeightStackView           : UIStackView!

  @IBAction func btnSelectFromFavourites(_ sender: Any) {
  }

  @IBAction func segMapType(_ sender: UISegmentedControl) {
    switch sender.selectedSegmentIndex {
    case 0:
      self.mapView.mapType = .mutedStandard
    case 1:
      self.mapView.mapType = .hybrid
    case 2:
      self.mapView.mapType = .satellite
    case 3:
      self.mapView.mapType = .hybridFlyover
    case 4:
      self.mapView.mapType = .satelliteFlyover
    default:
      self.mapView.mapType = .standard
    }
  }

  
  // add the Playing Area to the list of Favourites
  @IBAction func addAsFavourite(_ sender: Any) {

    var messageTitle  : String = ""
    var messageText   : String = ""
    // reverse the Favourite flag
    if playingArea?.isFavourite == false {
      playingArea?.isFavourite = true
      messageTitle = "Added to Favourites"
      messageText = "Playing Area added to Favourites"
    } else {
      playingArea?.isFavourite = false
      messageTitle = "Removed from Favourites"
      messageText = "Playing Area removed from Favourites"
    }

    guard let playingAreaToSave = self.playingArea else {
      MyFunc.logMessage(.error, "HeatmapViewController: addAsFavourite: no Playing Area to save")
      return
    }
    MyFunc.savePlayingArea(playingAreaToSave)

    self.notifyUser(messageTitle, message: messageText)
    setFavouritesButtonTitle()
  }


  @IBAction func textFieldEditingDidEnd(_ sender: Any) {
    playingArea?.name     = pitchField.text
    playingArea?.venue    = venueField.text
    playingArea?.sport    = sportField.text
    guard let playingAreaToSave = self.playingArea else {
      MyFunc.logMessage(.error, "HeatmapViewController: textFieldEditingDidEnd: no Playing Area to save")
      return
    }
    MyFunc.savePlayingArea(playingAreaToSave)
    updateOverlay()

  }


  @IBAction func sportFieldEditingDidEnd(_ sender: Any) {

    let sportStr = sportField.text ?? ""
    updatePitchImage(sport: sportStr)
    playingArea?.sport = sportStr
    guard let playingAreaToSave = self.playingArea else {
      MyFunc.logMessage(.error, "HeatmapViewController: textFieldEditingDidEnd: no Playing Area to save")
      return
    }
    MyFunc.savePlayingArea(playingAreaToSave)
    updateOverlay()
  }

  func updatePitchImage(sport: String)  {
    switch sport {
    case "Football":
      pitchImage = UIImage(named: "Football pitch.png")!
    case "5-a-side":
      pitchImage = UIImage(named: "5-a-side pitch.png")!
    case "Rugby":
      pitchImage = UIImage(named: "Rugby Union pitch.png")!
    case "Tennis":
      pitchImage = UIImage(named: "Tennis court.png")!
    case "None":
      pitchImage = UIImage(named: "Figma Pitch 11 Green.png")!
    default:
      pitchImage = UIImage(named: "Figma Pitch 11 Green.png")!
    }
  }

  func updateOverlay() {

    // first remove the old overlay
    if let overlays = mapView?.overlays {
      for overlay in overlays {
        if overlay is PlayingAreaOverlay {
          mapView?.removeOverlay(overlay)

        }
      }
    }

    // getting the angle to rotate the overlay by from the CGPoints of the corners of one side
    let pitchViewBottomLeft   : CGPoint = self.mapView.convert(bottomLeftCoord!, toPointTo: self.mapView)
    let pitchViewBottomRight  : CGPoint = self.mapView.convert(bottomRightCoord!, toPointTo: self.mapView)

    // rotate the view
    // need to anchor this first by the origin in order to rotate around bottom left

    let pitchAngle = angleInRadians(between: pitchViewBottomRight, ending: pitchViewBottomLeft)
    playingAreaAngleSaved = pitchAngle
    self.pitchAngleToApply = pitchAngle

    mapHeadingAtResizeOn = mapView.camera.heading
    updateAngleUI()

//    playingAreaAngleSaved = pitchAngle
//    self.pitchAngleToApply = pitchAngle
    self.createPlayingAreaOverlay(topLeft: self.topLeftCoord!, bottomLeft: self.bottomLeftCoord!, bottomRight: self.bottomRightCoord!)

  }

  @IBAction func resetPitches(_ sender: Any) {
    MyFunc.deletePlayingAreas()
    updateSteppers()
  }

  func notifyUser(_ title: String, message: String) -> Void
  {
    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
    let cancelAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)

    alert.addAction(cancelAction)
    self.present(alert, animated: true, completion: nil)
  }

  @objc func handleRotate(_ gesture: UIRotationGestureRecognizer) {
    guard let gestureView = gesture.view else {
      return
    }
    gestureView.transform = gestureView.transform.rotated(by: gesture.rotation)
    pitchRotationAtResizeOff += gesture.rotation
    updateAngleUI()
    gesture.rotation = 0
    updateSteppers()
  }

  @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
    guard let gestureView = gesture.view else {
      return
    }
    gestureView.transform = gestureView.transform.scaledBy(x: gesture.scale, y: gesture.scale)
    gesture.scale = 1
    updateSteppers()
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

    updateSteppers()
  }


  @IBAction func stepperWidth(_ sender: UIStepper) {

    guard let playingAreaView = self.view.viewWithTag(200) else {
      MyFunc.logMessage(.debug, "Cannot find pitchView to save")
      return
    }

    let viewX = playingAreaView.frame.origin.x
    let viewY = playingAreaView.frame.origin.y
    let viewHeight = playingAreaView.frame.height
    let viewWidth = sender.value
    playingAreaView.frame = CGRect(x: viewX, y: viewY, width: viewWidth, height: viewHeight)
  }

  @IBAction func stepperHeight(_ sender: UIStepper) {

    guard let playingAreaView = self.view.viewWithTag(200) else {
      MyFunc.logMessage(.debug, "Cannot find pitchView to save")
      return
    }

    let viewX = playingAreaView.frame.origin.x
    let viewY = playingAreaView.frame.origin.y
    let viewHeight = sender.value
    let viewWidth = playingAreaView.frame.width
    playingAreaView.frame = CGRect(x: viewX, y: viewY, width: viewWidth, height: viewHeight)
  }


  @IBAction func btnResize(_ sender: Any) {

    if resizeOn == true {
      // turn everything off (as it's on)

      resizeOn = false
      resizeButton.setTitle("Resize", for: .normal)
      resizeButton.tintColor = UIColor.systemGreen

      // record the map heading at end of resizing
      mapHeadingAtResizeOff = mapView.getRotation() ?? 0
      saveResizedPlayingArea()

      playingAreaAngleSavedAfterResize = pitchRotationAtResizeOff
      let playingAreaAngleSavedAfterResizeDegrees = playingAreaAngleSavedAfterResize.radiansToDegrees

      mapView.camera.heading = playingAreaAngleSavedAfterResizeDegrees

      setMapViewZoom()


      // update the metrics
      updateAngleUI()

      // removes the pitchView
      removeViewWithTag(tag: 200)
      resetPlayingAreaButton.isHidden = true
      heightAndWeightStackView.isHidden = true
      sportField.isHidden = false
      venueField.isHidden = false
      activityField.isHidden = false
      pitchField.isHidden = false


    } else {
      // turn everything on (as it's off)
      resizeOn = true
      resizeButton.setTitle("Save", for: .normal)
      resetPlayingAreaButton.isHidden = false
      heightAndWeightStackView.isHidden = false
      // hide the edit fields for more screen space
      // and to stop pesky switching of the sport type while resizing
      sportField.isHidden = true
      venueField.isHidden = true
      activityField.isHidden = true
      pitchField.isHidden = true

      getPlayingArea()
      enterResizeMode()
      updateSteppers()
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    // get workout metadata
    // *** pending change: replace call of all workouts with just call for this workout's metadata
    self.workoutMetadataArray = MyFunc.getWorkoutMetadata()
    if let workoutMetadataRow = self.workoutMetadataArray.firstIndex(where: {$0.workoutId == self.heatmapWorkoutId}) {
      self.workoutMetadata = self.workoutMetadataArray[workoutMetadataRow]
      self.loadMetadataUI()
    }


    initialiseUI()

    // this function sets up the tester colours
    // retaining but commenting out as may be needed for later work
    //  loadTesterData()

    getStaticData()

    // get workout data
    // Note: all UI work is called within this function as the data retrieval works asynchronously
    getWorkoutData()
    updateAngleUI()

  }

  func initialiseUI() {
    mapView.delegate = self
    mapView.listener = self
    geocoder = CLGeocoder()

    // start in normal (not resize) mode
    resizeOn = false
    resizeButton.setTitle("Resize playing area", for: .normal)

    // default Favourite button to assume PlayingArea not a Favourite
    // *** pending change:  set this from the workout
//    isFavourite = false
//    favouritesButton.setTitle("Add to Favourites", for: .normal)

    resetPlayingAreaButton.isHidden = true
    heightAndWeightStackView.isHidden = true

  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    updateWorkout()
    saveHeatmapImage()


  }

  func updateSteppers() {
    guard let playingAreaView = self.view.viewWithTag(200) else {
      MyFunc.logMessage(.debug, "Cannot find pitchView to save")
      return
    }

    heightStepper.value = playingAreaView.frame.height
    widthStepper.value = playingAreaView.frame.width

  }

  func saveHeatmapImage() {

    let pitchViewTopLeft      : CGPoint = self.mapView.convert(topLeftCoord!, toPointTo: self.mapView)
    let pitchViewBottomRight  : CGPoint = self.mapView.convert(bottomRightCoord!, toPointTo: self.mapView)
    let pitchViewTopRight     : CGPoint = self.mapView.convert(topRightCoord!, toPointTo: self.mapView)

    let imageWidth : Double = pitchViewTopRight.x - pitchViewTopLeft.x
    let imageHeight : Double = pitchViewBottomRight.y - pitchViewTopLeft.y

    let heatmapAreaToCrop = CGRect(x: pitchViewTopLeft.x, y: pitchViewTopLeft.y, width: imageWidth, height: imageHeight)
    let mapViewUIImage : UIImage = mapView.image()!
    let croppedUIImage = mapViewUIImage.crop(rect: heatmapAreaToCrop)

    if let data = croppedUIImage?.pngData() {
      if let workoutId = self.heatmapWorkoutId {
        let workoutIDString = String(describing: workoutId)
        let fileName = "Heatmap_" + workoutIDString + ".png"
        let fileURL = self.getDocumentsDirectory().appendingPathComponent(fileName)
        try? data.write(to: fileURL)
      }

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

    // workout out the corresponding co-ordinates at these points on the map view
    let pitchMapTopLeftCoordinate     : CLLocationCoordinate2D = mapView.convert(pitchMapTopLeftCGPoint, toCoordinateFrom: self.mapView)
    let pitchMapBottomLeftCoordinate  : CLLocationCoordinate2D = mapView.convert(pitchMapBottomLeftCGPoint, toCoordinateFrom: self.mapView)
    let pitchMapBottomRightCoordinate : CLLocationCoordinate2D = mapView.convert(pitchMapBottomRightCGPoint, toCoordinateFrom: self.mapView)
    let pitchMapTopRightCoordinate    : CLLocationCoordinate2D = mapView.convert(pitchMapTopRightCGPoint, toCoordinateFrom: self.mapView)

    playingAreaAngleSavedAfterResize = angleInRadians(between: pitchMapBottomLeftCGPoint, ending: pitchMapBottomRightCGPoint)

    // update the overlayCenter as we will centre the map Zoom on this
    let midpointLatitude = (pitchMapTopLeftCoordinate.latitude + pitchMapBottomRightCoordinate.latitude) / 2
    let midpointLongitude = (pitchMapTopLeftCoordinate.longitude + pitchMapBottomRightCoordinate.longitude) / 2
    self.overlayCenter = CLLocationCoordinate2D(latitude: midpointLatitude, longitude: midpointLongitude)

    createPlayingAreaOverlay(topLeft: pitchMapTopLeftCoordinate, bottomLeft: pitchMapBottomLeftCoordinate, bottomRight: pitchMapBottomRightCoordinate)


    // store the coordinate in the VC's corner variables
    // consider revising above code to use these earlier and avoid having to create new variables for the TL/BR swap
    topLeftCoord         = pitchMapTopLeftCoordinate
    bottomLeftCoord      = pitchMapBottomLeftCoordinate
    topRightCoord        = pitchMapTopRightCoordinate
    bottomRightCoord     = pitchMapBottomRightCoordinate

    playingArea?.topLeft = CodableCLLCoordinate2D(latitude: pitchMapTopLeftCoordinate.latitude, longitude: pitchMapTopLeftCoordinate.longitude)
    playingArea?.bottomLeft = CodableCLLCoordinate2D(latitude: pitchMapBottomLeftCoordinate.latitude, longitude: pitchMapBottomLeftCoordinate.longitude)
    playingArea?.bottomRight = CodableCLLCoordinate2D(latitude: pitchMapBottomRightCoordinate.latitude, longitude: pitchMapBottomRightCoordinate.longitude)
    playingArea?.topRight = CodableCLLCoordinate2D(latitude: pitchMapTopRightCoordinate.latitude, longitude: pitchMapTopRightCoordinate.longitude)

    guard let playingAreaToSave = self.playingArea else {
      MyFunc.logMessage(.error, "HeatmapViewController: addAsFavourite: no Playing Area to save")
      return
    }
    MyFunc.savePlayingArea(playingAreaToSave)

  }

  func enterResizeMode() {

    // need to size the pitchView from the MapView information
    // we have the mapView rect from the overlay and the coordinates

    let pitchViewBottomLeft   : CGPoint = self.mapView.convert(bottomLeftCoord!, toPointTo: self.mapView)
    let pitchViewTopLeft      : CGPoint = self.mapView.convert(topLeftCoord!, toPointTo: self.mapView)
    let pitchViewBottomRight  : CGPoint = self.mapView.convert(bottomRightCoord!, toPointTo: self.mapView)

    let newWidth = CGPointDistance(from: pitchViewBottomLeft, to: pitchViewBottomRight)
    let newHeight = CGPointDistance(from: pitchViewBottomLeft, to: pitchViewTopLeft)

    // now add the view
    let newPitchView = UIImageView(frame: (CGRect(x: pitchViewBottomRight.x, y: pitchViewBottomRight.y, width: newWidth, height: newHeight)))
    let playingAreaImage : UIImage = pitchImage
    newPitchView.image = playingAreaImage
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
        if overlay is PlayingAreaOverlay {
          mapView?.removeOverlay(overlay)
        }
      }
    }

  }


  func getPlayingArea() {
    // get the Playing Area Id associated to the workout - if none, default to non-initialized UUID
    // null results will be handled by the failure case in the closure
    let playingAreaToRetrieveId : UUID = workoutMetadata.playingAreaId ?? UUID()

    MyFunc.getPlayingAreaFromId(playingAreaId: playingAreaToRetrieveId, successClosure: { result in
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

        // check for any overlapping playing areas
//        let matchingPlayingAreasArray = self.getOverlappingPlayingAreas(playingAreaRect: pitchMKMapRect)
//
//        if matchingPlayingAreasArray.isEmpty == false {
//
//          if matchingPlayingAreasArray.count == 1 {
//
//            self.playingArea = matchingPlayingAreasArray.first!
//            // only one matching playing area so use this
//
//          } else {
//
//            // multiple matching playing areas
//          }
//
//
//        } else {


        // get the PlayingArea corner coordinates from the size of heatmap
        self.bottomLeftCoord = CLLocationCoordinate2D(latitude: maxLat!, longitude: maxLong!)
        self.topLeftCoord = CLLocationCoordinate2D(latitude: minLat!, longitude: maxLong!)
        self.bottomRightCoord = CLLocationCoordinate2D(latitude: maxLat!, longitude: minLong!)
        self.topRightCoord  = CLLocationCoordinate2D(latitude: minLat!, longitude: minLong!)

        self.setMapViewZoom()

        // convert the coordinates to a codable subclass for saving
        let topLeftCoordToSave = CodableCLLCoordinate2D(latitude: self.topLeftCoord!.latitude, longitude: self.topLeftCoord!.longitude)
        let bottomLeftCoordToSave = CodableCLLCoordinate2D(latitude: self.bottomLeftCoord!.latitude, longitude: self.bottomLeftCoord!.longitude)
        let bottomRightCoordToSave = CodableCLLCoordinate2D(latitude: self.bottomRightCoord!.latitude, longitude: self.bottomRightCoord!.longitude)
        let topRightCoordToSave = CodableCLLCoordinate2D(latitude: self.topRightCoord!.latitude, longitude: self.topRightCoord!.longitude)

        // as we are creating a new playing area, default the name and venue to the placemark data
        if let firstCoordinate = self.heatmapperCoordinatesArray.first {
          self.getCLPlacemark(coordinate: firstCoordinate)
        }

        // now save the auto-generated PlayingArea coordinates for future use
        let playingAreaToSave = PlayingArea(bottomLeft:  bottomLeftCoordToSave, bottomRight: bottomRightCoordToSave, topLeft: topLeftCoordToSave, topRight: topRightCoordToSave, name: "", venue: "", sport: "", comments: "", isFavourite: false)
        MyFunc.savePlayingArea(playingAreaToSave)

        self.playingArea = playingAreaToSave
        self.workoutMetadata.playingAreaId = playingAreaToSave.id
//        }


        self.updateWorkout()
        self.updateAngleUI()


      case .success(let playingAreaRetrieved):
        MyFunc.logMessage(.debug, "Success retrieving PlayingArea! :")
        let playingAreaStr = String(describing: playingAreaRetrieved)
        MyFunc.logMessage(.debug, playingAreaStr)

        self.pitchField.text = playingAreaRetrieved.name
        self.venueField.text = playingAreaRetrieved.venue
        self.sportField.text = playingAreaRetrieved.sport

        let midpointLatitude = (playingAreaRetrieved.topLeft.latitude + playingAreaRetrieved.bottomRight.latitude) / 2
        let midpointLongitude = (playingAreaRetrieved.topLeft.longitude + playingAreaRetrieved.bottomRight.longitude) / 2
        self.overlayCenter = CLLocationCoordinate2D(latitude: midpointLatitude, longitude: midpointLongitude)

        // PlayingArea coordinates stored as Codable sub-class of CLLocationCoordinate2D so convert to original class (may be able to remove this?)
        let topLeftAsCoord = CLLocationCoordinate2D(latitude: playingAreaRetrieved.topLeft.latitude, longitude: playingAreaRetrieved.topLeft.longitude)
        let bottomLeftAsCoord = CLLocationCoordinate2D(latitude: playingAreaRetrieved.bottomLeft.latitude, longitude: playingAreaRetrieved.bottomLeft.longitude)
        let bottomRightAsCoord = CLLocationCoordinate2D(latitude: playingAreaRetrieved.bottomRight.latitude, longitude: playingAreaRetrieved.bottomRight.longitude)
        let topRightAsCoord = CLLocationCoordinate2D(latitude: playingAreaRetrieved.topRight.latitude, longitude: playingAreaRetrieved.topRight.longitude)

        self.bottomLeftCoord = bottomLeftAsCoord
        self.bottomRightCoord = bottomRightAsCoord
        self.topLeftCoord = topLeftAsCoord
        self.topRightCoord = topRightAsCoord
        self.playingArea = playingAreaRetrieved

      }
    })


    // getting the angle to rotate the overlay by from the CGPoints
    let pitchViewBottomLeft   : CGPoint = self.mapView.convert(bottomLeftCoord!, toPointTo: self.mapView)
    let pitchViewBottomRight  : CGPoint = self.mapView.convert(bottomRightCoord!, toPointTo: self.mapView)
    let pitchViewTopLeft      : CGPoint = self.mapView.convert(topLeftCoord!, toPointTo: self.mapView)

    let newWidth = CGPointDistance(from: pitchViewBottomLeft, to: pitchViewBottomRight)
    let newHeight = CGPointDistance(from: pitchViewBottomLeft, to: pitchViewTopLeft)

    // now add the view
    let newPitchView = UIImageView(frame: (CGRect(x: pitchViewBottomRight.x, y: pitchViewBottomRight.y, width: newWidth, height: newHeight)))
    let sportStr = sportField.text ?? ""
    updatePitchImage(sport: sportStr)
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
    newPitchView.setAnchorPoint(CGPoint(x: 0.5, y: 0.5))

    mapHeadingAtResizeOn = mapView.camera.heading
    pitchRotationAtResizeOn = rotation(from: newPitchView.transform)
    updateAngleUI()

    playingAreaAngleSaved = pitchAngle
    self.pitchAngleToApply = pitchAngle
    self.createPlayingAreaOverlay(topLeft: self.topLeftCoord!, bottomLeft: self.bottomLeftCoord!, bottomRight: self.bottomRightCoord!)
//    setMapViewZoom()
    setFavouritesButtonTitle()

  }

  func getOverlappingPlayingAreas(playingAreaRect: MKMapRect) -> [PlayingArea] {

    var matchingPlayingAreas = [PlayingArea]()

    let playingAreaArray = MyFunc.getPlayingAreas()

    for playingAreaRetrieved in playingAreaArray {
      // PlayingArea coordinates stored as Codable sub-class of CLLocationCoordinate2D so convert to original class (may be able to remove this?)
      let topLeftAsCoord = CLLocationCoordinate2D(latitude: playingAreaRetrieved.topLeft.latitude, longitude: playingAreaRetrieved.topLeft.longitude)
      let bottomLeftAsCoord = CLLocationCoordinate2D(latitude: playingAreaRetrieved.bottomLeft.latitude, longitude: playingAreaRetrieved.bottomLeft.longitude)
      let bottomRightAsCoord = CLLocationCoordinate2D(latitude: playingAreaRetrieved.bottomRight.latitude, longitude: playingAreaRetrieved.bottomRight.longitude)

      let playingAreaMapRect = createPlayingAreaMapRectFromCoordinates(topLeft: topLeftAsCoord, bottomLeft:bottomLeftAsCoord, bottomRight: bottomRightAsCoord)

      if playingAreaRect.intersects(playingAreaMapRect) {
        matchingPlayingAreas.append(playingAreaRetrieved)
      }
    }

    if matchingPlayingAreas.isEmpty == false {
      print("MatchingPlayingAreas!")
      print(String(describing: matchingPlayingAreas))
    }
    return matchingPlayingAreas
  }

  func setFavouritesButtonTitle() {
    if let isFavourite = playingArea?.isFavourite, isFavourite  {
      favouritesButton.setTitle("Remove Playing Area from Favourites", for: .normal)
    } else {
      favouritesButton.setTitle("Add Playing Area to Favourites", for: .normal)
    }

  }

  func createPlayingAreaOverlay(topLeft: CLLocationCoordinate2D, bottomLeft: CLLocationCoordinate2D, bottomRight: CLLocationCoordinate2D) {

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
    let playingAreaOverlay = PlayingAreaOverlay(pitchRect: pitchMKMapRect)
    mapView.insertOverlay(playingAreaOverlay, at: 0)

    self.playingAreaMapRect = pitchMKMapRect

  }

  func createPlayingAreaMapRectFromCoordinates(topLeft: CLLocationCoordinate2D, bottomLeft: CLLocationCoordinate2D, bottomRight: CLLocationCoordinate2D) -> MKMapRect {

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

    return pitchMKMapRect

  }




  func getMapRotation() -> CGFloat {

    // this function calculates the rotation of the map
    var rotationToApply : CGFloat = 0.0

    // apply different rotations depending upon whether the view is displayed
    // i.e. we are in resize mode
    if let newPitchView = self.view.viewWithTag(200) {
      rotationToApply = rotation(from: newPitchView.transform.inverted())
        rotationToApply = rotationToApply + .pi
    } else {
      rotationToApply = 0 - (pitchAngleToApply + .pi)

    }

    let mapViewHeading = mapView.camera.heading

    let mapViewHeadingInt = Int(mapViewHeading)
    let mapViewHeadingRadians = mapViewHeadingInt.degreesToRadians
    let angleIncMapRotation = rotationToApply - mapViewHeadingRadians
    updateAngleUI()
    return angleIncMapRotation

  }

  func mapView(_ mapView: MyMKMapView, rotationDidChange rotation: Double) {
    // this function just tracks any rotation changes in the map and prints them out
    mapHeadingAtResizeOff = rotation
    updateAngleUI()
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


  //  func loadTesterData() {
  //    let loadedTesterArray = MyFunc.getTesterData()
  //    if loadedTesterArray.isEmpty == false {
  //
  //      innerColourRed = loadedTesterArray[0]
  //      innerColourGreen = loadedTesterArray[1]
  //      innerColourBlue = loadedTesterArray[2]
  //      innerColourAlpha = loadedTesterArray[3]
  //      innerColourGradient = loadedTesterArray[4]
  //
  //      middleColourRed = loadedTesterArray[5]
  //      middleColourGreen = loadedTesterArray[6]
  //      middleColourBlue = loadedTesterArray[7]
  //      middleColourAlpha = loadedTesterArray[8]
  //      middleColourGradient = loadedTesterArray[9]
  //
  //      outerColourRed = loadedTesterArray[10]
  //      outerColourGreen = loadedTesterArray[11]
  //      outerColourBlue = loadedTesterArray[12]
  //      outerColourAlpha = loadedTesterArray[13]
  //      outerColourGradient = loadedTesterArray[14]
  //
  //    }
  //  }

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
    let workoutVenue = workoutMetadata.playingAreaVenue
    let workoutPitch = workoutMetadata.playingAreaName
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
    mapView.setCenter(self.overlayCenter!, animated: false)

    playingAreaBearing = bottomLeftCoord!.bearing(to: topLeftCoord!)
    let distanceToSet = mapView.camera.centerCoordinateDistance
    let cameraToApply = MKMapCamera(lookingAtCenter: self.overlayCenter!, fromDistance: distanceToSet, pitch: 0, heading: playingAreaBearing)
    self.mapView.setCamera(cameraToApply, animated: false)
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

  func getWorkoutData() {
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

  func getWorkout(workoutId: UUID, completion: @escaping ([HKWorkout]?, Error?) -> Void) {

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
        MyFunc.logMessage(.error, "Error getting route sample object : \(error.debugDescription)")
        return
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
          self.getPlayingArea()
          self.setMapViewZoom()
          self.createREHeatmap()

        }
      }
    }
    healthStore.execute(query)
  }

  func getCLPlacemark(coordinate: CLLocationCoordinate2D)  {

    let latitude = coordinate.latitude
    let longitude = coordinate.longitude
    let location = CLLocation(latitude: latitude, longitude: longitude)
    geocoder.reverseGeocodeLocation(location) { (placemarks, error) in

      if error != nil {
        MyFunc.logMessage(.debug, "No placemark found: \(error.debugDescription)")
      } else {
        guard let returnedPlacemarks = placemarks else {
          MyFunc.logMessage(.debug, "No placemark found: \(error.debugDescription)")
          return

        }
        let placemark =  returnedPlacemarks.first!
        var placemarkStr : String = ""

        let thoroughfare = placemark.thoroughfare ?? ""
        let locality = placemark.locality ?? ""
        if thoroughfare != "" && locality != "" {
          placemarkStr = (thoroughfare + ", " + locality)
        } else {
          placemarkStr =  "No placemark found"
        }

        self.pitchField.text = placemarkStr

      }

    }

  }

  func angleInDegrees(between starting: CGPoint, ending: CGPoint) -> CGFloat {
    let center = CGPoint(x: ending.x - starting.x, y: ending.y - starting.y)
    let radians = atan2(center.y, center.x)
    var degrees = radians * 180 / .pi
    degrees = degrees > 0 ? degrees : degrees + degrees

    return degrees
  }

  func angleInRadians(between starting: CGPoint, ending: CGPoint) -> CGFloat {
    let center = CGPoint(x: ending.x - starting.x, y: ending.y - starting.y)
    let radians = atan2(center.y, center.x)
    return radians
  }

  func addHeatmapPoint(coordinate:CLLocationCoordinate2D){
    // create MKCircle for each heatmap point
    let heatmapPointCircle = MKCircle(center: coordinate, radius: CLLocationDistance(radius))
    mapView.addOverlay(heatmapPointCircle)
  }

//  func addAnnotation(coordinate:CLLocationCoordinate2D){
//    let annotation = MKPointAnnotation()
//    annotation.coordinate = coordinate
//    mapView.addAnnotation(annotation)
//  }
//
//  func setPinUsingMKAnnotation(coordinate: CLLocationCoordinate2D, title: String) {
//    let annotation = MKPointAnnotation()
//    annotation.coordinate = coordinate
//    annotation.title = title
//    mapView.addAnnotation(annotation)
//  }
//
//  func addPinImage(point: CGPoint, colour: UIColor, tag: Int) {
//    let pinImageView = UIImageView()
//    pinImageView.frame = CGRect(x: point.x, y: point.y, width: 20, height: 20)
//    pinImageView.image = UIImage(systemName: "mappin")
//    pinImageView.tintColor = colour
//    pinImageView.tag = tag
//    mapView.addSubview(pinImageView)
//  }

  func removeViewWithTag(tag: Int) {
    if let viewToRemove = self.view.viewWithTag(tag) {
      viewToRemove.removeFromSuperview()
    }
  }

//  func removeAllPins() {
//    removeViewWithTag(tag: 101)
//    removeViewWithTag(tag: 102)
//    removeViewWithTag(tag: 103)
//    removeViewWithTag(tag: 104)
//    removeViewWithTag(tag: 301)
//    removeViewWithTag(tag: 302)
//    removeViewWithTag(tag: 303)
//    removeViewWithTag(tag: 304)
//  }
//
//  func removeAllAnnotations() {
//    let allAnnotations = self.mapView.annotations
//    self.mapView.removeAnnotations(allAnnotations)
//  }
//
//  func removeAllPinsAndAnnotations () {
//    removeAllPins()
//    removeAllAnnotations()
//  }

  func updateWorkout()  {

    guard let workoutId = heatmapWorkoutId else {
      MyFunc.logMessage(.error, "Invalid heatmapWorkoutId passed to SavedHeatmapViewController: \(String(describing: heatmapWorkoutId))")
      return
    }

    let activity = activityField.text ?? ""
    let venue = venueField.text ?? ""
    let sport = sportField.text ?? ""
    let pitch = pitchField.text ?? ""
    let playingAreaId = workoutMetadata.playingAreaId

    let workoutMetadataToSave = WorkoutMetadata(workoutId: workoutId, playingAreaId: playingAreaId, activity: activity, sport: sport, playingAreaVenue: venue, playingAreaName: pitch)

    if let row = self.workoutMetadataArray.firstIndex(where: {$0.workoutId == workoutId}) {
      workoutMetadataArray[row] = workoutMetadataToSave
    } else {
      workoutMetadataArray.append(workoutMetadataToSave)
    }
    MyFunc.saveWorkoutMetadata(workoutMetadataArray)
    MyFunc.logMessage(.debug, "WorkoutMetadata saved in SavedHeatmapViewController \(String(describing: workoutMetadataToSave))")

  }
//
//  func getMapRectFromCoordinates(maxLat: Double, minLat: Double, maxLong: Double, minLong: Double) -> MKMapRect {
//
//    let minCoord = CLLocationCoordinate2D(latitude: minLat, longitude: minLong)
//    let maxCoord = CLLocationCoordinate2D(latitude: maxLat, longitude: maxLong)
//
//    let midpointLatitude = (minCoord.latitude + maxCoord.latitude) / 2
//    let midpointLongitude = (minCoord.longitude + maxCoord.longitude) / 2
//    self.overlayCenter = CLLocationCoordinate2D(latitude: midpointLatitude, longitude: midpointLongitude)
//
//    // get the max and min X and Y points from the above coordinates as MKMapPoints
//    let minX = MKMapPoint(minCoord).x
//    let maxX = MKMapPoint(maxCoord).x
//    let minY = MKMapPoint(minCoord).y
//    let maxY = MKMapPoint(maxCoord).y
//
//    // this code ensures the pitch size is larger than the heatmap by adding a margin
//    // get the dimensions of the rectangle from the distance between the point extremes
//    var rectWidth = maxX - minX
//    var rectHeight = minY - maxY
//    // set the scale of the border
//    let rectMarginScale = 0.1
//    // set the rectangle origin as the plot dimensions plus the border
//    let rectX = minX - (rectWidth * rectMarginScale)
//    let rectY = minY + (rectHeight * rectMarginScale)
//
//    // increase the rectangle width and height by the border * 2
//    rectWidth = rectWidth + (rectWidth * rectMarginScale * 2)
//    rectHeight = rectHeight + (rectHeight * rectMarginScale * 2)
//
//    let pitchMKMapRect = MKMapRect.init(x: rectX, y: rectY, width: rectWidth, height: rectHeight)
//    return pitchMKMapRect
//  }

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

    if overlay is PlayingAreaOverlay {
      //      if let pitchImage = UIImage(named: "Figma Pitch 11 Green.png")
      //      {

      var pitchImage = UIImage()
      switch playingArea?.sport {
      case "Football":
        pitchImage = UIImage(named: "Football pitch.png")!
      case "5-a-side":
        pitchImage = UIImage(named: "5-a-side pitch.png")!
      case "Rugby":
        pitchImage = UIImage(named: "Rugby Union pitch.png")!
      case "Tennis":
        pitchImage = UIImage(named: "Tennis court.png")!
      case "None":
        pitchImage = UIImage(named: "Figma Pitch 11 Green.png")!
      default:
        pitchImage = UIImage(named: "Figma Pitch 11 Green.png")!
      }


      // get the rotation of the pitchView
      let angleIncMapRotation = getMapRotation()
      let footballPitchOverlayRenderer = PlayingAreaOverlayRenderer(overlay: overlay, overlayImage: pitchImage, angle: angleIncMapRotation, workoutId: heatmapWorkoutId!)
      footballPitchOverlayRenderer.alpha = 1

      return footballPitchOverlayRenderer
    }
    //    }

    // should never call this... needs to be fixed
    MyFunc.logMessage(.error, "No MKOverlayRenderer returned")
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
      if activityArray.isEmpty == false {
        activityField.text = activityArray[row].name
        sportField.text = activityArray[row].sport.rawValue
      }
    } else {
      sportField.text = sportArray[row].rawValue
    }
    updateWorkout()

    self.view.endEditing(true)
  }

}

