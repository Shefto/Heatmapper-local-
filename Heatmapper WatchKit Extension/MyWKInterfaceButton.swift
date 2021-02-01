//
//  MyWKInterfaceButton.swift
//  FIT WatchKit Extension
//
//  Created by Richard English on 19/01/2021.
//  Copyright © 2021 Richard English. All rights reserved.
//

import WatchKit

class MyWKInterfaceButton: WKInterfaceButton {

  func preventRepeatedPresses(inNext seconds: Double = 1) {
    self.setEnabled(false)
    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + seconds) {
      self.setEnabled(true)
    }
  }


}
