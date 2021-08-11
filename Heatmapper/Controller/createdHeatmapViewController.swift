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

class createdHeatmapViewController: UIViewController {

  var heatmapWorkoutId : UUID?

  // the view which renders the heatmap over the map
  @IBOutlet weak var mapsView: UIView!

  override func viewDidLoad() {
    super.viewDidLoad()

    getHeatmapImage()



  }

  func getHeatmapImage() {

    guard let workoutId = heatmapWorkoutId else {
      MyFunc.logMessage(.error, "Invalid heatmapWorkoutId passed to createdHeatmapViewController: \(String(describing: heatmapWorkoutId))")
      return
    }
    let directoryURL = getDocumentsDirectory()
    let fileName = "JDHeatmap_\(workoutId)"
    let fileExt = "png"

    let imageURL = directoryURL.appendingPathComponent(fileName).appendingPathExtension(fileExt)
    MyFunc.logMessage(.debug, "imageURL: \(String(describing: imageURL))")

    let heatmapUIImage    = UIImage(contentsOfFile: imageURL.path)
      // Do whatever you want with the image

  }

  func getDocumentsDirectory() -> URL {
    // find all possible documents directories for this user
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)

    // just send back the first one, which ought to be the only one
    return paths[0]
  }

}

