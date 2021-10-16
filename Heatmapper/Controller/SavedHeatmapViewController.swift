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
  var routeCoordinates = [CLLocationCoordinate2D]()

  let workoutDateFormatter  = DateFormatter()
  var measurementFormatter  = MeasurementFormatter()
  var units: String = ""
  var unitLength: UnitLength = .meters
  var unitSpeed: UnitSpeed  = .metersPerSecond
  var activityArray = [Activity]()
  var sportArray = [Sport]()
  let defaults = UserDefaults.standard

  // Outlets and Actions

  @IBOutlet weak var heatmapImageView: UIImageView!

  @IBOutlet weak var sportField         : ThemeMediumFontTextField!
  @IBOutlet weak var activityField      : ThemeMediumFontTextField!
  @IBOutlet weak var activityLabel      : ThemeMediumFontUILabel!

  @IBOutlet weak var venueLabel         : ThemeMediumFontUILabel!
  @IBOutlet weak var pitchLabel         : ThemeMediumFontUILabel!

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

    activityArray = MyFunc.getHeatmapperActivityDefaults()
    sportArray = Sport.allCases.map { $0 }
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

        let workoutReturned = samples.first

        guard let workout : HKWorkout = workoutReturned else {
          MyFunc.logMessage(.debug, "HeatmapViewController workoutReturned invalid: \(String(describing: workoutReturned))")
          return
        }
        self.getRouteSampleObject(workout: workout)
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

    // get route data for saving to new updated route

    MyFunc.logMessage(.debug, "routeCoordinatesToSave:")
    MyFunc.logMessage(.debug, String(describing: routeCoordinates))

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

            // need to add the new workout route here


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




  // added this to get the route data to save to the updated workout
  // this needs to be moved into a separate workout manager
  func getRouteSampleObject(workout: HKWorkout)  {

    let runningObjectQuery = HKQuery.predicateForObjects(from: workout)
    let routeQuery = HKAnchoredObjectQuery(type: HKSeriesType.workoutRoute(), predicate: runningObjectQuery, anchor: nil, limit: HKObjectQueryNoLimit) { (query, samples, deletedObjects, anchor, error) in

      guard error == nil else {

        fatalError("The initial query failed.")
      }

      DispatchQueue.main.async {
        guard
          let routeSamples = samples as? [HKWorkoutRoute],
          error == nil
        else {
          return
        }
        MyFunc.logMessage(.debug, "routeSamples:")
        MyFunc.logMessage(.debug, String(describing: routeSamples))
        guard let routeReturned = samples?.first as? HKWorkoutRoute else {
          MyFunc.logMessage(.debug, "routeQuery for workout \(String(describing: workout.startDate)) returned no samples")
          return
        }
        self.getRouteLocationData(route: routeReturned, workoutId: workout.uuid)
      }

    }

    // the update handler process persists between loads and can retrieve additional data
    // currently not using this to process updates
    routeQuery.updateHandler = { (query, samples, deleted, anchor, error) in

      guard error == nil else {
        MyFunc.logMessage(.error, "HKWorkoutRoute Anchored Query updateHandler failed with error \(String(describing: error))")
        return
      }
      // Process updates or additions here.
    }
    healthstore.execute(routeQuery)


  }

  func getRouteLocationData(route: HKWorkoutRoute, workoutId: UUID)   {


    let samplesCount = route.count
    MyFunc.logMessage(.debug, "Number of samples: \(samplesCount)")

    // Create the route query.
    let query = HKWorkoutRouteQuery(route: route) { (query, locationsOrNil, done, errorOrNil) in

      // This block may be called multiple times.

      if errorOrNil != nil {
        MyFunc.logMessage(.error, "Error retrieving workout locations")
      }

      guard let locations = locationsOrNil else {
        MyFunc.logMessage(.error, "Error retrieving workout locations")
        return
      }

      if done {

        let locationsAsCoordinates = locations.map {$0.coordinate}
        self.routeCoordinates = locationsAsCoordinates
        MyFunc.logMessage(.debug, "Locations retrieved: \(self.routeCoordinates)")
      }
    }

    healthstore.execute(query)

  }



}

extension SavedHeatmapViewController: UIScrollViewDelegate {

  func viewForZooming(in scrollView: UIScrollView) -> UIView? {
    return heatmapImageView
  }

}

