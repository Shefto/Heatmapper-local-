//
//  IntervalsInterfaceController.swift
//  Heatmapper
//
//  Created by Richard English on 11/08/2020.
//  Copyright © 2020 Richard English. All rights reserved.
//

import WatchKit
import Foundation

class IntervalsInterfaceController: WKInterfaceController {

  // Units default - these will be retrieved during initialisation
  var units: String = ""
  var unitLength: UnitLength = .meters
  var unitSpeed: UnitSpeed  = .metersPerSecond
  var measurementFormatter  = MeasurementFormatter()

  @IBOutlet weak var mainMenuButton: WKInterfaceButton!
  @IBOutlet weak var intervalTable: WKInterfaceTable!

  override func awake(withContext context: Any?) {
    super.awake(withContext: context)

    // if workout has ended, display the Main Menu button, otherwise hide it
    if (context as? String)  == "workoutEnded" {
      mainMenuButton.setHidden(false)
    } else {
      mainMenuButton.setHidden(true)
    }

    unitSpeed = MyFunc.getDefaultsUnitSpeed()
    unitLength = MyFunc.getDefaultsUnitLength()

    let locale = Locale.current
    // get the locale for displaying metrics in km or mi
    measurementFormatter.locale = locale
    measurementFormatter.unitOptions = .naturalScale
    measurementFormatter.unitStyle = .medium
    measurementFormatter.numberFormatter.usesSignificantDigits = false
    measurementFormatter.numberFormatter.minimumIntegerDigits = 1
    measurementFormatter.numberFormatter.maximumFractionDigits = 2

  }

  override func willActivate() {
    super.willActivate()
//    loadTable()
  }

  func loadTable() {

    let count = HeatmapperWorkout.intervalArray.count
    intervalTable.setNumberOfRows(count, withRowType: "IntervalRowController")

    for count in 0..<count {
      let row = intervalTable.rowController(at: count)
        as! IntervalRowController

      // format distance including metric / imperial conversion as required
      let distance = HeatmapperWorkout.intervalArray[count].distance
      MyFunc.logMessage(.debug, "intervalArray distance: \(distance)")
      let distanceAsDouble = Double(truncating: distance)
      let distanceString = MyFunc.getUnitLengthAsString(value: distanceAsDouble, unitLength: unitLength, formatter: measurementFormatter)
      row.distanceLabel.setText(distanceString)
      MyFunc.logMessage(.debug, "distanceString: \(distanceString)")
      row.distanceUnits.setText(unitLength.symbol)

      let pace = HeatmapperWorkout.intervalArray[count].pace
      MyFunc.logMessage(.debug, "intervalArray pace: \(pace) seconds per meter")
      let paceAsDouble = Double(truncating: pace)
      let paceString = MyFunc.getUnitSpeedAsString(value: paceAsDouble, unitSpeed: unitSpeed, formatter: measurementFormatter)
      row.paceLabel.setText(paceString)
      MyFunc.logMessage(.debug, "paceString: \(paceString)")
      row.paceUnits.setText(unitSpeed.symbol)

      // set the unit labels for pace and distance

      let duration = HeatmapperWorkout.intervalArray[count].duration?.duration
      // have to use extension on TimeInterval as DateComponentsFormatter does not support sub-second precision
      let durationStr = duration?.toReadableString()
      row.durationLabel.setText(durationStr)

      switch HeatmapperWorkout.intervalArray[count].activity {
      case "Walking":
        row.group.setBackgroundColor(.orange)
        row.activityTypeLabel.setText("walk")
      case "Running":
        row.group.setBackgroundColor(.red)
        row.activityTypeLabel.setText("run")
      case "Stationary":
        row.group.setBackgroundColor(UIColor(named: "textPrimary"))
        row.activityTypeLabel.setText("stationary")
      default:
        row.group.setBackgroundColor(.clear)
        row.activityTypeLabel.setText("stationary")
      }
    }

  } // func loadTable

}
