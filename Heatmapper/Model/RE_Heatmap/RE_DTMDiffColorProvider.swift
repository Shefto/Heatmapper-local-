//
//  RE_DTMDiffHeatmapRenderer.swift
//  Heatmapper
//
//  Created by Richard English on 08/07/2021.
//  Copyright © 2021 Richard English. All rights reserved.
//

import Foundation
class DTMDiffColorProvider: DTMColorProvider {
}

class DTMDiffColorProvider {
  static let colorMaxVal = 255
  
  func color(
    forValue value: Double,
    red: UnsafeMutablePointer<CGFloat>?,
    green: UnsafeMutablePointer<CGFloat>?,
    blue: UnsafeMutablePointer<CGFloat>?,
    alpha: UnsafeMutablePointer<CGFloat>?
  ) {
    var value = value
    var red = red
    var green = green
    var blue = blue
    var alpha = alpha

    if value == 0 {
      return
    }

    let isNegative = value < 0
    value = sqrt(min(abs(value), 1))
    if value < kSBAlphaPivotY {
      alpha = UnsafeMutablePointer<CGFloat>(mutating: value * kSBAlphaPivotY / kSBAlphaPivotX)
    } else {
      alpha = UnsafeMutablePointer<CGFloat>(mutating: kSBAlphaPivotY + ((kSBMaxAlpha - kSBAlphaPivotY) / (1 - kSBAlphaPivotX)) * (value - kSBAlphaPivotX))
    }
    //  Converted to Swift 5.4 by Swiftify v5.4.29596 - https://swiftify.com/
    if isNegative {
      red = 0
      if value <= 0 {
        alpha = 0
        blue = alpha
        green = blue
      } else if value < 0.125 {
        green = 0
        blue = 2 * (value + 0.125)
      } else if value < 0.375 {
        blue = 2 * (value + 0.125)
        green = 4 * (value - 0.125)
      } else if value < 0.625 {
        blue = 4 * (value - 0.375)
        green = 1
      } else if value < 0.875 {
        blue = 1
        green = 1 - 4 * (value - 0.625)
      } else {
        blue = max(1 - 4 * (value - 0.875), 0.5)
        green = 0
      }
    } else {
      blue = 0
      if value <= 0 {
        alpha = 0
        green = alpha
        red = green
      } else if value < 0.125 {
        green = value
        red = value
      } else if value < 0.375 {
        red = (value + 0.125)
        green = value
      } else if value < 0.625 {
        red = (value + 0.125)
        green = value
      } else if value < 0.875 {
        red = (value + 0.125)
        green = 1 - 4 * (value - 0.625)
      } else {
        green = 0
        red = max(1 - 4 * (value - 0.875), 0.5)
      }
    }

    alpha *= maxVal
    blue *= alpha
    green *= alpha
    red *= alpha
  }
}
