////
////  RE_DTMDiffColorProvider.swift
////  Heatmapper
////
////  Created by Richard English on 08/07/2021.
////  Copyright © 2021 Richard English. All rights reserved.
////
//
////  Converted to Swift 5.4 by Swiftify v5.4.29596 - https://swiftify.com/
//
//import UIKit
//
//class RE_DiffColorProvider : RE_ColorProvider {
////  static let colorMaxVal = 255
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
//
//    if value == 0 {
//      return
//    }
//
//    let isNegative = value < 0
//    value = sqrt(min(abs(value), 1))
//    if value < kSBAlphaPivotY {
//      alpha = UnsafeMutablePointer<CGFloat>(mutating: value * kSBAlphaPivotY / kSBAlphaPivotX)
//    } else {
//      alpha = UnsafeMutablePointer<CGFloat>(mutating: kSBAlphaPivotY + ((kSBMaxAlpha - kSBAlphaPivotY) / (1 - kSBAlphaPivotX)) * (value - kSBAlphaPivotX))
//    }
//
//    if isNegative {
//      red = nil
//      if value <= 0 {
//        alpha = nil
//        blue = alpha
//        green = blue
//      } else if value < 0.125 {
//        green = nil
//        blue = UnsafeMutablePointer<CGFloat>(mutating: 2 * (value + 0.125))
//      } else if value < 0.375 {
//        blue = UnsafeMutablePointer<CGFloat>(mutating: 2 * (value + 0.125))
//        green = UnsafeMutablePointer<CGFloat>(mutating: 4 * (value - 0.125))
//      } else if value < 0.625 {
//        blue = UnsafeMutablePointer<CGFloat>(mutating: 4 * (value - 0.375))
//        green = UnsafeMutablePointer<CGFloat>(mutating: 1)
//      } else if value < 0.875 {
//        blue = UnsafeMutablePointer<CGFloat>(mutating: 1)
//        green = UnsafeMutablePointer<CGFloat>(mutating: 1 - 4 * (value - 0.625))
//      } else {
//        blue = max(1 - 4 * (value - 0.875), 0.5)
//        green = nil
//      }
//    } else {
//      blue = nil
//      if value <= 0 {
//        alpha = nil
//        green = alpha
//        red = green
//      } else if value < 0.125 {
//        green = UnsafeMutablePointer<CGFloat>(mutating: &value)
//        red = UnsafeMutablePointer<CGFloat>(mutating: &value)
//      } else if value < 0.375 {
//        red = UnsafeMutablePointer<CGFloat>(mutating: (value + 0.125))
//        green = UnsafeMutablePointer<CGFloat>(mutating: &value)
//      } else if value < 0.625 {
//        red = UnsafeMutablePointer<CGFloat>(mutating: (value + 0.125))
//        green = UnsafeMutablePointer<CGFloat>(mutating: &value)
//      } else if value < 0.875 {
//        red = UnsafeMutablePointer<CGFloat>(mutating: (value + 0.125))
//        green = UnsafeMutablePointer<CGFloat>(mutating: 1 - 4 * (value - 0.625))
//      } else {
//        green = nil
//        red = max(1 - 4 * (value - 0.875), 0.5)
//      }
//    }
//
//    alpha *= RE_DiffColorProvider.colorMaxVal
//    blue *= alpha
//    green *= alpha
//    red *= alpha
//  }
//}
