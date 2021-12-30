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
//import DTMHeatmap

// this struct manages the conversion of the rotated view to create a rotated MKMapRect
struct ViewCorners {
  private(set) var topLeft:     CGPoint!
  private(set) var topRight:    CGPoint!
  private(set) var bottomLeft:  CGPoint!
  private(set) var bottomRight: CGPoint!

  private let originalCenter: CGPoint
  private let transformedView: UIView

  private func pointWith(multipliedWidth: CGFloat, multipliedHeight: CGFloat) -> CGPoint {
    var x = originalCenter.x
    x += transformedView.bounds.width  / 2 * multipliedWidth

    var y = originalCenter.y
    y += transformedView.bounds.height / 2 * multipliedHeight

    var result = CGPoint(x: x, y: y).applying(transformedView.transform)
    result.x += transformedView.transform.tx
    result.y += transformedView.transform.ty

    return result
  }

  init(view: UIView) {
    transformedView = view
    originalCenter = view.center.applying(view.transform.inverted())

    topLeft =     pointWith(multipliedWidth:-1, multipliedHeight:-1)
    topRight =    pointWith(multipliedWidth: 1, multipliedHeight:-1)
    bottomLeft =  pointWith(multipliedWidth:-1, multipliedHeight: 1)
    bottomRight = pointWith(multipliedWidth: 1, multipliedHeight: 1)

  }
}



class REHeatmapViewController: UIViewController {

//  var dtmHeatmap                  = DTMHeatmap()
  var heatmapperCoordinatesArray  = [CLLocationCoordinate2D]()
  var heatmapperLocationsArray    = [CLLocation]()
  var heatmapWorkoutId            : UUID?
  var workoutMetadata             = WorkoutMetadata(workoutId: UUID.init(), activity: "", sport: "", venue: "", pitch: "")
  var workoutMetadataArray        =  [WorkoutMetadata]()


  var pointCount                  : Int = 0
  var angle                       : CGFloat = 0.0
  var pointsDistance              : CGFloat = 0.0
  var dtmRect                     = MKMapRect()
  var pitchOn                     : Bool = false
  var resizeOn                    : Bool = true
  var startResize                 : Bool = false

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
  var pitchView                   : UIImageView!

  var pitchViewRotation           : CGFloat = 0.0

  var bottomLeftCoord             : CLLocationCoordinate2D?
  var topLeftCoord                : CLLocationCoordinate2D?
  var bottomRightCoord            : CLLocationCoordinate2D?

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


  @IBAction func btnPoints(_ sender: Any) {

    let annotations = mapView.annotations
    mapView.removeAnnotations(annotations)
    savePitchCoordinates()

  }

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
  }

  @objc func handleRotate(_ gesture: UIRotationGestureRecognizer) {
    guard let gestureView = gesture.view else {
      return
    }
    gestureView.transform = gestureView.transform.rotated(
      by: gesture.rotation
    )
    pitchViewRotation += gesture.rotation
    gesture.rotation = 0
  }

  @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
    guard let gestureView = gesture.view else {
      return
    }
    gestureView.transform = gestureView.transform.scaledBy(
      x: gesture.scale,
      y: gesture.scale
    )
    gesture.scale = 1

    print("gestureView frame: \(gestureView.frame.debugDescription)")

  }

  @objc func handlePan(_ sender: UIPanGestureRecognizer) {

    // 1
    let translation = sender.translation(in: view)

    // 2
    guard let gestureView = sender.view else {
      return
    }

    gestureView.center = CGPoint(
      x: gestureView.center.x + translation.x,
      y: gestureView.center.y + translation.y
    )

    // 3
    sender.setTranslation(.zero, in: view)

    guard sender.state == .ended else {
      return
    }

    // 4
    let velocity = sender.velocity(in: view)
    let magnitude = sqrt((velocity.x * velocity.x) + (velocity.y * velocity.y))
    let slideMultiplier = magnitude / 200

    // 5
    let slideFactor = 0.1 * slideMultiplier
    // 6
    var finalPoint = CGPoint(
      x: gestureView.center.x + (velocity.x * slideFactor),
      y: gestureView.center.y + (velocity.y * slideFactor)
    )

    // 7
    finalPoint.x = min(max(finalPoint.x, 0), view.bounds.width)
    finalPoint.y = min(max(finalPoint.y, 0), view.bounds.height)

    print("gestureView frame: \(gestureView.frame.debugDescription)")

    //    // 8
    //    UIView.animate(
    //      withDuration: Double(slideFactor * 2),
    //      delay: 0,
    //      // 9
    //      options: .curveEaseOut,
    //      animations: {
    //        gestureView.center = finalPoint
    //      })

  }

  @IBAction func resetPitches(_ sender: Any) {
    MyFunc.deletePlayingAreas()
  }
  
  // this is where the fun begins... resize mode
  @IBAction func btnResize(_ sender: Any) {

    if resizeOn == true {
      // turn everything off (as it's on)
      resizeOn = false
      resizeButton.setTitle("Adjust Pitch Size", for: .normal)
      resizeButton.tintColor = UIColor.systemGreen

      self.touchView.isHidden = true
      savePitchCoordinates()

    } else {
      // turn everything on (as it's off)

      resizeOn = true
      startResize = true
      resizeButton.setTitle("Save Pitch Size", for: .normal)
      resizeButton.tintColor = UIColor.systemRed
      self.touchView.isHidden = false


      // now need to size the pitchView from the MapView information

      // we have the mapView rect from the overlay and the coordinates
      // let's try the coordinates first as MapView has better conversion functions

      let pitchViewBottomLeft : CGPoint = self.mapView.convert(bottomLeftCoord!, toPointTo: self.mapView)
      let pitchViewTopLeft : CGPoint = self.mapView.convert(topLeftCoord!, toPointTo: self.mapView)
      let pitchViewBottomRight : CGPoint = self.mapView.convert(bottomRightCoord!, toPointTo: self.mapView)

      let pitchViewBottomLefttStr = String(describing: pitchViewBottomLeft)
      print("pitchViewBottomLeft: \(pitchViewBottomLefttStr)")
      let pitchViewTopLeftStr = String(describing: pitchViewTopLeft)
      print("pitchViewTopLeft: \(pitchViewTopLeftStr)")
      let pitchViewBottomRightStr = String(describing: pitchViewBottomRight)
      print("pitchViewBottomRight: \(pitchViewBottomRightStr)")


      let pitchViewHeight = CGPointDistance(from: pitchViewBottomLeft, to: pitchViewTopLeft)
      let pitchViewWidth = CGPointDistance(from: pitchViewBottomLeft, to: pitchViewBottomRight)

//      pitchView.frame = CGRect(x: pitchViewBottomLeft.x, y: pitchViewBottomLeft.y, width: pitchViewWidth, height: pitchViewHeight)

      print("pitchView frame from Region: \(self.pitchView.frame.debugDescription)")




      //remove the pitch overlay

      if let overlays = mapView?.overlays {
        for overlay in overlays {
          // remove all MKPolyline-Overlays
          if overlay is FootballPitchOverlay {
            let overlayRect = overlay.boundingMapRect
            let overlayRectStr = String(describing: overlayRect)
            print ("overlayRect: \(overlayRectStr)")

            mapView?.removeOverlay(overlay)
          }
        }
      }
    }


  }
//
//  override func viewDidLayoutSubviews() {
//    super.viewDidLayoutSubviews()
//
//    pitchView.superview!.setNeedsLayout()
//    pitchView.superview!.layoutIfNeeded()
//
//    if startResize == true {
//    // Now modify bottomView's frame here
//    let pitchViewBottomLeft : CGPoint = self.mapView.convert(bottomLeftCoord!, toPointTo: self.mapView)
//    let pitchViewTopLeft : CGPoint = self.mapView.convert(topLeftCoord!, toPointTo: self.mapView)
//    let pitchViewBottomRight : CGPoint = self.mapView.convert(bottomRightCoord!, toPointTo: self.mapView)
//
//    let pitchViewBottomLefttStr = String(describing: pitchViewBottomLeft)
//    print("pitchViewBottomLeft: \(pitchViewBottomLefttStr)")
//    let pitchViewTopLeftStr = String(describing: pitchViewTopLeft)
//    print("pitchViewTopLeft: \(pitchViewTopLeftStr)")
//    let pitchViewBottomRightStr = String(describing: pitchViewBottomRight)
//    print("pitchViewBottomRight: \(pitchViewBottomRightStr)")
//
//
//    let pitchViewHeight = CGPointDistance(from: pitchViewBottomLeft, to: pitchViewTopLeft)
//    let pitchViewWidth = CGPointDistance(from: pitchViewBottomLeft, to: pitchViewBottomRight)
//
//    pitchView.frame = CGRect(x: pitchViewBottomLeft.x, y: pitchViewBottomLeft.y, width: pitchViewWidth, height: pitchViewHeight)
//
//    print("pitchView frame from Region: \(self.pitchView.frame.debugDescription)")
//      startResize = false
//    }
//  }


  override func viewDidLoad() {
    super.viewDidLoad()

    // set up the tester picker
    blendModePicker.delegate = self
    blendModePicker.dataSource = self

    mapView.delegate = self

    let rotator = UIRotationGestureRecognizer(target: self,action: #selector(self.handleRotate(_:)))
    let panner = UIPanGestureRecognizer(target: self,action: #selector(self.handlePan(_:)))
    let pincher = UIPinchGestureRecognizer(target: self, action: #selector(self.handlePinch(_:)))

    // add the touchView
    // doing this programmatically to avoid Storyboard complaining about overlap
    let mapViewFrame = mapView.globalFrame!
    touchView = UIView(frame: mapViewFrame)
    touchView.bounds = mapView.bounds
    touchView.translatesAutoresizingMaskIntoConstraints = false

    self.mapView.addSubview(touchView)

    // this code ensures the touchView is completely aligned with the mapView
    let attributes: [NSLayoutConstraint.Attribute] = [.top, .bottom, .right, .left]
    NSLayoutConstraint.activate(attributes.map {
      NSLayoutConstraint(item: touchView as Any, attribute: $0, relatedBy: .equal, toItem: touchView.superview, attribute: $0, multiplier: 1, constant: 0)
    })

    let pitchImageBlue = UIImage(named: "Figma Pitch 11 Blue")
    pitchView = UIImageView(image: pitchImageBlue)
    pitchView.layer.opacity = 0.5
    pitchView.translatesAutoresizingMaskIntoConstraints = false
    pitchView.isUserInteractionEnabled = true
    pitchView.addGestureRecognizer(panner)
    pitchView.addGestureRecognizer(rotator)
    pitchView.addGestureRecognizer(pincher)

    self.touchView.addSubview(pitchView)

//    NSLayoutConstraint.activate([
//      pitchView.topAnchor.constraint(greaterThanOrEqualTo: touchView.topAnchor, constant: 20),
//      pitchView.leftAnchor.constraint(greaterThanOrEqualTo: touchView.leftAnchor, constant: 20),
//      pitchView.bottomAnchor.constraint(greaterThanOrEqualTo: touchView.bottomAnchor, constant: -20),
//      pitchView.rightAnchor.constraint(greaterThanOrEqualTo: touchView.rightAnchor, constant: -20)
//    ])

    coloursStackView.isHidden = true
    lowerControlsStackView.isHidden = true

    resizeOn = false
    resizeButton.setTitle("Adjust Pitch Size", for: .normal)
    resizeButton.tintColor = UIColor.systemGreen
    self.touchView.isHidden = true

    self.loadUI()
    self.loadTesterData()
    self.loadTesterUI()

    // get workout data
    // Note: all UI work is called within this function as the data retrieval works asynchronously
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

    let overlays = mapView.overlays
    mapView.removeOverlays(overlays)

    self.createDefaultPitchOverlay()
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

  func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
    return true
  }


  func savePitchCoordinates() {

    // adding code to save pitch corner points as coordinates

    // first need to get the pitch corners on the touch view
    let corners = ViewCorners(view: pitchView)

    let pitchMapTopLeftCGPoint : CGPoint = corners.topLeft
    let pitchMapBottomLeftCGPoint : CGPoint  = corners.bottomLeft
    let pitchMapBottomRightCGPoint : CGPoint  =  corners.bottomRight

    // then workout out the corresponding co-ordinates at these points on the map view
    let pitchMapTopLeftCoordinate : CLLocationCoordinate2D = mapView.convert(pitchMapTopLeftCGPoint, toCoordinateFrom: self.mapView)
    let pitchMapBottomLeftCoordinate : CLLocationCoordinate2D = mapView.convert(pitchMapBottomLeftCGPoint, toCoordinateFrom: self.mapView)
    let pitchMapBottomRightCoordinate : CLLocationCoordinate2D = mapView.convert(pitchMapBottomRightCGPoint, toCoordinateFrom: self.mapView)

    createPitchOverlay(topLeft: pitchMapTopLeftCoordinate, bottomLeft: pitchMapBottomLeftCoordinate, bottomRight: pitchMapBottomRightCoordinate)

    if let row = self.workoutMetadataArray.firstIndex(where: {$0.workoutId == heatmapWorkoutId}) {
      workoutMetadataArray[row] = workoutMetadata
    } else {
      MyFunc.logMessage(.error, "Error updating workoutMetadata with pitch area")
    }

    // save the pitch here
    // we need the co-ordinates of 3 of the 4 points and the rotation to successfully recreate it

    let topLeftCoordToSave = CodableCLLCoordinate2D(latitude: pitchMapTopLeftCoordinate.latitude, longitude: pitchMapTopLeftCoordinate.longitude)
    let bottomLeftCoordToSave = CodableCLLCoordinate2D(latitude: pitchMapBottomLeftCoordinate.latitude, longitude: pitchMapBottomLeftCoordinate.longitude)
    let bottomRightCoordToSave = CodableCLLCoordinate2D(latitude: pitchMapBottomRightCoordinate.latitude, longitude: pitchMapBottomRightCoordinate.longitude)
    let viewRotation = rotation(from: pitchView.transform)

    let playingAreaToSave = PlayingArea(workoutID: heatmapWorkoutId!, bottomLeft: bottomLeftCoordToSave, bottomRight: bottomRightCoordToSave, topLeft: topLeftCoordToSave, rotation: viewRotation)

    MyFunc.savePlayingArea(playingAreaToSave)
    
    MyFunc.saveWorkoutMetadata(workoutMetadataArray)
    MyFunc.logMessage(.debug, "WorkoutMetadata saved in SavedHeatmapViewController \(String(describing: workoutMetadata))")

  }


  func getMapRotation() -> CGFloat {

    let viewRotation = rotation(from: pitchView.transform.inverted())
    let mapViewHeading = mapView.camera.heading
    let viewRotationAsCGFloat = CGFloat(viewRotation)

    let mapViewHeadingInt = Int(mapViewHeading)
    let mapViewHeadingRadians = mapViewHeadingInt.degreesToRadians
    let angleIncMapRotation = viewRotationAsCGFloat - mapViewHeadingRadians
    return angleIncMapRotation
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



  func setMapViewZoom(rect: MKMapRect) {
    let insets = UIEdgeInsets(top: 0, left: 5, bottom: 5, right: 5)
    //    let insets = UIEdgeInsets(top: 50, left: 50, bottom: 50, right: 50)

    mapView.setVisibleMapRect(rect, edgePadding: insets, animated: false)
    mapView.setCenter(self.overlayCenter!, animated: false)

  }

  func createREHeatmap() {

    for heatmapperCoordinate in heatmapperCoordinatesArray {
      addHeatmapPoint(coordinate: heatmapperCoordinate)
    }

  }


  func createDefaultPitchOverlay() {

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

        self.bottomLeftCoord = CLLocationCoordinate2D(latitude: minLat!, longitude: minLong!)
        self.bottomRightCoord = CLLocationCoordinate2D(latitude: minLat!, longitude: maxLong!)
        self.topLeftCoord = CLLocationCoordinate2D(latitude: maxLat!, longitude: minLong!)


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

        // this rectangle covers the area of all points
        let pitchMKMapRect = MKMapRect.init(x: rectX, y: rectY, width: rectWidth, height: rectHeight)

        //  create an overlay of the pitch based upon the rectangle
        let footballPitch11Overlay = FootballPitchOverlay(pitchRect: pitchMKMapRect)
        self.mapView.addOverlay(footballPitch11Overlay)
        self.setMapViewZoom(rect: pitchMKMapRect)

      case .success(let playingArea):
        MyFunc.logMessage(.debug, "Success retrieving PlayingArea! :")
        let playingAreaStr = String(describing: playingArea)
        MyFunc.logMessage(.debug, playingAreaStr)

        let midpointLatitude = (playingArea.topLeft.latitude + playingArea.bottomLeft.latitude) / 2
        let midpointLongitude = (playingArea.bottomLeft.longitude + playingArea.bottomRight.longitude) / 2
        self.overlayCenter = CLLocationCoordinate2D(latitude: midpointLatitude, longitude: midpointLongitude)
        let topLeftCoord = CLLocationCoordinate2D(latitude: playingArea.topLeft.latitude, longitude: playingArea.topLeft.longitude)

        let bottomLeftCoord = CLLocationCoordinate2D(latitude: playingArea.bottomLeft.latitude, longitude: playingArea.bottomLeft.longitude)
        let bottomRightCoord = CLLocationCoordinate2D(latitude: playingArea.bottomRight.latitude, longitude: playingArea.bottomRight.longitude)

        self.bottomLeftCoord = bottomLeftCoord
        self.bottomRightCoord = bottomRightCoord
        self.topLeftCoord = topLeftCoord


        // now get the CGPoints for these Coordinates
        let bottomLeftCGPoint = self.mapView.convert(bottomLeftCoord, toPointTo: self.mapView)
        let bottomLeftCGPointStr = String(describing: bottomLeftCGPoint)
        print("bottomLeftCGPoint: \(bottomLeftCGPointStr)")

        let topLeftCGPoint = self.mapView.convert(topLeftCoord, toPointTo: self.mapView)
        let topLeftCGPointStr = String(describing: topLeftCGPoint)
        print("topLeftCGPoint: \(topLeftCGPointStr)")

        let bottomRightCGPoint = self.mapView.convert(bottomRightCoord, toPointTo: self.mapView)
        let bottomRightCGPointStr = String(describing: bottomRightCGPoint)
        print("bottomRightCGPoint: \(bottomRightCGPointStr)")


        // the rotation is straightforward - rotate the pitchView by the same angle as the saved PlayingArea
        let savedPitchViewRotationStr = self.pitchView.transform.angle
        print("savedPitchViewRotationStr: \(savedPitchViewRotationStr)")

        self.pitchView.transform = self.pitchView.transform.rotated(by: playingArea.rotation)

        let pitchViewRotationStr = self.pitchView.transform.angle
        print("pitchViewRotationStr: \(pitchViewRotationStr)")

        self.createPitchOverlay(topLeft: topLeftCoord, bottomLeft: bottomLeftCoord, bottomRight: bottomRightCoord)


      }
    })

  }

  func createPitchOverlay(topLeft: CLLocationCoordinate2D, bottomLeft: CLLocationCoordinate2D, bottomRight: CLLocationCoordinate2D) {

    // get the max and min X and Y points from the above coordinates as MKMapPoints
    let topLeftMapPoint = MKMapPoint(topLeft)
    //    let topRightMapPoint = MKMapPoint(pitchMapTopRightCoordinate)
    let bottomLeftMapPoint = MKMapPoint(bottomLeft)
    let bottomRightMapPoint = MKMapPoint(bottomRight)

    let pitchRectHeight = MKMapPointDistance(from: bottomLeftMapPoint, to: topLeftMapPoint)
    let pitchRectWidth = MKMapPointDistance(from: bottomLeftMapPoint, to: bottomRightMapPoint)

    //    // using the bottom left as the origin of the rectangle (currently)
    let pitchMapOriginX = bottomLeftMapPoint.x
    let pitchMapOriginY = bottomLeftMapPoint.y

    // set up the rectangle
    let pitchMKMapRect = MKMapRect.init(x: pitchMapOriginX, y: pitchMapOriginY, width: pitchRectWidth, height: pitchRectHeight)

    let pitchRectStr = String(describing: pitchMKMapRect)

    MyFunc.logMessage(.debug, "pitch MKMapRect: \(pitchRectStr)")

    //  create an overlay of the pitch based upon the rectangle
    let adjustedPitchOverlay = FootballPitchOverlay(pitchRect: pitchMKMapRect)
    self.mapView.addOverlay(adjustedPitchOverlay)
    self.setMapViewZoom(rect: pitchMKMapRect)



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

      guard let workout : HKWorkout = workoutReturned else {
        MyFunc.logMessage(.error, "workoutReturned invalid: \(String(describing: workoutReturned))")
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

      DispatchQueue.main.async {
        //4. Cast the samples as HKWorkout
        guard
          let routeSamples = samples as? [HKWorkoutRoute],
          error == nil
        else {
          return
        }

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

    healthstore.execute(routeQuery)
  }

  func getRouteLocationData(route: HKWorkoutRoute) {

    let samplesCount = route.count

    // Create the route query.
    let query = HKWorkoutRouteQuery(route: route) { (query, locationsOrNil, done, errorOrNil) in

      // This block may be called multiple times.

      if errorOrNil != nil {
        MyFunc.logMessage(.error, "Error retrieving workout locations")
        return
      }

      guard let locations = locationsOrNil else {
        MyFunc.logMessage(.error, "Error retrieving workout locations")

        fatalError("*** Invalid State: This can only fail if there was an error. ***")
      }

      let locationsAsCoordinates = locations.map {$0.coordinate}

      self.heatmapperCoordinatesArray.append(contentsOf: locationsAsCoordinates)

      // if done = all data retrieved
      // only at this point can we start to build a heatmap overlay
      if done {

        // dispatch to the main queue as we are making UI updates
        DispatchQueue.main.async {

          // get the workout's metadata
          self.workoutMetadataArray = MyFunc.getWorkoutMetadata()
          if let workoutMetadataRow = self.workoutMetadataArray.firstIndex(where: {$0.workoutId == self.heatmapWorkoutId}) {
            self.workoutMetadata = self.workoutMetadataArray[workoutMetadataRow]
          }

          self.createDefaultPitchOverlay()
          self.createREHeatmap()

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
      if let pitchImage = UIImage(named: "Figma Pitch 11 Green.png")
      {

        // get the rotation of the pitchView
        let angleIncMapRotation = getMapRotation()

        let footballPitchOverlayRenderer = FootballPitchOverlayRenderer(overlay: overlay, overlayImage: pitchImage, angle: angleIncMapRotation)

        footballPitchOverlayRenderer.alpha = 0.5

        let pitchViewCGRect = footballPitchOverlayRenderer.rect(for: overlay.boundingMapRect)
        let pitchViewCGRectStr = String(describing: pitchViewCGRect)
        print("pitchViewCGRect:")
        print(pitchViewCGRectStr)
        pitchView.frame = pitchViewCGRect
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

extension REHeatmapViewController: UIPickerViewDelegate, UIPickerViewDataSource {
  func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
//    MyFunc.logMessage(.debug, "REHeatmapViewController.didSelectRow: \(row)")

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

  func setPinUsingMKPlacemark(coordinate: CLLocationCoordinate2D) {
    let pin = MKPlacemark(coordinate: coordinate)

    mapView.addAnnotation(pin)
  }

  func setPinUsingMKAnnotation(coordinate: CLLocationCoordinate2D, title: String) {
    let annotation = MKPointAnnotation()
    annotation.coordinate = coordinate
    annotation.title = title
    mapView.addAnnotation(annotation)

  }


}
