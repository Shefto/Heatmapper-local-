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
  var pitchOn                     : Bool = false
  var ResizeOn                    : Bool = false

  var heatmapPointCircle          : MKCircle?
  var reHeatmapPoint              : REHeatmapPoint?
  var reHeatmapPointImage         : UIImage?

  let healthstore                 = HKHealthStore()
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

  var blendMode                   = CGBlendMode.normal
  var innerColourGradient         : String = "0.1"
  var middleColourGradient        : String = "0.3"
  var outerColourGradient         : String = "0.5"
  var radius                      : Int = 2

  var touchView                   : UIView!

  var inProgressWheel       : UIActivityIndicatorView?
  // variable purely for the In Progress wheel
  public var showIndicator  : Bool = true {
    didSet{
      if (!showIndicator)
      {
        inProgressWheel?.stopAnimating()
      }
    }
  }
  var blendModeArray = [BlendMode]()
  var overlayCenter               : CLLocationCoordinate2D?
  // tester outlets


  @IBOutlet weak var innerRed: UITextField!
  @IBOutlet weak var innerGreen: UITextField!
  @IBOutlet weak var innerBlue: UITextField!
  @IBOutlet weak var innerAlpha: UITextField!
  @IBOutlet weak var innerGradient: UITextField!

  @IBOutlet weak var middleRed: UITextField!
  @IBOutlet weak var middleGreen: UITextField!
  @IBOutlet weak var middleBlue: UITextField!
  @IBOutlet weak var middleAlpha: UITextField!
  @IBOutlet weak var middleGradient: UITextField!

  @IBOutlet weak var outerRed: UITextField!
  @IBOutlet weak var outerGreen: UITextField!
  @IBOutlet weak var outerBlue: UITextField!
  @IBOutlet weak var outerAlpha: UITextField!

  @IBOutlet weak var blendModePicker: UIPickerView!
  @IBOutlet weak var outerGradient: UITextField!

  @IBOutlet weak var innerRedStepper: UIStepper!
  @IBOutlet weak var innerGreenStepper: UIStepper!
  @IBOutlet weak var innerBlueStepper: UIStepper!
  @IBOutlet weak var innerAlphaStepper: UIStepper!
  @IBOutlet weak var innerGradientStepper: UIStepper!

  @IBOutlet weak var middleRedStepper: UIStepper!
  @IBOutlet weak var middleGreenStepper: UIStepper!
  @IBOutlet weak var middleBlueStepper: UIStepper!
  @IBOutlet weak var middleAlphaStepper: UIStepper!
  @IBOutlet weak var middleGradientStepper: UIStepper!

  @IBOutlet weak var outerRedStepper: UIStepper!
  @IBOutlet weak var outerGreenStepper: UIStepper!
  @IBOutlet weak var outerBlueStepper: UIStepper!
  @IBOutlet weak var outerAlphaStepper: UIStepper!
  @IBOutlet weak var outerGradientStepper: UIStepper!

  @IBOutlet weak var radiusField: UITextField!
  @IBOutlet weak var radiusStepper: UIStepper!

  @IBOutlet weak var pitchSegmentedControl: UISegmentedControl!
  @IBOutlet weak var mapSegmentedControl: UISegmentedControl!

  @IBOutlet weak var panelSegmentedControl: UISegmentedControl!

  @IBOutlet weak var coloursStackView: UIStackView!
  @IBOutlet weak var lowerControlsStackView: UIStackView!

  @IBOutlet weak var resizeButton: UIButton!


  @IBAction func stepperRadius(_ sender: UIStepper) {
    radius = Int(sender.value)
    radiusField.text = String(describing: radius)
    refreshHeatmap()
  }


  @IBAction func segPanel(_ sender: UISegmentedControl) {
    switch sender.selectedSegmentIndex {
    case 0:
      coloursStackView.isHidden = false
      lowerControlsStackView.isHidden = false
    case 1:
      coloursStackView.isHidden = true
      lowerControlsStackView.isHidden = true
    default:
      coloursStackView.isHidden = false
      lowerControlsStackView.isHidden = false
    }


  }


  @IBAction func segMap(_ sender: UISegmentedControl) {
    switch sender.selectedSegmentIndex {
    case 0:
      self.mapView.mapType = .standard
    case 1:
      self.mapView.mapType = .satellite
    default:
      self.mapView.mapType = .standard
    }

  }

  @IBAction func segPitch(_ sender: UISegmentedControl) {

    switch sender.selectedSegmentIndex {
    case 0:
      pitchOn = true
    case 1:
      pitchOn = false
    default:
      pitchOn = true
    }

    refreshHeatmap()
  }

  @IBAction func stepperInnerRed(_ sender: UIStepper) {
    innerColourRed = String(format:"%.1f", sender.value)
    print(sender.value)
    innerRed.text = innerColourRed
    refreshHeatmap()
  }

  @IBAction func stepperInnerGreen(_ sender: UIStepper) {
    innerColourGreen = String(format:"%.1f", sender.value)
    innerGreen.text = innerColourGreen
    refreshHeatmap()
  }

  @IBAction func stepperInnerBlue(_ sender: UIStepper) {
    innerColourBlue = String(format:"%.1f", sender.value)
    innerBlue.text = innerColourBlue
    refreshHeatmap()
  }

  @IBAction func stepperInnerAlpha(_ sender: UIStepper) {
    innerColourAlpha = String(format:"%.1f", sender.value)
    innerAlpha.text = innerColourAlpha
    refreshHeatmap()
  }

  @IBAction func stepperInnerGradient(_ sender: UIStepper) {
    innerColourGradient = String(format:"%.1f", sender.value)
    innerGradient.text = innerColourGradient
    refreshHeatmap()
  }

  @IBAction func stepperMiddleRed(_ sender: UIStepper) {
    middleColourRed = String(format:"%.1f", sender.value)
    middleRed.text = middleColourRed
    refreshHeatmap()
  }

  @IBAction func stepperMiddleGreen(_ sender: UIStepper) {
    middleColourGreen = String(format:"%.1f", sender.value)
    middleGreen.text = middleColourGreen
    refreshHeatmap()
  }

  @IBAction func stepperMiddleBlue(_ sender: UIStepper) {
    middleColourBlue = String(format:"%.1f", sender.value)
    middleBlue.text = middleColourBlue
    refreshHeatmap()
  }

  @IBAction func stepperMiddleAlpha(_ sender: UIStepper) {
    middleColourAlpha = String(format:"%.1f", sender.value)
    middleAlpha.text = middleColourAlpha
    refreshHeatmap()
  }

  @IBAction func stepperMiddleGradient(_ sender: UIStepper) {
    middleColourGradient = String(format:"%.1f", sender.value)
    middleGradient.text = middleColourGradient
    refreshHeatmap()
  }

  @IBAction func stepperOuterRed(_ sender: UIStepper) {
    outerColourRed =  String(format:"%.1f", sender.value)
    outerRed.text = outerColourRed
    refreshHeatmap()
  }

  @IBAction func stepperOuterGreen(_ sender: UIStepper) {
    outerColourGreen = String(format:"%.1f", sender.value)
    outerGreen.text = outerColourGreen
    refreshHeatmap()
  }

  @IBAction func stepperOuterBlue(_ sender: UIStepper) {
    outerColourBlue = String(format:"%.1f", sender.value)
    outerBlue.text = outerColourBlue
    refreshHeatmap()
  }

  @IBAction func stepperOuterAlpha(_ sender: UIStepper) {
    outerColourAlpha = String(format:"%.1f", sender.value)
    outerAlpha.text = outerColourAlpha
    refreshHeatmap()
  }

  @IBAction func stepperOuterGradient(_ sender: UIStepper) {
    outerColourGradient = String(format:"%.1f", sender.value)
    outerGradient.text = outerColourGradient
    refreshHeatmap()
  }

  //  @IBAction func panGesture(_ sender: UIPanGestureRecognizer) {
  //    print("PanGesture recognized")
  //  }


  //  // this gesture created to enable user to tap points on which the overlay size will be based
  //  // not currently in use
  //  @IBAction func handleTap(_ sender: UITapGestureRecognizer) {
  //
  //    if sender.state == .ended {
  //      let tapGestureEndedLocation = sender.location(in: mapView)
  //      print("tapGestureEndedLocation: \(tapGestureEndedLocation)")
  ////      let tappedCoordinate = mapView.convert(tapGestureEndedLocation, toCoordinateFrom: mapView)
  //      //      addAnnotation(coordinate: tappedCoordinate)
  ////      pointCount += 1
  ////
  ////      if pointCount == 2 {
  ////
  ////        print("pointCount = 2 - time to insert the overlay")
  ////
  ////      }
  //    }
  //  }


  @IBAction func btnReset(_ sender: Any) {

    innerColourGradient = "0.1"
    middleColourGradient = "0.3"
    outerColourGradient = "0.5"

    innerColourRed = "1.0"
    innerColourGreen = "0.0"
    innerColourBlue = "0.0"
    innerColourAlpha = "0.9"

    middleColourRed = "1.0"
    middleColourBlue = "0.0"
    middleColourGreen = "0.5"
    middleColourAlpha = "0.5"

    outerColourRed = "1.0"
    outerColourBlue = "0.0"
    outerColourGreen = "1.0"
    outerColourAlpha = "0.3"
    radius = 2

    blendMode                   = CGBlendMode.normal
    loadTesterUI()
    refreshHeatmap()
  }



  @IBAction func textfieldEditingDidEnd(_ sender: Any) {
    print("textFieldEditingDidEnd")

    // update fields from UI values
    innerColourGradient =  innerGradient.text ?? ""
    middleColourGradient = middleGradient.text ?? ""
    outerColourGradient = outerGradient.text ?? ""

    innerColourRed = innerRed.text ?? ""
    innerColourBlue = innerBlue.text ?? ""
    innerColourGreen = innerGreen.text ?? ""
    innerColourAlpha = innerAlpha.text ?? ""

    middleColourRed = middleRed.text ?? ""
    middleColourBlue = middleBlue.text ?? ""
    middleColourGreen = middleGreen.text ?? ""
    middleColourAlpha = middleAlpha.text ?? ""

    outerColourRed = outerRed.text ?? ""
    outerColourBlue = outerBlue.text ?? ""
    outerColourGreen = outerGreen.text ?? ""
    outerColourAlpha = outerAlpha.text ?? ""

    refreshHeatmap()
  }

  @IBOutlet weak var mapView: MKMapView!

  @objc func resizeTap(_ sender: UITapGestureRecognizer? = nil) {
    print("resizeTap called")
  }

  @objc func resizePan(_ sender: UITapGestureRecognizer? = nil) {
    print("resizePan called")
  }

  func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
    return true
  }

  @IBAction func longPressRecognizer(_ sender: UILongPressGestureRecognizer) {
    print("longPress")
  }

  @IBAction func panGestureRecognizer(_ sender: UIPanGestureRecognizer) {
    print("panGestureRecognizer called")
  }


  // this is where the fun begins... resize mode
  @IBAction func btnResize(_ sender: Any) {

    if ResizeOn == false {
      ResizeOn = true
      resizeButton.setTitle("Resize ON", for: .normal)
      self.touchView.isHidden = true


    } else {
      ResizeOn = false
      resizeButton.setTitle("Resize OFF", for: .normal)
      self.touchView.isHidden = false

    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    // set up the tester picker
    blendModePicker.delegate = self
    blendModePicker.dataSource = self

    mapView.delegate = self

    let tapper = UITapGestureRecognizer(target: self,action: #selector(self.resizeTap(_:)))
    let panner = UIPanGestureRecognizer(target: self,action: #selector(self.resizePan(_:)))

    // add the touchView
    // doing this programmatically to avoid Storyboard complaining about overlap
    let mapViewFrame = mapView.globalFrame!
    touchView = UIView(frame: mapViewFrame)
    touchView.bounds = mapView.bounds
    touchView.isOpaque = true
    touchView.translatesAutoresizingMaskIntoConstraints = false
    touchView.isUserInteractionEnabled = true

    touchView.addGestureRecognizer(tapper)
    touchView.addGestureRecognizer(panner)

    self.mapView.addSubview(touchView)

    // this code ensures the touchView is completely aligned with the mapView
    let attributes: [NSLayoutConstraint.Attribute] = [.top, .bottom, .right, .left]
    NSLayoutConstraint.activate(attributes.map {
      NSLayoutConstraint(item: touchView as Any, attribute: $0, relatedBy: .equal, toItem: touchView.superview, attribute: $0, multiplier: 1, constant: 0)
    })

    let pitchImage = UIImage(named: "football pitch 11")
    let pitchView = UIImageView(image: pitchImage)
    pitchView.layer.opacity = 0.5

    self.touchView.addSubview(pitchView)

    self.loadUI()
    self.loadTesterData()
    self.loadTesterUI()


    // get workout data
    // all UI work is called within the function as the data retrieval works asynchronously
    getWorkoutData()
  }


  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    var testerArray = [String]()

    testerArray.append(innerColourRed)
    testerArray.append(innerColourGreen)
    testerArray.append(innerColourBlue)
    testerArray.append(innerColourAlpha)
    testerArray.append(innerColourGradient)

    testerArray.append(middleColourRed)
    testerArray.append(middleColourGreen)
    testerArray.append(middleColourBlue)
    testerArray.append(middleColourAlpha)
    testerArray.append(middleColourGradient)

    testerArray.append(outerColourRed)
    testerArray.append(outerColourGreen)
    testerArray.append(outerColourBlue)
    testerArray.append(outerColourAlpha)
    testerArray.append(outerColourGradient)


    MyFunc.saveTesterData(testerArray)
  }

  func refreshHeatmap() {

    if (self.showIndicator)
    {
      self.inProgressWheel?.startAnimating()
    }

    let overlays = mapView.overlays
    mapView.removeOverlays(overlays)

    self.createPitchOverlay()
    self.createREHeatmap()
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

  func loadUI() {
    blendModeArray = BlendMode.allCases.map { $0 }

    innerRedStepper.transform = innerRedStepper.transform.scaledBy(x: 0.75, y: 1.0)
    innerGreenStepper.transform = innerGreenStepper.transform.scaledBy(x: 0.75, y: 1.0)
    innerBlueStepper.transform = innerBlueStepper.transform.scaledBy(x: 0.75, y: 1.0)
    innerAlphaStepper.transform = innerAlphaStepper.transform.scaledBy(x: 0.75, y: 1.0)
    innerGradientStepper.transform = innerGradientStepper.transform.scaledBy(x: 0.75, y: 1.0)

    middleRedStepper.transform = middleRedStepper.transform.scaledBy(x: 0.75, y: 1.0)
    middleGreenStepper.transform = middleGreenStepper.transform.scaledBy(x: 0.75, y: 1.0)
    middleBlueStepper.transform = middleBlueStepper.transform.scaledBy(x: 0.75, y: 1.0)
    middleAlphaStepper.transform = middleAlphaStepper.transform.scaledBy(x: 0.75, y: 1.0)
    middleGradientStepper.transform = middleGradientStepper.transform.scaledBy(x: 0.75, y: 1.0)

    outerRedStepper.transform = outerRedStepper.transform.scaledBy(x: 0.75, y: 1.0)
    outerGreenStepper.transform = outerGreenStepper.transform.scaledBy(x: 0.75, y: 1.0)
    outerBlueStepper.transform = outerBlueStepper.transform.scaledBy(x: 0.75, y: 1.0)
    outerAlphaStepper.transform = outerAlphaStepper.transform.scaledBy(x: 0.75, y: 1.0)
    outerGradientStepper.transform = outerGradientStepper.transform.scaledBy(x: 0.75, y: 1.0)
    radiusStepper.transform = radiusStepper.transform.scaledBy(x: 0.75, y: 1.0)
  }

  func loadTesterUI() {

    innerGradient.text = innerColourGradient
    middleGradient.text = middleColourGradient
    outerGradient.text = outerColourGradient

    innerRed.text = innerColourRed
    innerBlue.text = innerColourBlue
    innerGreen.text = innerColourGreen
    innerAlpha.text = innerColourAlpha

    middleRed.text = middleColourRed
    middleBlue.text = middleColourBlue
    middleGreen.text = middleColourGreen
    middleAlpha.text = middleColourAlpha

    outerRed.text = outerColourRed
    outerBlue.text = outerColourBlue
    outerGreen.text = outerColourGreen
    outerAlpha.text = outerColourAlpha


    innerRedStepper.value = Double(innerColourRed)!
    innerGreenStepper.value = Double(innerColourGreen)!
    innerBlueStepper.value = Double(innerColourBlue)!
    innerAlphaStepper.value = Double(innerColourAlpha)!
    innerGradientStepper.value = Double(innerColourGradient)!

    middleRedStepper.value = Double(middleColourRed)!
    middleGreenStepper.value = Double(middleColourGreen)!
    middleBlueStepper.value = Double(middleColourBlue)!
    middleAlphaStepper.value = Double(middleColourAlpha)!
    middleGradientStepper.value = Double(middleColourGradient)!


    outerRedStepper.value = Double(outerColourRed)!
    outerGreenStepper.value = Double(outerColourGreen)!
    outerBlueStepper.value = Double(outerColourBlue)!
    outerAlphaStepper.value = Double(outerColourAlpha)!
    outerGradientStepper.value = Double(outerColourGradient)!
    radiusStepper.value = Double(radius)

    radiusField.text = String(radius)

    switch pitchOn {
    case true:
      pitchSegmentedControl.selectedSegmentIndex = 0
    case false:
      pitchSegmentedControl.selectedSegmentIndex = 1

    }

  }



  func setMapViewZoom(rect: MKMapRect) {
    let insets = UIEdgeInsets(top: 0, left: 5, bottom: 5, right: 5)
    //    let insets = UIEdgeInsets(top: 50, left: 50, bottom: 50, right: 50)

    mapView.setVisibleMapRect(rect, edgePadding: insets, animated: false)
    mapView.setCenter(overlayCenter!, animated: false)

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

    let midpointLatitude = (minCoord.latitude + maxCoord.latitude) / 2
    let midpointLongitude = (minCoord.longitude + maxCoord.longitude) / 2
    overlayCenter = CLLocationCoordinate2D(latitude: midpointLatitude, longitude: midpointLongitude)

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

    // this rectangle covers the area of all points
    let rect = MKMapRect.init(x: rectX, y: rectY, width: rectWidth, height: rectHeight)

    //  create an overlay of the pitch based upon the rectangle
    let footballPitch11Overlay = FootballPitchOverlay(pitchRect: rect)

    if pitchOn == true {
      self.mapView.addOverlay(footballPitch11Overlay)

    }

    //    self.addAnnotation(coordinate: mapCenter)
    //    self.mapView.setCenter(mapCenter, animated: true)
    self.setMapViewZoom(rect: rect)


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

  func initialiseProgressWheel()
  {
    inProgressWheel = UIActivityIndicatorView(style: .large)
    inProgressWheel?.translatesAutoresizingMaskIntoConstraints = false
    self.view.addSubview(inProgressWheel!)
    let sizeWidth = NSLayoutConstraint(item: inProgressWheel!, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 0.0, constant: 60)
    let sizeHeight = NSLayoutConstraint(item: inProgressWheel!, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 0.0, constant: 60)
    let CenterX = NSLayoutConstraint(item: inProgressWheel!, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1.0, constant: 0)
    let CenterY = NSLayoutConstraint(item: inProgressWheel!, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1.0, constant: 0)

    inProgressWheel?.addConstraints([sizeWidth,sizeHeight])
    self.view.addConstraints([CenterX,CenterY])
    self.view.updateConstraints()
  }


}

extension REHeatmapViewController: MKMapViewDelegate {

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


      //      let circleRenderer = HeatmapPointCircleRenderer(circle: overlay as! MKCircle)
      let circleRenderer = HeatmapPointCircleRenderer(circle: overlay as! MKCircle,
                                                      innerColourArray: innerColourArray, middleColourArray: middleColourArray, outerColourArray: outerColourArray, gradientLocationsArray: gradientLocationsArray, blendMode: blendMode)

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
    var heatmapPointAnnotationView: MKAnnotationView? = self.mapView.dequeueReusableAnnotationView(withIdentifier: reuseId)

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

extension REHeatmapViewController: UIPickerViewDelegate, UIPickerViewDataSource {
  func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
    MyFunc.logMessage(.debug, "REHeatmapViewController.didSelectRow: \(row)")

    let blendModeSelected = blendModeArray[row]

    switch blendModeSelected {
    case .normal:
      blendMode = .normal
    case .multiply:
      blendMode = .multiply
    case .screen:
      blendMode = .screen
    case .overlay:
      blendMode = .overlay
    case .darken:
      blendMode = .darken
    case .lighten:
      blendMode = .lighten
    case .colorDodge:
      blendMode = .colorDodge
    case .colorBurn:
      blendMode = .colorBurn
    case .softLight:
      blendMode = .softLight
    case .hardLight:
      blendMode = .hardLight
    case .difference:
      blendMode = .difference
    case .exclusion:
      blendMode = .exclusion
    case .hue:
      blendMode = .hue
    case .saturation:
      blendMode = .saturation
    case .color:
      blendMode = .color
    case .luminosity:
      blendMode = .luminosity
    case .clear:
      blendMode = .clear
    case .copy:
      blendMode = .copy
    case .sourceIn:
      blendMode = .sourceIn
    case .sourceOut:
      blendMode = .sourceOut
    case .sourceAtop:
      blendMode = .sourceAtop
    case .destinationOver:
      blendMode = .destinationOver
    case .destinationIn:
      blendMode = .destinationIn
    case .destinationOut:
      blendMode = .destinationOut
    case .destinationAtop:
      blendMode = .destinationAtop
    case .xor:
      blendMode = .xor
    case .plusDarker:
      blendMode = .plusDarker
    case .plusLighter:
      blendMode = .plusLighter
      //    default:
      //      blendMode = .normal
    }

    refreshHeatmap()

  }

  func numberOfComponents(in pickerView: UIPickerView) -> Int {
    return 1
  }

  func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
    return blendModeArray.count
  }

  func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
    return blendModeArray[row].rawValue
  }

}
