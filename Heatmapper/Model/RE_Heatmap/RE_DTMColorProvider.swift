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
//// Play with the pivot point and max alpha to affect the look of the heatmap
//
//// This number should be between 0 and 1
//private let kSBAlphaPivotX: CGFloat = 0.333
//// This number should be between 0 and MAX_ALPHA
//private let kSBAlphaPivotY: CGFloat = 0.5
//// This number should be between 0 and 1
//private let kSBMaxAlpha: CGFloat = 0.85
//
//class DTMColorProvider: NSObject {
//  func color(
//    forValue value: Double,
//    red: UnsafeMutablePointer<CGFloat>?,
//    green: UnsafeMutablePointer<CGFloat>?,
//    blue: UnsafeMutablePointer<CGFloat>?,
//    alpha: UnsafeMutablePointer<CGFloat>?
//  ) {
//  }
////}
////
////class DTMColorProvider {
//  static let colorMaxVal = 255
//
//  func color(
//    forValue value: Double,
//    red: UnsafeMutablePointer<CGFloat>?,
//    green: UnsafeMutablePointer<CGFloat>?,
//    blue: UnsafeMutablePointer<CGFloat>?,
//    alpha: UnsafeMutablePointer<CGFloat>?
//  ) {
//    var value = value
//    var red = red
//    var green = green
//    var blue = blue
//    var alpha = alpha
//    if value > 1 {
//      value = 1
//    }
//
//    value = sqrt(value)
//
//    if value < kSBAlphaPivotY {
//      alpha = UnsafeMutablePointer<CGFloat>(mutating: value * kSBAlphaPivotY / kSBAlphaPivotX)
//    } else {
//      alpha = UnsafeMutablePointer<CGFloat>(mutating: kSBAlphaPivotY + ((kSBMaxAlpha - kSBAlphaPivotY) / (1 - kSBAlphaPivotX)) * (value - kSBAlphaPivotX))
//    }
//
//    //formula converts a number from 0 to 1.0 to an rgb color.
//    //uses MATLAB/Octave colorbar code
//    if value <= 0 {
//      alpha = nil
//      blue = alpha
//      green = blue
//      red = green
//    } else if value < 0.125 {
//      green = nil
//      red = green
//      blue = UnsafeMutablePointer<CGFloat>(mutating: 4 * (value + 0.125))
//    } else if value < 0.375 {
//      red = nil
//      green = UnsafeMutablePointer<CGFloat>(mutating: 4 * (value - 0.125))
//      blue = UnsafeMutablePointer<CGFloat>(mutating: 1)
//    } else if value < 0.625 {
//      red = UnsafeMutablePointer<CGFloat>(mutating: 4 * (value - 0.375))
//      green = UnsafeMutablePointer<CGFloat>(mutating: 1)
//      blue = UnsafeMutablePointer<CGFloat>(mutating: 1 - 4 * (value - 0.375))
//    } else if value < 0.875 {
//      red = UnsafeMutablePointer<CGFloat>(mutating: 1)
//      green = UnsafeMutablePointer<CGFloat>(mutating: 1 - 4 * (value - 0.625))
//      blue = nil
//    } else {
//      red = max(1 - 4 * (value - 0.875), 0.5)
//      blue = nil
//      green = blue
//    }
//
//    alpha *= DTMColorProvider.colorMaxVal
//    blue *= alpha
//    green *= alpha
//    red *= alpha
//  }
//}
