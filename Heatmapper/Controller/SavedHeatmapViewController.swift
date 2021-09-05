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

class SavedHeatmapViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate  {

  // **************************************************
  // Declare class variables
  // **************************************************
  let healthstore       = HKHealthStore()
  var heatmapWorkoutId  : UUID?
  var heatmapImage      : UIImage?
  var retrievedWorkout  : HKWorkout?

  let workoutDateFormatter  = DateFormatter()
  var measurementFormatter  = MeasurementFormatter()
  var units: String = ""
  var unitLength: UnitLength = .meters
  var unitSpeed: UnitSpeed  = .metersPerSecond
  var activityArray = [String]()
  var sportArray = ["Football - 11-a-side", "Football - 5-a-side", "Kabbaddi"]
  let defaults = UserDefaults.standard

  // Outlets and Actions

  @IBOutlet weak var heatmapImageView: UIImageView!

  @IBOutlet weak var sportField         : ThemeTextField!
  @IBOutlet weak var activityField      : ThemeTextField!
  @IBOutlet weak var activityLabel      : ThemeMediumFontUILabel!

  @IBOutlet weak var venueLabel         : ThemeMediumFontUILabel!
  @IBOutlet weak var pitchLabel         : ThemeMediumFontUILabel!

  @IBOutlet weak var durationLabel      : ThemeMediumFontUILabel!
  @IBOutlet weak var dateLabel          : ThemeMediumFontUILabel!

  @IBOutlet weak var distanceLabel      : ThemeMediumFontUILabel!
  @IBOutlet weak var caloriesLabel      : ThemeMediumFontUILabel!
  @IBOutlet weak var avgHeartRateLabel  : ThemeMediumFontUILabel!
  @IBOutlet weak var avgSpeedLabel      : ThemeMediumFontUILabel!

  @IBOutlet weak var scrollView: UIScrollView! {
    didSet {
      scrollView.delegate = self
      scrollView.minimumZoomScale = 1
      scrollView.maximumZoomScale = 10
    }
  }


  let activityPicker = UIPickerView()
  let sportPicker = UIPickerView()

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
      return activityArray[row]
    } else {
      return sportArray[row]
    }

  }

  func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {

    if pickerView == activityPicker {
      activityField.text = activityArray[row]
    } else {
      sportField.text = sportArray[row]
    }
    updateWorkout()
    self.view.endEditing(true)
  }



  // **************************************************
  // Core Flow
  // **************************************************
  override func viewDidLoad() {
    super.viewDidLoad()

    getWorkoutData()
    getStaticData()

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

  }

  func getStaticData() {

    activityArray = defaults.stringArray(forKey: "Activity") ?? []
  }


  func loadUI() {

    activityPicker.delegate = self
    activityPicker.dataSource = self
    activityField.inputView = activityPicker

    sportPicker.delegate = self
    sportPicker.dataSource = self
    sportField.inputView = sportPicker


    //    let sportGesture = UITapGestureRecognizer(target: self, action: #selector(self.sportTap(_:)))
    //
    //    sportLabel.isUserInteractionEnabled = true
    //    sportLabel.addGestureRecognizer(sportGesture)


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

    guard let workoutMetadata : Dictionary = heatmapWorkout.metadata  else {
      MyFunc.logMessage(.error, "SavedHeatmapViewController: no workout metadata")
      return
    }

    let workoutActivity = workoutMetadata["Activity"] as? String ?? ""
    let workoutVenue = workoutMetadata["Venue"] as? String ?? ""
    let workoutPitch = workoutMetadata["Pitch"] as? String ?? ""
    let workoutSport = workoutMetadata["Sport"] as? String ?? ""

    activityField.text = workoutActivity
    venueLabel.text = workoutVenue
    pitchLabel.text = workoutPitch
    sportField.text = workoutSport

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

  //  @objc func sportTap(_ sender: UITapGestureRecognizer? = nil)
  //  {
  //    self.sportPicker.isHidden = false
  //    self.view.setNeedsLayout()
  //  }


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
        completion(samples, nil)
        self.loadUI()
      }
    }
    healthstore.execute(query)

  }

  func updateWorkout()  {

    guard let workoutToUpdate = retrievedWorkout else {
      MyFunc.logMessage(.error, "Cannot get retrievedWorkout")
      return
    }

    var metadataToUpdate = workoutToUpdate.metadata
    let currentDate = Date()
    let currentDateAsString = String(describing: currentDate)

    metadataToUpdate?.updateValue(currentDateAsString, forKey: "Date")
    metadataToUpdate?.updateValue(activityField.text as Any, forKey: "Activity")
    metadataToUpdate?.updateValue(sportField.text as Any, forKey: "Sport")

    let workoutToSave = HKWorkout(activityType: workoutToUpdate.workoutActivityType, start: workoutToUpdate.startDate, end: workoutToUpdate.endDate, workoutEvents: workoutToUpdate.workoutEvents, totalEnergyBurned: workoutToUpdate.totalEnergyBurned, totalDistance: workoutToUpdate.totalDistance, device: workoutToUpdate.device, metadata: metadataToUpdate)



    self.healthstore.delete(workoutToUpdate, withCompletion: { (success, error) in

      if success {
        MyFunc.logMessage(.debug, "Workout with ID \(String(describing: workoutToUpdate.uuid)) deleted successfully")

        self.healthstore.save(workoutToSave, withCompletion: { (success, error) in

          if success {
            // Workout was successfully saved
            MyFunc.logMessage(.debug, "Workout saved successfully: \(String(describing: workoutToSave.uuid))")
            MyFunciOS.renameHeatmapImageFile(currentID: workoutToUpdate.uuid, newID: workoutToSave.uuid)
            // delete previous workout

          } else {
            MyFunc.logMessage(.error, "Error saving workout: \(String(describing: error))")
          }

        })

      } else {
        MyFunc.logMessage(.error, "Error deleting workout with ID\(String(describing: workoutToUpdate.uuid)) :  \(String(describing: error))")

      }
    }
    )


  }



  func loadAverageHeartRateLabel(startDate: Date, endDate: Date, quantityType: HKQuantityType, option: HKStatisticsOptions) {
    MyFunc.logMessage(.debug, "getHeartRateSample: \(String(describing: startDate)) to \(String(describing: endDate))")

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
    healthstore.execute(heartRateQuery)
  }

  func loadAverageSpeedLabel(startDate: Date, endDate: Date, quantityType: HKQuantityType, option: HKStatisticsOptions) {
    MyFunc.logMessage(.debug, "getHeartRateSample: \(String(describing: startDate)) to \(String(describing: endDate))")

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
    healthstore.execute(heartRateQuery)
  }

}

extension SavedHeatmapViewController: UIScrollViewDelegate {

  func viewForZooming(in scrollView: UIScrollView) -> UIView? {
    return heatmapImageView
  }

}
