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

  var heatmapWorkoutId : UUID?
  var heatmapImage : UIImage?
  
  @IBOutlet weak var heatmapImageView: UIImageView!

  @IBOutlet weak var scrollView: UIScrollView! {
    didSet {
      scrollView.delegate = self
      scrollView.minimumZoomScale = 1
      scrollView.maximumZoomScale = 10
    }
  }


  override func viewDidLoad() {
    super.viewDidLoad()

    getHeatmapImage()
    let colouredheatmapImage = heatmapImage?.withBackground(color: UIColor.systemGreen)
    heatmapImageView.image = colouredheatmapImage


  }

  func getHeatmapImage() {

    guard let workoutId = heatmapWorkoutId else {
      MyFunc.logMessage(.error, "Invalid heatmapWorkoutId passed to createdHeatmapViewController: \(String(describing: heatmapWorkoutId))")
      return
    }

    heatmapImage = MyFunciOS.getHeatmapImageForWorkout(workoutID: workoutId)

  }

}

extension createdHeatmapViewController: UIScrollViewDelegate {

  func viewForZooming(in scrollView: UIScrollView) -> UIView? {
    return heatmapImageView
  }

}

