//
//  PlayingAreaViewController.swift
//  Heatmapper
//
//  Created by Richard English on 12/05/2022.
//  Copyright © 2022 Richard English. All rights reserved.
//

import UIKit
import MapKit
import HealthKit
import CoreLocation

class PlayingAreaViewController: UIViewController, MyMapListener {
  
  var playingAreaToUpdate         : PlayingArea?
  var heatmapperCoordinatesArray  = [CLLocationCoordinate2D]()
  var heatmapperLocationsArray    = [CLLocation]()
  var heatmapWorkoutId            : UUID?
  var workoutMetadata             = WorkoutMetadata(workoutId: UUID.init(), activity: "", sport: "", playingAreaVenue: "", playingAreaName: "")
  var workoutMetadataArray        =  [WorkoutMetadata]()
  var retrievedWorkout            : HKWorkout?
  private var workoutArray        = [HKWorkout]()
  private var workoutInfoArray    = [WorkoutInfo]()
  
  var measurementFormatter        = MeasurementFormatter()
  var unitSpeed                   : UnitSpeed  = .metersPerSecond
  
  var resizeOn                    : Bool = true
  var playingAreaMapRect          : MKMapRect?
  //  var heatmapPointCircle          : MKCircle?
  
  let healthStore                 = HKHealthStore()
  let theme                       = ColourTheme()

  var pitchRotationAtResizeOff    : CGFloat = 0.0
  var pitchRotationAtResizeOn     : CGFloat = 0.0
  
  var mapHeadingAtResizeOn        : Double = 0.0
  var mapHeadingAtResizeOff       : Double = 0.0
  
  var playingAreaAngleSavedAfterResize       : CGFloat = 0.0
  var playingAreaAngleSaved       : CGFloat = 0.0
  var pitchAngleToApply           : CGFloat = 0.0
  
  var bottomLeftCoord             : CLLocationCoordinate2D?
  var topLeftCoord                : CLLocationCoordinate2D?
  var bottomRightCoord            : CLLocationCoordinate2D?
  var topRightCoord               : CLLocationCoordinate2D?
  var playingAreaBearing          : Double = 0.0
  
  var activityArray               = [Activity]()
  var sportArray                  = [Sport]()
  
  var overlayCenter               : CLLocationCoordinate2D?
  
  let activityPicker              = UIPickerView()
  let sportPicker                 = UIPickerView()

  var selectedIndexPath           : Int?


  lazy var dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.timeStyle = .short
    formatter.dateStyle = .short
    return formatter
  } ()

  @IBOutlet weak var heightAndWeightStackView: UIStackView!
  @IBOutlet weak var heightStepper: UIStepper!
  @IBOutlet weak var widthStepper: UIStepper!
  
  @IBOutlet weak var resetPlayingAreaButton: ThemeActionButton!
  @IBOutlet weak var resizeButton: ThemeActionButton!
  @IBOutlet weak var sportField: ThemeMediumFontTextField!
  @IBOutlet weak var venueField: ThemeMediumFontTextField!
  @IBOutlet weak var nameField: ThemeMediumFontTextField!
  @IBOutlet weak var mapView: MyMKMapView!
  @IBOutlet weak var mapTypeSegmentedControl: UISegmentedControl!
  
  @IBOutlet weak var workoutTableView: ThemeTableViewNoBackground!

  @IBAction func btnResize(_ sender: Any) {
    if resizeOn == true {
      // turn everything off (as it's on)
      
      resizeOn = false
      resizeButton.setTitle("Resize playing area", for: .normal)
      resizeButton.tintColor = UIColor.systemGreen
      
      // record the map heading at end of resizing
      mapHeadingAtResizeOff = mapView.getRotation() ?? 0
      
      saveResizedPlayingArea()
      
      playingAreaAngleSavedAfterResize = pitchRotationAtResizeOff
      let playingAreaAngleSavedAfterResizeDegrees = playingAreaAngleSavedAfterResize.radiansToDegrees

      mapView.camera.heading = playingAreaAngleSavedAfterResizeDegrees

      setMapViewZoom()
      let distanceToSet = mapView.camera.centerCoordinateDistance
      let cameraToApply = MKMapCamera(lookingAtCenter: self.overlayCenter!, fromDistance: distanceToSet, pitch: 0, heading: playingAreaBearing)
      self.mapView.setCamera(cameraToApply, animated: false)
      
      // removes the pitchView
      removeViewWithTag(tag: 200)
      
      //      resetPlayingAreaButton.isHidden = true
      heightAndWeightStackView.isHidden = true
      
    } else {
      // turn everything on (as it's off)
      resizeOn = true
      resizeButton.setTitle("Save", for: .normal)
      //      resizeButton.tintColor = UIColor.systemRed
      //      resetPlayingAreaButton.isHidden = false
      heightAndWeightStackView.isHidden = false
      removeAllPinsAndAnnotations()
      enterResizeMode()
      updateSteppers()
    }
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

  override func viewDidLoad() {
    super.viewDidLoad()
    initialiseUI()
    getStaticData()
    getData()

    self.navigationItem.rightBarButtonItem = editButtonItem
  }

  override func setEditing(_ editing: Bool, animated: Bool) {
    super.setEditing(editing, animated: true)
    if editing {
      print("Edit mode on")
      venueField.isEnabled = true
      sportField.isEnabled = true
      nameField.isEnabled = true

    } else {
      print("Edit mode off")
      venueField.isEnabled = false
      sportField.isEnabled = false
      nameField.isEnabled = false

      savePlayingArea()

    }
  }



  func initialiseUI() {

    workoutTableView.delegate = self
    workoutTableView.dataSource = self
    workoutTableView.allowsSelection = true
    mapView.delegate = self
    mapView.listener = self
    resizeOn = false
    heightAndWeightStackView.isHidden = true
    sportPicker.delegate = self
    sportPicker.dataSource = self
    sportField.inputView = sportPicker
    mapView.showsUserLocation = false
  }

  func getStaticData() {
    activityArray = MyFunc.getHeatmapperActivityDefaults()
    sportArray = Sport.allCases.map { $0 }
  }

  func getData() {
    getPlayingAreaOnLoad()
    getWorkoutsForPlayingArea()
  }

  func getPlayingAreaOnLoad() {


    if let playingArea  = playingAreaToUpdate  {

    nameField.text = playingArea.name
    venueField.text = playingArea.venue
    sportField.text = playingArea.sport

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
      self.isEditing = false

    } else {

      // no Playing Area passed in so we will create new one

      MyFunc.logMessage(.debug, "No PlayingArea passed in to PlayingAreasViewController")

      // get the user's location
      let userLocation = LocationManager.sharedInstance.currentLocation
      let userCoordinate = userLocation.coordinate

      let topLeftLocation = userLocation.movedBy(latitudinalMeters: 52.5, longitudinalMeters: 34)
      let bottomRightLocation = userLocation.movedBy(latitudinalMeters: -52.5, longitudinalMeters: -34)

      let minCoord = topLeftLocation.coordinate
      let maxCoord = bottomRightLocation.coordinate

      let maxLat = maxCoord.latitude
      let minLat = minCoord.latitude
      let maxLong = maxCoord.longitude
      let minLong = minCoord.longitude

      // set the map region
      self.overlayCenter = CLLocationCoordinate2D(latitude: userCoordinate.latitude, longitude: userCoordinate.longitude)

      // get the max and min X and Y points from the above coordinates as MKMapPoints
      let minX = MKMapPoint(minCoord).x
      let maxX = MKMapPoint(maxCoord).x
      let minY = MKMapPoint(minCoord).y
      let maxY = MKMapPoint(maxCoord).y

      // this code ensures the pitch size is larger than the heatmap by adding a margin
      // get the dimensions of the rectangle from the distance between the point extremes
//      var rectWidth = maxX - minX
//      var rectHeight = minY - maxY
//      // set the scale of the border

      // setting default pitch size to football pitch width and height
      var rectWidth : Double = 68.0
      var rectHeight  : Double = 105.0
      let rectMarginScale = 0.1

      // set the rectangle origin as the plot dimensions plus the border
      let rectX = minX - (rectWidth * rectMarginScale)
      let rectY = minY + (rectHeight * rectMarginScale)

      // increase the rectangle width and height by the border * 2
      rectWidth = rectWidth + (rectWidth * rectMarginScale * 2)
      rectHeight = rectHeight + (rectHeight * rectMarginScale * 2)

      let pitchMKMapRect = MKMapRect.init(x: rectX, y: rectY, width: rectWidth, height: rectHeight)
      self.playingAreaMapRect = pitchMKMapRect


      // get the PlayingArea corner coordinates from the size of heatmap
      self.bottomLeftCoord = CLLocationCoordinate2D(latitude: maxLat, longitude: maxLong)
      self.topLeftCoord = CLLocationCoordinate2D(latitude: minLat, longitude: maxLong)
      self.bottomRightCoord = CLLocationCoordinate2D(latitude: maxLat, longitude: minLong)
      self.topRightCoord  = CLLocationCoordinate2D(latitude: minLat, longitude: minLong)

      // convert the coordinates to a codable subclass for saving
      let topLeftCoordToSave = CodableCLLCoordinate2D(latitude: self.topLeftCoord!.latitude, longitude: self.topLeftCoord!.longitude)
      let bottomLeftCoordToSave = CodableCLLCoordinate2D(latitude: self.bottomLeftCoord!.latitude, longitude: self.bottomLeftCoord!.longitude)
      let bottomRightCoordToSave = CodableCLLCoordinate2D(latitude: self.bottomRightCoord!.latitude, longitude: self.bottomRightCoord!.longitude)
      let topRightCoordToSave = CodableCLLCoordinate2D(latitude: self.topRightCoord!.latitude, longitude: self.topRightCoord!.longitude)

      self.isEditing = true

      // as we are creating a new playing area, default the name and venue to the placemark data
      var geocoder            : CLGeocoder!
      geocoder = CLGeocoder()
      geocoder.reverseGeocodeLocation(userLocation) { (placemarks, error) in

        if error != nil {
          MyFunc.logMessage(.debug, "No placemark found: \(error.debugDescription)")
        } else {
          guard let returnedPlacemarks = placemarks else {
            MyFunc.logMessage(.debug, "No placemark found: \(error.debugDescription)")
            return

          }
          let placemark =  returnedPlacemarks.first!
          var placemarkStr : String = ""
          print ("Placemark returned: ")
          print (String(describing: placemark.locality))
          print (String(describing: placemark.thoroughfare))

          let thoroughfare = placemark.thoroughfare ?? ""
          let locality = placemark.locality ?? ""
          if thoroughfare != "" && locality != "" {
            placemarkStr = (thoroughfare + ", " + locality)
          } else {
            placemarkStr =  "No placemark found"
          }

          self.nameField.text = placemarkStr
          // now save the auto-generated PlayingArea coordinates for future use
          let playingAreaToSave = PlayingArea(bottomLeft:  bottomLeftCoordToSave, bottomRight: bottomRightCoordToSave, topLeft: topLeftCoordToSave, topRight: topRightCoordToSave, name: placemarkStr, venue: "", sport: "", comments: "", isFavourite: true)
          MyFunc.savePlayingArea(playingAreaToSave)

          self.playingAreaToUpdate = playingAreaToSave
        }

      }


    }

    // getting the angle to rotate the overlay by from the CGPoints
    // simply doing this as it seems to work better than using coordinate angles
    let pitchViewBottomLeft   : CGPoint = self.mapView.convert(bottomLeftCoord!, toPointTo: self.mapView)
    let pitchViewBottomRight  : CGPoint = self.mapView.convert(bottomRightCoord!, toPointTo: self.mapView)
    //        let pitchViewTopRight     : CGPoint = self.mapView.convert(topRightCoord!, toPointTo: self.mapView)
    let pitchViewTopLeft      : CGPoint = self.mapView.convert(topLeftCoord!, toPointTo: self.mapView)

    let newWidth = CGPointDistance(from: pitchViewBottomLeft, to: pitchViewBottomRight)
    let newHeight = CGPointDistance(from: pitchViewBottomLeft, to: pitchViewTopLeft)

    // now add the view
    let newPitchView = UIImageView(frame: (CGRect(x: pitchViewBottomRight.x, y: pitchViewBottomRight.y, width: newWidth, height: newHeight)))
    let pitchImageGreen = UIImage(named: "Figma Pitch 11 Green")
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
    newPitchView.setAnchorPoint(CGPoint(x: 0.5, y: 0.5))

    mapHeadingAtResizeOn = mapView.camera.heading
    pitchRotationAtResizeOn = rotation(from: newPitchView.transform)

    playingAreaAngleSaved = pitchAngle
    self.pitchAngleToApply = pitchAngle
    self.createPitchOverlay(topLeft: self.topLeftCoord!, bottomLeft: self.bottomLeftCoord!, bottomRight: self.bottomRightCoord!)
    self.setMapViewZoom()


  }



  func getWorkoutsForPlayingArea() {

    workoutInfoArray.removeAll()

    loadWorkouts { (workouts, error) in
      guard let workoutsReturned = workouts else {
        MyFunc.logMessage(.debug, "No workouts returned")
        return
      }


      self.workoutArray = workoutsReturned

      for workoutToProcess in workoutsReturned {
        let workoutToAppend = WorkoutInfo(uuid: workoutToProcess.uuid, samples: false, locations: false, sampleCount: 0, locationsCount: 0)
        self.workoutInfoArray.append(workoutToAppend)
      }
      self.workoutMetadataArray = MyFunc.getWorkoutMetadata()

      let workoutMetadataForPlayingAreaArray = self.workoutMetadataArray.filter {$0.playingAreaId == self.playingAreaToUpdate?.id }
      let workoutMetadataArrayIdsOnly = workoutMetadataForPlayingAreaArray.map { $0.workoutId}

      let workoutForPlayingAreaArray = self.workoutArray.filter { workoutMetadataArrayIdsOnly.contains($0.uuid) }
      self.workoutArray = workoutForPlayingAreaArray

      self.workoutTableView.reloadData()
    }


  }

  // retrieve all Heatmapper workouts
  func loadWorkouts(completion: @escaping ([HKWorkout]?, Error?) -> Void) {

    let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
    let sourcePredicate = HKQuery.predicateForObjects(from: .default())

    let query = HKSampleQuery(sampleType: .workoutType(), predicate: sourcePredicate, limit: 0, sortDescriptors: [sortDescriptor]) { (query, samples, error) in
      DispatchQueue.main.async {
        guard
          let samples = samples as? [HKWorkout], error == nil
        else {
          completion(nil, error)
          return
        }
        completion(samples, nil)
      }
    }
    healthStore.execute(query)

  }


  
  func savePlayingArea() {
    
    // convert the coordinates to a codable subclass for saving
    let topLeftCoordToSave = CodableCLLCoordinate2D(latitude: self.topLeftCoord!.latitude, longitude: self.topLeftCoord!.longitude)
    let bottomLeftCoordToSave = CodableCLLCoordinate2D(latitude: self.bottomLeftCoord!.latitude, longitude: self.bottomLeftCoord!.longitude)
    let bottomRightCoordToSave = CodableCLLCoordinate2D(latitude: self.bottomRightCoord!.latitude, longitude: self.bottomRightCoord!.longitude)
    let topRightCoordToSave = CodableCLLCoordinate2D(latitude: self.topRightCoord!.latitude, longitude: self.topRightCoord!.longitude)
    
    let nameToSave = nameField.text ?? ""
    let venueToSave = venueField.text ?? ""
    let sportToSave = sportField.text ?? ""


    let playingAreaToSave = PlayingArea(playingAreaId: playingAreaToUpdate!.id, bottomLeft:  bottomLeftCoordToSave, bottomRight: bottomRightCoordToSave, topLeft: topLeftCoordToSave, topRight: topRightCoordToSave, name: nameToSave, venue: venueToSave,  sport: sportToSave, comments: "", isFavourite: true)


    MyFunc.savePlayingArea(playingAreaToSave)

  }
  

  func updateSteppers() {
    guard let playingAreaView = self.view.viewWithTag(200) else {
      MyFunc.logMessage(.debug, "Cannot find pitchView to save")
      return
    }
    
    heightStepper.value = playingAreaView.frame.height
    widthStepper.value = playingAreaView.frame.width
    
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
    var pitchMapTopLeftCoordinate     : CLLocationCoordinate2D = mapView.convert(pitchMapTopLeftCGPoint, toCoordinateFrom: self.mapView)
    var pitchMapBottomLeftCoordinate  : CLLocationCoordinate2D = mapView.convert(pitchMapBottomLeftCGPoint, toCoordinateFrom: self.mapView)
    var pitchMapBottomRightCoordinate : CLLocationCoordinate2D = mapView.convert(pitchMapBottomRightCGPoint, toCoordinateFrom: self.mapView)
    var pitchMapTopRightCoordinate    : CLLocationCoordinate2D = mapView.convert(pitchMapTopRightCGPoint, toCoordinateFrom: self.mapView)
    
    //this logic always swaps the TopLeft and BottomRight
    // was originally an if-then-else - consider refactoring to remove
    
    print("Swapping TL and BR: SavePitchCoordinates")
    let topLeftToSwap = pitchMapTopLeftCoordinate
    pitchMapTopLeftCoordinate = pitchMapBottomRightCoordinate
    pitchMapBottomRightCoordinate = topLeftToSwap
    let bottomLeftToSwap = pitchMapBottomLeftCoordinate
    pitchMapBottomLeftCoordinate = pitchMapTopRightCoordinate
    pitchMapTopRightCoordinate = bottomLeftToSwap
    
    
    playingAreaAngleSavedAfterResize = angleInRadians(between: pitchMapBottomLeftCGPoint, ending: pitchMapBottomRightCGPoint)
    
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

    
    let nameToSave = nameField.text
    let venueToSave = venueField.text
    let sportToSave = sportField.text
    
    let playingAreaToSave = PlayingArea(playingAreaId: playingAreaToUpdate!.id, bottomLeft:  bottomLeftCoordToSave, bottomRight: bottomRightCoordToSave, topLeft: topLeftCoordToSave, topRight: topRightCoordToSave, name: nameToSave, venue: venueToSave,  sport: sportToSave, comments: "Resizing", isFavourite: true)
    
    MyFunc.savePlayingArea(playingAreaToSave)
    
    // store the coordinate in the VC's corner variables
    // consider revising above code to use these earlier and avoid having to create new variables for the TL/BR swap
    self.topLeftCoord         = pitchMapTopLeftCoordinate
    self.bottomLeftCoord      = pitchMapBottomLeftCoordinate
    self.topRightCoord        = pitchMapTopRightCoordinate
    self.bottomRightCoord     = pitchMapBottomRightCoordinate
    
    playingAreaBearing = pitchMapBottomLeftCoordinate.bearing(to: pitchMapTopLeftCoordinate)
    let playingAreaBearingStr = String(describing: playingAreaBearing)
    print("playingAreaBearing: \(playingAreaBearingStr)")
    
  }
  
  
  func enterResizeMode() {
    
    let playingArea : PlayingArea = playingAreaToUpdate!
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
    
    // now need to size the pitchView from the MapView information
    // we have the mapView rect from the overlay and the coordinates
    
    let pitchViewBottomLeft   : CGPoint = self.mapView.convert(bottomLeftCoord!, toPointTo: self.mapView)
    let pitchViewTopLeft      : CGPoint = self.mapView.convert(topLeftCoord!, toPointTo: self.mapView)
    let pitchViewBottomRight  : CGPoint = self.mapView.convert(bottomRightCoord!, toPointTo: self.mapView)
    
    
    let newWidth = CGPointDistance(from: pitchViewBottomLeft, to: pitchViewBottomRight)
    let newHeight = CGPointDistance(from: pitchViewBottomLeft, to: pitchViewTopLeft)
    
    // now add the view
    let newPitchView = UIImageView(frame: (CGRect(x: pitchViewBottomRight.x, y: pitchViewBottomRight.y, width: newWidth, height: newHeight)))
    let pitchImageGreen = UIImage(named: "Figma Pitch 11 Green")
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
    //      updateAngleUI()
    
    //remove the pitch MKMapOverlay
    if let overlays = mapView?.overlays {
      for overlay in overlays {
        if overlay is FootballPitchOverlay {
          mapView?.removeOverlay(overlay)
        }
      }
    }
    
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
    mapView.insertOverlay(adjustedPitchOverlay, at: 0)
    //    mapView.addOverlay(adjustedPitchOverlay)
    
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
        rotationToApply = rotationToApply + .pi
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
    //    updateAngleUI()
    return angleIncMapRotation
    
  }
  
  
  func mapView(_ mapView: MyMKMapView, rotationDidChange rotation: Double) {
    // this function just tracks any rotation changes in the map and prints them out
    mapHeadingAtResizeOff = rotation
    //    updateAngleUI()
  }
  
  func getDocumentsDirectory() -> URL {
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    let documentsDirectory = paths[0]
    return documentsDirectory
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
  
  func addAnnotation(coordinate:CLLocationCoordinate2D){
    let annotation = MKPointAnnotation()
    annotation.coordinate = coordinate
    mapView.addAnnotation(annotation)
  }
  
  func setPinUsingMKAnnotation(coordinate: CLLocationCoordinate2D, title: String) {
    let annotation = MKPointAnnotation()
    annotation.coordinate = coordinate
    annotation.title = title
    mapView.addAnnotation(annotation)
  }
  
  func addPinImage(point: CGPoint, colour: UIColor, tag: Int) {
    let pinImageView = UIImageView()
    pinImageView.frame = CGRect(x: point.x, y: point.y, width: 20, height: 20)
    pinImageView.image = UIImage(systemName: "mappin")
    pinImageView.tintColor = colour
    pinImageView.tag = tag
    mapView.addSubview(pinImageView)
  }
  
  func removeViewWithTag(tag: Int) {
    if let viewToRemove = self.view.viewWithTag(tag) {
      viewToRemove.removeFromSuperview()
    }
  }
  
  func removeAllPins() {
    removeViewWithTag(tag: 101)
    removeViewWithTag(tag: 102)
    removeViewWithTag(tag: 103)
    removeViewWithTag(tag: 104)
    removeViewWithTag(tag: 301)
    removeViewWithTag(tag: 302)
    removeViewWithTag(tag: 303)
    removeViewWithTag(tag: 304)
  }
  
  func removeAllAnnotations() {
    let allAnnotations = self.mapView.annotations
    self.mapView.removeAnnotations(allAnnotations)
  }
  
  func removeAllPinsAndAnnotations () {
    removeAllPins()
    removeAllAnnotations()
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
  
  @objc func handleRotate(_ gesture: UIRotationGestureRecognizer) {
    guard let gestureView = gesture.view else {
      return
    }
    gestureView.transform = gestureView.transform.rotated(by: gesture.rotation)
    pitchRotationAtResizeOff += gesture.rotation
    //    updateAngleUI()
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
  
  
}

extension PlayingAreaViewController: MKMapViewDelegate {
  
  func mapViewDidFinishRenderingMap(_ mapView: MKMapView, fullyRendered: Bool) {
  }
  
  func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
    
    
    if overlay is FootballPitchOverlay {
      if let pitchImage = UIImage(named: "Figma Pitch 11 Green.png")
      {
        
        // get the rotation of the pitchView
        let angleIncMapRotation = getMapRotation()
        let footballPitchOverlayRenderer = FootballPitchOverlayRenderer(overlay: overlay, overlayImage: pitchImage, angle: angleIncMapRotation)
        
        footballPitchOverlayRenderer.alpha = 1
        
        return footballPitchOverlayRenderer
      }
    }
    
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

extension PlayingAreaViewController: UIPickerViewDelegate, UIPickerViewDataSource {
  
  func numberOfComponents(in pickerView: UIPickerView) -> Int {
    return 1
  }
  
  func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
    return sportArray.count
  }
  
  func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
    return sportArray[row].rawValue
  }
  
  func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
    
    sportField.text = sportArray[row].rawValue
    //    updateWorkout()
    self.view.endEditing(true)
  }
  
}


extension PlayingAreaViewController: UITableViewDelegate, UITableViewDataSource {

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return workoutArray.count
  }


  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

    let cell = workoutTableView.dequeueReusableCell(withIdentifier: "WorkoutTableViewCell", for: indexPath)

    let workoutStartDate = workoutArray[indexPath.row].startDate
    cell.textLabel!.text = dateFormatter.string(from: workoutStartDate)

//    cell.detailTextLabel!.text = playingAreaArray[indexPath.row].venue

    return cell
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

    selectedIndexPath = indexPath.row
    let workoutToSend = self.workoutArray[indexPath.row]
    self.performSegue(withIdentifier: "playingAreasToPlayingArea", sender: workoutToSend)
    //    self.playingAreaTableView.reloadData()

  }

  func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    return true
  }

  func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
    selectedIndexPath = nil

  }



  // this function controls the two swipe controls
  func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {

    let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { _, _, complete in

      self.workoutArray.remove(at: indexPath.row)
      tableView.deleteRows(at: [indexPath], with: .fade)
      //      MyFunc.saveHeatmapActivityDefaults(self.playingAreaArray)
      self.workoutTableView.reloadData()
      complete(true)
    }

    deleteAction.backgroundColor = .red
    deleteAction.image = UIImage(systemName: "trash")

    let editAction = UIContextualAction(style: .destructive, title: "Edit") { _, _, complete in
      // switch table into edit mode
      let playingAreaToSend = self.workoutArray[indexPath.row]
      self.performSegue(withIdentifier: "playingAreasToPlayingArea", sender: playingAreaToSend)

      complete(true)
    }

    editAction.backgroundColor = .systemGray
    editAction.image = UIImage(systemName: "pencil")

    let configuration = UISwipeActionsConfiguration(actions: [deleteAction, editAction])
    configuration.performsFirstActionWithFullSwipe = false
    return configuration
  }

}


