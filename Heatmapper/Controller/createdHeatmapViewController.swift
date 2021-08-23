//
//  createdHeatmapViewController.swift
//  Heatmapper
//
//  Created by Richard English on 11/08/2021.
//  Copyright © 2021 Richard English. All rights reserved.
//


import UIKit
import MapKit
import HealthKit
import CoreLocation

class createdHeatmapViewController: UIViewController  {

  // ****************************************************************************************************
  // Declare class variables
  // ****************************************************************************************************
  let healthstore       = HKHealthStore()
  var heatmapWorkoutId  : UUID?
  var heatmapImage      : UIImage?
  var retrievedWorkout  : HKWorkout?

  let workoutDateFormatter  = DateFormatter()


  // Outlets and Actions

  @IBOutlet weak var heatmapImageView: UIImageView!

  @IBOutlet weak var eventLabel         : ThemeLargeFontUILabel!
  @IBOutlet weak var venueLabel         : ThemeMediumFontUILabel!
  @IBOutlet weak var pitchLabel         : ThemeMediumFontUILabel!
  @IBOutlet weak var sportLabel         : ThemeMediumFontUILabel!

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

  // Core Flow
  override func viewDidLoad() {
    super.viewDidLoad()

    getWorkoutData()

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

  func loadUI() {

    guard let heatmapWorkout = retrievedWorkout else {
      MyFunc.logMessage(.error, "createdHeatmapViewController : no workout returned")
      return
    }
    let colouredheatmapImage = heatmapImage?.withBackground(color: UIColor.systemGreen)
    heatmapImageView.image = colouredheatmapImage

    guard let workoutMetadata : Dictionary = heatmapWorkout.metadata  else {
      MyFunc.logMessage(.error, "createdHeatmapViewController: no workout metadata")
      return
    }

    let workoutEvent = workoutMetadata["Event"] as? String ?? ""
    let workoutVenue = workoutMetadata["Venue"] as? String ?? ""
    let workoutPitch = workoutMetadata["Pitch"] as? String ?? ""
    let workoutSport = workoutMetadata["Sport"] as? String ?? ""

    eventLabel.text = workoutEvent
    venueLabel.text = workoutVenue
    pitchLabel.text = workoutPitch
    sportLabel.text = workoutSport
    


    // start and end date
    var workoutStartDateAsString = ""
    var workoutEndDateAsString = ""

    workoutDateFormatter.dateFormat = "E, d MMM yyyy HH:mm"
    // start date
    //    if let workoutStartDate = heatmapWorkout.startDate {
    workoutStartDateAsString = workoutDateFormatter.string(from: heatmapWorkout.startDate)
    //    }

    workoutDateFormatter.dateFormat = "HH:mm"
    //    if let workoutEndDate = heatmapWorkout.endDate {
    workoutEndDateAsString = workoutDateFormatter.string(from: heatmapWorkout.endDate)
    //    }

    let workoutDateString = workoutStartDateAsString + " - " + workoutEndDateAsString
    dateLabel.text = workoutDateString

    // duration
    let workoutIntervalFormatter = DateComponentsFormatter()

    //    if let workoutDuration = heatmapWorkout.duration {
    durationLabel.text = workoutIntervalFormatter.string(from: heatmapWorkout.duration)
    //    }

    // total calories
    if let caloriesBurned =
        heatmapWorkout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) {
      let formattedCalories = String(format: "%.2f kCal", caloriesBurned)
      caloriesLabel.text = formattedCalories
    } else {
      caloriesLabel.text = nil
    }

    // total distance
    if let workoutDistance = heatmapWorkout.totalDistance?.doubleValue(for: .meter()) {
      let formattedDistance = String(format: "%.2f m", workoutDistance)
      distanceLabel.text = formattedDistance
    } else {
      distanceLabel.text = nil
    }

    // average heart rate
    let heartRateSet = getHeartRateSampleForWorkout(workout: heatmapWorkout)


  }


  func getHeatmapImage() {

    guard let workoutId = heatmapWorkoutId else {
      MyFunc.logMessage(.error, "Invalid heatmapWorkoutId passed to createdHeatmapViewController: \(String(describing: heatmapWorkoutId))")
      return
    }
    heatmapImage = MyFunciOS.getHeatmapImageForWorkout(workoutID: workoutId)
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

        guard
          let samples = results as? [HKWorkout],
          error == nil
        else {
          completion(nil, error)
          return
        }

        completion(samples, nil)



        // load UI
        self.loadUI()

      }
    }

    healthstore.execute(query)

  }
  //

  //
  //  func getHRSample (startDate: Date, endDate: Date, completion:  @escaping ([HKWorkout]?, Error?) -> Void) {
  //
  //    let heartRateType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!
  //    let predicateHR = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: [])
  //    let sampleQueryHR = HKSampleQuery(sampleType: heartRateType, predicate: predicateHR, limit: 0, sortDescriptors: nil)
  //    { (sampleQueryHR, samples, error) -> Void in
  //
  //      DispatchQueue.main.async {
  //        guard
  //          let samples = samples as? [HKWorkout],
  //          error == nil
  //        else {
  //          completion(nil, error)
  //          return
  //        }
  //
  //        completion(samples, nil)
  //      }
  //
  //    }
  //
  //    self.healthstore.execute(sampleQueryHR)
  //    MyFunc.logMessage(.debug, "HR samples:")
  //    MyFunc.logMessage(.debug, String(describing: samples))
  //
  //  }


  func getHeartRateSampleForWorkout(workout: HKWorkout) -> [HKQuantitySample] {
    //      guard let heartRateType =  HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate) else {
    //        MyFunc.logMessage(.error, "*** Unable to create a heartRate type ***")
    //        return
    //      }
    let heartRateType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!
    var samplesToReturnSet = [HKQuantitySample]()

    let predicateHR = HKQuery.predicateForSamples(withStart: workout.startDate, end: workout.endDate, options: [])

    let sourcePredicate = HKQuery.predicateForObjects(from: .default())

    //3. Combine the predicates into a single predicate.
    let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates:
                                                  [predicateHR, sourcePredicate])

    let startDateSort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

    let query = HKSampleQuery(sampleType: heartRateType,
                              predicate: predicateHR,
                              limit: 0,
                              sortDescriptors: [startDateSort]) { (sampleQuery, results, error) -> Void in

      DispatchQueue.main.async {
        //        guard
        //          let samples = samples as? [HKWorkout],
        //          error == nil
        //        else {
        //          completion(nil, error)
        //          return
        //        }
        //
        //        completion(samples, nil)
        //      }
        //
        guard let heartRateSamples = results as? [HKQuantitySample] else {
          // Perform proper error handling here.
          return
        }
        samplesToReturnSet = heartRateSamples
        // Use the workout's heartrate samples here.
        MyFunc.logMessage(.debug, "heartRateSet")
        MyFunc.logMessage(.debug, String(describing: samplesToReturnSet))
      }
    }

    healthstore.execute(query)

    return samplesToReturnSet
  }




}

extension createdHeatmapViewController: UIScrollViewDelegate {

  func viewForZooming(in scrollView: UIScrollView) -> UIView? {
    return heatmapImageView
  }

}

