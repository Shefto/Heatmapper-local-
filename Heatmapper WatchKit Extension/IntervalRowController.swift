//
//  IntervalRowController.swift
//  Heatmapper
//
//  Created by Richard English on 08/07/2020.
//  Copyright © 2020 Richard English. All rights reserved.
//

import WatchKit

class IntervalRowController: NSObject {

  @IBOutlet weak var middleGroup: WKInterfaceGroup!
  @IBOutlet weak var heartRateLabel: WKInterfaceLabel!
  @IBOutlet weak var durationLabel: WKInterfaceLabel!
  @IBOutlet weak var paceLabel: WKInterfaceLabel!
  @IBOutlet weak var distanceLabel: WKInterfaceLabel!

  @IBOutlet weak var caloriesLabel: WKInterfaceLabel!
  @IBOutlet weak var distanceUnits: WKInterfaceLabel!
  @IBOutlet weak var paceUnits: WKInterfaceLabel!
  @IBOutlet weak var group: WKInterfaceGroup!
  @IBOutlet weak var activityTypeLabel: WKInterfaceLabel!

}
