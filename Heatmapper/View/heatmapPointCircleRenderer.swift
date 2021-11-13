//
//  heatmapPointCircleRenderer.swift
//  Heatmapper
//
//  Created by Richard English on 06/11/2021.
//  Copyright © 2021 Richard English. All rights reserved.
//
//  This class

import MapKit

class HeatmapPointCircleRenderer: MKCircleRenderer {

  var innerColour       :     [CGFloat] = [1.0, 0.0, 0.0, 0.9]
  var middleColour      :     [CGFloat] = [1.0, 0.5, 0.0, 0.3]
  var outerColour       :     [CGFloat] = [1.0, 1.0, 0.0, 0.2]
  var gradientLocations :     [CGFloat] = [0.1, 0.4, 0.7]
  var blendMode                         = CGBlendMode.normal

  init(circle: MKCircle, innerColourArray: [CGFloat], middleColourArray: [CGFloat], outerColourArray: [CGFloat], gradientLocationsArray: [CGFloat], blendMode: CGBlendMode) {
    super.init(circle: circle)
    self.innerColour        = innerColourArray
    self.middleColour       = middleColourArray
    self.outerColour        = outerColourArray
    self.gradientLocations  = gradientLocationsArray
    self.blendMode          = blendMode

  }

  override func fillPath(_ path: CGPath, in context: CGContext) {
    let rect: CGRect = path.boundingBox
    context.addPath(path)
    context.clip()
    context.setBlendMode(.multiply)


//    let gradientColors: [CGFloat] = [1.0, 0.0, 0.0, 0.9,
//                                     1.0, 0.5, 0.0, 0.2,
//                                     1.0, 1.0, 0.0, 0.1]
    let colorSpace = CGColorSpaceCreateDeviceRGB()

    let gradientColours = innerColour + middleColour + outerColour

//    consider using when other issues fixed
//    let cgColorArray = [UIColor.systemRed.cgColor, UIColor.systemYellow.cgColor] as CFArray
//    guard let gradient = CGGradient(colorsSpace: colorSpace, colors: cgColorArray, locations: gradientLocations) else { return    }

    guard let gradient = CGGradient(colorSpace: colorSpace, colorComponents: gradientColours, locations: gradientLocations, count: 3) else { return }
    let gradientCenter = CGPoint(x: rect.midX, y: rect.midY)
    let gradientRadius = min(rect.size.width, rect.size.height) / 2
    context.drawRadialGradient(gradient, startCenter: gradientCenter, startRadius: 0, endCenter: gradientCenter, endRadius: gradientRadius, options: .drawsAfterEndLocation)

  }
}
