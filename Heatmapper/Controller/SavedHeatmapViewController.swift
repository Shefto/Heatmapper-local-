//
//  SavedHeatmapViewController.swift
//  Heatmapper
//
//  Created by Richard English on 11/08/2021.
//  Copyright © 2021 Richard English. All rights reserved.
//


import UIKit
import MapKit
import HealthKit
import CoreLocation

class SavedHeatmapViewController: UIViewController {

  // **************************************************
  // Declare class variables
  // **************************************************
  let healthStore                 = HKHealthStore()
  let workoutConfiguration        = HKWorkoutConfiguration()
  var builder                     : HKWorkoutBuilder!
  var routeBuilder                : HKWorkoutRouteBuilder!

  var workoutMetadataArray        =  [WorkoutMetadata]()
  var workoutMetadata             = WorkoutMetadata(workoutId: UUID.init(), activity: "", sport: "", playingAreaVenue: "", playingAreaName: "")

  var heatmapWorkoutId  : UUID?
  var heatmapImage      : UIImage?
  var retrievedWorkout  : HKWorkout?
  var routeCoordinatesArray = [CLLocation]()

  let workoutDateFormatter  = DateFormatter()
  var measurementFormatter  = MeasurementFormatter()
  var units: String = ""
  var unitLength: UnitLength = .meters
  var unitSpeed: UnitSpeed  = .metersPerSecond
  var activityArray = [Activity]()
  var sportArray    = [Sport]()
  let defaults = UserDefaults.standard

  // Outlets and Actions
  @IBOutlet weak var heatmapImageView: UIImageView!

  @IBOutlet weak var activityLabel      : ThemeMediumFontUILabel!
  @IBOutlet weak var sportLabel         : ThemeMediumFontUILabel!
  @IBOutlet weak var venueLabel         : ThemeMediumFontUILabel!
  @IBOutlet weak var pitchLabel         : ThemeMediumFontUILabel!

  @IBOutlet weak var activityField      : ThemeMediumFontTextField!
  @IBOutlet weak var sportField         : ThemeMediumFontTextField!
  @IBOutlet weak var venueField         : ThemeMediumFontTextField!
  @IBOutlet weak var pitchField         : ThemeMediumFontTextField!

  @IBOutlet weak var durationLabel      : ThemeMediumFontUILabel!
  @IBOutlet weak var dateLabel          : ThemeMediumFontUILabel!

  @IBOutlet weak var distanceLabel      : ThemeMediumFontUILabel!
  @IBOutlet weak var caloriesLabel      : ThemeMediumFontUILabel!
  @IBOutlet weak var avgHeartRateLabel  : ThemeMediumFontUILabel!
  @IBOutlet weak var avgSpeedLabel      : ThemeMediumFontUILabel!

  @IBOutlet weak var caloriesImageView  : UIImageView!
  @IBOutlet weak var paceImageView      : UIImageView!
  @IBOutlet weak var heartRateImageView : UIImageView!
  @IBOutlet weak var distanceImageView  : UIImageView!

  @IBOutlet weak var scrollView: UIScrollView! {
    didSet {
      scrollView.delegate = self
      scrollView.minimumZoomScale = 1
      scrollView.maximumZoomScale = 10
    }
  }


  let activityPicker = UIPickerView()
  let sportPicker = UIPickerView()


  // **************************************************
  // Core Flow
  // **************************************************
  override func viewDidLoad() {
    super.viewDidLoad()

    workoutConfiguration.activityType = .running
    workoutConfiguration.locationType = .outdoor

    builder = HKWorkoutBuilder(healthStore: healthStore, configuration: workoutConfiguration, device: .local())
    routeBuilder = HKWorkoutRouteBuilder(healthStore: healthStore, device: nil)

    getWorkoutData()
    getStaticData()

  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    updateWorkout()
  }

  func getWorkoutData() {

    // check valid workout ID received
    guard let workoutId = heatmapWorkoutId else {
      MyFunc.logMessage(.error, "HeatmapViewController heatmapWorkoutId is invalid: \(String(describing: heatmapWorkoutId))")
      return
    }

    // get workout
    getWorkout(workoutId: workoutId) { [self] (workouts, error) in
      let workoutReturned = workouts?.first

      guard let workout : HKWorkout = workoutReturned else {
        MyFunc.logMessage(.debug, "HeatmapViewController workoutReturned invalid: \(String(describing: workoutReturned))")
        return
      }
      retrievedWorkout = workout

    }

    // get image for heatmap
    getHeatmapImage()

    // add function to get metadata from elsewhere
    getWorkoutMetadata()
  }

  func getStaticData() {

    activityArray = MyFunc.getHeatmapperActivityDefaults()
    sportArray = Sport.allCases.map { $0 }
  }

  func getWorkoutMetadata() {
    // calling this with the workoutId for now
    // currently retrieving the whole array but will tighten this up once working
    workoutMetadataArray = MyFunc.getWorkoutMetadata()
//    MyFunc.logMessage(.debug, "updateWorkout: workoutMetadataArray: \(String(describing: workoutMetadataArray))")
    
    if let workoutMetadataRow = self.workoutMetadataArray.firstIndex(where: {$0.workoutId == heatmapWorkoutId}) {
      workoutMetadata = self.workoutMetadataArray[workoutMetadataRow]
    }



  }

  func loadUI() {

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

    guard let heatmapWorkout = retrievedWorkout else {
      MyFunc.logMessage(.error, "SavedHeatmapViewController : no workout returned")
      return
    }
    let colouredheatmapImage = heatmapImage?.withBackground(color: UIColor.systemGreen)
    heatmapImageView.image = colouredheatmapImage


    let workoutActivity = workoutMetadata.activity
    let workoutVenue = workoutMetadata.playingAreaVenue
    let workoutPitch = workoutMetadata.playingAreaName
    let workoutSport = workoutMetadata.sport

    activityField.text = workoutActivity
    venueField.text = workoutVenue
    pitchField.text = workoutPitch
    sportField.text = workoutSport

    // colour icons
    heartRateImageView.image = heartRateImageView.image?.withRenderingMode(.alwaysTemplate)
    heartRateImageView.tintColor = UIColor.systemRed

    caloriesImageView.image = caloriesImageView.image?.withRenderingMode(.alwaysTemplate)
    caloriesImageView.tintColor = UIColor.systemOrange

    paceImageView.image = paceImageView.image?.withRenderingMode(.alwaysTemplate)
    paceImageView.tintColor = UIColor.systemBlue

    distanceImageView.image = distanceImageView.image?.withRenderingMode(.alwaysTemplate)
    distanceImageView.tintColor = UIColor.systemGreen

    // start and end date
    var workoutStartDateAsString = ""
    var workoutEndDateAsString = ""

    workoutDateFormatter.dateFormat = "E, d MMM yyyy HH:mm"
    workoutStartDateAsString = workoutDateFormatter.string(from: heatmapWorkout.startDate)

    workoutDateFormatter.dateFormat = "d MMM yyy HH:mm"
    self.title = workoutDateFormatter.string(from: heatmapWorkout.startDate)

    workoutDateFormatter.dateFormat = "HH:mm"
    workoutEndDateAsString = workoutDateFormatter.string(from: heatmapWorkout.endDate)

    let workoutDateString = workoutStartDateAsString + " - " + workoutEndDateAsString
    dateLabel.text = workoutDateString

    // duration
    let workoutIntervalFormatter = DateComponentsFormatter()
    durationLabel.text = workoutIntervalFormatter.string(from: heatmapWorkout.duration)

    // total distance
    if let workoutDistance = heatmapWorkout.totalDistance?.doubleValue(for: .meter()) {
      let formattedDistance = String(format: "%.2f m", workoutDistance)
      distanceLabel.text = formattedDistance

      let pace = workoutDistance / heatmapWorkout.duration

      let paceString = MyFunc.getUnitSpeedAsString(value: pace, unitSpeed: unitSpeed, formatter: measurementFormatter)
      let paceUnitString = unitSpeed.symbol

      avgSpeedLabel.text = paceString + " " + paceUnitString

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


  func getHeatmapImage() {

    guard let workoutId = heatmapWorkoutId else {
      MyFunc.logMessage(.error, "Invalid heatmapWorkoutId passed to SavedHeatmapViewController: \(String(describing: heatmapWorkoutId))")
      return
    }
    heatmapImage = MyFunciOS.getHeatmapImageForWorkout(workoutID: workoutId)
  }


  func getWorkout(workoutId: UUID, completion: @escaping ([HKWorkout]?, Error?) -> Void) {

    let predicate = HKQuery.predicateForObject(with: workoutId)

    let query = HKSampleQuery(sampleType: .workoutType(), predicate: predicate, limit: 0, sortDescriptors: nil) { (query, results, error) in
      DispatchQueue.main.async {
        guard let samples = results as? [HKWorkout], error == nil else {
          completion(nil, error)
          return
        }

//        let workoutReturned = samples.first

//        guard let workout : HKWorkout = workoutReturned else {
//          MyFunc.logMessage(.debug, "HeatmapViewController workoutReturned invalid: \(String(describing: workoutReturned))")
//          return
//        }

        completion(samples, nil)

        self.loadUI()

      }
    }
    healthStore.execute(query)

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

    let workoutMetadataToSave = WorkoutMetadata(workoutId: workoutId, activity: activity, sport: sport, playingAreaVenue: venue, playingAreaName: pitch)
//    MyFunc.logMessage(.debug, "updateWorkout: workoutMetadataArray: \(String(describing: workoutMetadataArray))")
    if let row = self.workoutMetadataArray.firstIndex(where: {$0.workoutId == workoutId}) {
      workoutMetadataArray[row] = workoutMetadataToSave
    } else {
      workoutMetadataArray.append(workoutMetadataToSave)
    }
    MyFunc.saveWorkoutMetadata(workoutMetadataArray)
    MyFunc.logMessage(.debug, "WorkoutMetadata saved in SavedHeatmapViewController \(String(describing: workoutMetadataToSave))")


  }



  func loadAverageHeartRateLabel(startDate: Date, endDate: Date, quantityType: HKQuantityType, option: HKStatisticsOptions) {
//    MyFunc.logMessage(.debug, "getHeartRateSample: \(String(describing: startDate)) to \(String(describing: endDate))")

    let quantityPredicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)
    let heartRateQuery = HKStatisticsQuery(quantityType: quantityType, quantitySamplePredicate: quantityPredicate, options: .discreteAverage) { (query, statisticsOrNil, errorOrNil) in

      guard let statistics = statisticsOrNil else {
        return
      }
      let average : HKQuantity? = statistics.averageQuantity()
      let heartRateBPM  = average?.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute())) ?? 0.0

      DispatchQueue.main.async {
        self.avgHeartRateLabel.text = String(format: "%.2f", heartRateBPM) + " bpm"
      }
    }
    healthStore.execute(heartRateQuery)
  }

  func loadAverageSpeedLabel(startDate: Date, endDate: Date, quantityType: HKQuantityType, option: HKStatisticsOptions) {
//    MyFunc.logMessage(.debug, "getHeartRateSample: \(String(describing: startDate)) to \(String(describing: endDate))")

    let quantityPredicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)
    let heartRateQuery = HKStatisticsQuery(quantityType: quantityType, quantitySamplePredicate: quantityPredicate, options: .discreteAverage) { (query, statisticsOrNil, errorOrNil) in

      guard let statistics = statisticsOrNil else {
        return
      }
      let average : HKQuantity? = statistics.averageQuantity()
      let pace  = average?.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute())) ?? 0.0

      DispatchQueue.main.async {
        self.avgSpeedLabel.text = String(format: "%.2f", pace) + " bpm"
      }
    }
    healthStore.execute(heartRateQuery)
  }

}

extension SavedHeatmapViewController: UIScrollViewDelegate {

  func viewForZooming(in scrollView: UIScrollView) -> UIView? {
    return heatmapImageView
  }

}

extension SavedHeatmapViewController:  UIPickerViewDataSource, UIPickerViewDelegate {

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
      //      if sportField.text == "" {
      sportField.text = activityArray[row].sport.rawValue
      //      }
    } else {
      sportField.text = sportArray[row].rawValue
    }
    updateWorkout()

    self.view.endEditing(true)
  }



}
