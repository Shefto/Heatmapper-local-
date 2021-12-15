////
////  RE_DTMColorProvider.swift
////  Heatmapper
////
////  Created by Richard English on 08/07/2021.
////  Copyright © 2021 Richard English. All rights reserved.
////
//
//import UIKit
//
//// These affect the transparency of the heatmap
//// Colder areas will be more transparent
//// Currently the alpha is a two piece linear function of the value
//
//// Play with the pivot point and max alpha to affect the look of the heatmap
//
//// This number should be between 0 and 1
//private let kSBAlphaPivotX: Double = 0.333
//// This number should be between 0 and MAX_ALPHA
//private let kSBAlphaPivotY: Double = 0.5
////private let kSBAlphaPivotY: CGFloat = 0.5
//
//// This number should be between 0 and 1
//private let kSBMaxAlpha: Double = 0.85
//
//class REColourProvider: NSObject {
//
////class DTMColorProvider {
//  static let colorMaxVal = 255
//
//  func color(forValue value: Double, red: Double, green: Double, blue: Double, alpha: Double) {
//
//    var red = red
//    var green = green
//    var blue = blue
//    var alpha = alpha 
//
//    var value2 = value
//    if value2 > 1 {
//      value2 = 1
//    }
//
//    value2 = sqrt(value2)
//
//    if value < kSBAlphaPivotY {
//      alpha = value * kSBAlphaPivotY / Double(kSBAlphaPivotX)
//    } else {
//      let maxAlphaMinusPivotY = kSBMaxAlpha - kSBAlphaPivotY
//      let oneMinusPivotX = 1 - kSBAlphaPivotX
//      let valueMinusPivotX = value - kSBAlphaPivotX
//      let alphaSum2 = maxAlphaMinusPivotY / oneMinusPivotX * valueMinusPivotX
//      alpha = kSBAlphaPivotY + alphaSum2
//
//    }
//
//    //formula converts a number from 0 to 1.0 to an rgb color.
//    //uses MATLAB/Octave colorbar code
//    if value <= 0 {
//      alpha = 0
//      blue = alpha
//      green = blue
//      red = green
//    } else if value < 0.125 {
//      green = 0
//      red = green
//      blue = 4 * (value + 0.125)
//    } else if value < 0.375 {
//      red = 0
//      green = 4 * (value - 0.125)
//      blue = 1
//    } else if value < 0.625 {
//      red = 4 * (value - 0.375)
//      green = 1
//      blue = 1 - 4 * (value - 0.375)
//    } else if value < 0.875 {
//      red = 1
//      green = 1 - 4 * (value - 0.625)
//      blue = 0
//    } else {
//      red = max(1 - 4 * (value - 0.875), 0.5)
//      blue = 0
//      green = blue
//    }
//
//    alpha *= 255
//    blue =  alpha
//    green = alpha
//    red *= alpha
//  }
//}
