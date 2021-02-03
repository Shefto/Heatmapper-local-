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

}
