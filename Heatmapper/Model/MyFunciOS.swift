//
//  MyFunciOS.swift
//  Heatmapper
//
//  Created by Richard English on 23/10/2020.
//  Copyright © 2020 Richard English. All rights reserved.
//

import UIKit

class MyFunciOS {

  static func openUrl(urlString: String) {
    guard let url = URL(string: urlString) else {
      return
    }

    if UIApplication.shared.canOpenURL(url) {
      UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
  }


  static func getHeatmapImageForWorkout(workoutID: UUID) -> UIImage {

    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    let documentsDirectory = paths[0]
    let documentsDirectoryStr = String(describing: documentsDirectory)

    let workoutIDString = String(describing: workoutID)
    let heatmapImageString = "Heatmap_" + workoutIDString + ".png"

    let heatmapImageFileExists = MyFunc.checkFileExists(filename: heatmapImageString)

    var heatmapImage  = UIImage()
    if heatmapImageFileExists {
      let documentLocationStr = documentsDirectoryStr + heatmapImageString
      let documentLocationURL = URL(string: documentLocationStr)!
      if let data = try? Data(contentsOf: documentLocationURL), let loaded = UIImage(data: data) {
        heatmapImage = loaded
      } else {
        heatmapImage = UIImage(named: "Work.png")!
      }

    }
    return heatmapImage
  }

  static func renameHeatmapImageFile(currentID: UUID, newID: UUID) {

    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    let documentsDirectory = paths[0]
    let documentsDirectoryStr = String(describing: documentsDirectory)

    let currentIDString = String(describing: currentID)
    let currentFilenameString = "Heatmap_" + currentIDString + ".png"

    let heatmapImageFileExists = MyFunc.checkFileExists(filename: currentFilenameString)

    if heatmapImageFileExists {

      let documentLocationStr = documentsDirectoryStr + currentFilenameString
      var currentFileURL = URL(string: documentLocationStr)!

      let newIDString = String(describing: newID)
      let newFilenameString = "Heatmap_" + newIDString + ".png"

      var newURV = URLResourceValues()
      newURV.name = newFilenameString

      try? currentFileURL.setResourceValues(newURV)

    }

  }




}
