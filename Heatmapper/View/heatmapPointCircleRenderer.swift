//
//  heatmapPointCircleRenderer.swift
//  Heatmapper
//
//  Created by Richard English on 06/11/2021.
//  Copyright © 2021 Richard English. All rights reserved.
//


import MapKit

class HeatmapPointCircleRenderer: MKCircleRenderer {


    var innerColour       =     [CGFloat]()
    var middleColour      =     [CGFloat]()
    var outerColour       =     [CGFloat]()
    var gradientLocations =     [CGFloat]()


  var blendMode                         = CGBlendMode.multiply

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
    context.setBlendMode(blendMode)



    let colorSpace = CGColorSpaceCreateDeviceRGB()

    let gradientColours = innerColour + middleColour + outerColour

    guard let gradient = CGGradient(colorSpace: colorSpace, colorComponents: gradientColours, locations: gradientLocations, count: 3) else { return }
    let gradientCenter = CGPoint(x: rect.midX, y: rect.midY)
    let gradientRadius = min(rect.size.width, rect.size.height) / 2
    context.drawRadialGradient(gradient, startCenter: gradientCenter, startRadius: 0, endCenter: gradientCenter, endRadius: gradientRadius, options: .drawsAfterEndLocation)

  }
}
