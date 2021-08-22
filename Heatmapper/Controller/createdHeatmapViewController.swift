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

  let healthstore       = HKHealthStore()
  var heatmapWorkoutId  : UUID?
  var heatmapImage      : UIImage?
  var heatmapWorkout    : HKWorkout?

  // Outlets and Actions
  @IBOutlet weak var workoutName: ThemeVeryLargeFontUILabel!
  @IBOutlet weak var workoutLocation: ThemeVeryLargeFontUILabel!
  @IBOutlet weak var heatmapImageView: UIImageView!
  @IBOutlet weak var durationLabel: ThemeColumnHeaderUILabel!
  
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

    // get workout data
    getWorkoutData()

    // load UI
//    loadUI()

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
      heatmapWorkout = workout
    }

    // get image for heatmap
    getHeatmapImage()

  }

  func loadUI() {



    let colouredheatmapImage = heatmapImage?.withBackground(color: UIColor.systemGreen)
    heatmapImageView.image = colouredheatmapImage

    guard let workoutMetadata : Dictionary = heatmapWorkout?.metadata  else {
      MyFunc.logMessage(.error, "createdHeatmapViewController: no workout metadata")
      return
    }
    let workoutVenue = workoutMetadata["Venue"] as! String
    let workoutEvent = workoutMetadata["Event"] as! String
    let workoutSport = workoutMetadata["Sport"] as! String
    let workoutPitch = workoutMetadata["Pitch"] as! String

    workoutName.text = workoutEvent
    workoutLocation.text = workoutVenue

    
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



}

extension createdHeatmapViewController: UIScrollViewDelegate {

  func viewForZooming(in scrollView: UIScrollView) -> UIView? {
    return heatmapImageView
  }

}

