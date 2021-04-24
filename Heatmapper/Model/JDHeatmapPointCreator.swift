//
//  JDHeatmapPointCreator.swift
//  Heatmapper
//
//  Created by Richard English on 24/04/2021.
//  Copyright © 2021 Richard English. All rights reserved.
//


import Foundation
import MapKit

// this structure defines a CGPoint (i.e. a point in a 2D coordinate system) together with the heat level and radius
// in essence, a point to be added to the heatmap
struct HeatmapPointCG {
  var heatlevel     : Float   = 0
  var localCGpoint  : CGPoint = CGPoint.zero
  var radius        : CGFloat = 0
}

struct IntSize {
  var width         : Int = 0
  var height        : Int = 0
}

/**
 All this class needs to know is relative position & CGSize
 And produce an array of RGBA colours
 **/
// this class is subclassed depending upon the point type
// results in duplication which could be removed
// essentially it creates the heatmap shape from an array of heatmap points
class HeatmapPointCreator: NSObject
{
  /*
   These two variables should not be modified after
   */
  var originalHeatmapPointArray : [HeatmapPointCG] = []
  var originalCGSize            : CGSize = CGSize.zero

  static var theColorMixer      : JDHeatMapColorMixer!

  var heatmapPointColourArray   : [UTF8Char] = []
  var heatmapPointArray         : [HeatmapPointCG] = []
  // IntSize is simply a structure with two variables, height and weight
  var fitnessIntSize            : IntSize!

  var BytesPerRow               : Int
  {
    return 4 * fitnessIntSize.width
  }

  init (size: CGSize, heatmapPointArray: [HeatmapPointCG])
  {
    super.init()
    self.originalHeatmapPointArray = heatmapPointArray
    self.originalCGSize = size
  }

  // function to reduce the image size as MKMapRect has a high definition
  func reduceSize(scales: Double)
  {
    let scale       : CGFloat = CGFloat(scales) * 1.5
    let newWidth    = Int(originalCGSize.width * scale)
    let newHeight   = Int(originalCGSize.height * scale)
    self.fitnessIntSize = IntSize(width: newWidth, height: newHeight)

    func reduceHeatmapPointSize()
    {
      heatmapPointArray.removeAll()
      for heatmapPoint in originalHeatmapPointArray
      {
        let newX = heatmapPoint.localCGpoint.x * scale
        let newY = heatmapPoint.localCGpoint.y * scale
        let newCGPoint = CGPoint(x: newX, y: newY)
        let newRadius = heatmapPoint.radius * scale
        let modifiedHeatmapPoint = HeatmapPointCG(heatlevel: heatmapPoint.heatlevel, localCGpoint: newCGPoint, radius: newRadius)
        heatmapPointArray.append(modifiedHeatmapPoint)
      }
    }
    reduceHeatmapPointSize()
    heatmapPointColourArray = Array.init(repeating: 0, count: 4 * fitnessIntSize.width * fitnessIntSize.height)
  }

  /**
   SubClass Should Override thie method
   **/
  func createHeatmapPoint()
  {
  }
}

class HeatmapRadiusPointCreator: HeatmapPointCreator
{

  // this function creates the heatmap point including calculating the colour required depending upon the point's proximity to other heatmap points
  // in effect, it adds the heatmap point to the actual heatmap heat area
  override func createHeatmapPoint()
  {
    //print(#function + "w:\(FitnessIntSize.width),w:\(FitnessIntSize.height)")
    var byteCount :Int = 0
    for height in 0..<self.fitnessIntSize.height
    {
      for width in 0..<self.fitnessIntSize.width
      {
        // "destiny" appears to be the ultimate required colour of the point as part of a heatmap area
        var target : Float = 0
        for heatmapPoint in self.heatmapPointArray
        {
          let pixelCGPoint          = CGPoint(x: width, y: height)
          let bytesDistanceToPoint  : Float = pixelCGPoint.distanceTo(anther: heatmapPoint.localCGpoint)
          let ratio                 : Float = 1 - (bytesDistanceToPoint / Float(heatmapPoint.radius))
          if  (ratio > 0)
          {
            target += ratio * heatmapPoint.heatlevel
          }
        }
        if(target > 1)
        {
          target = 1
        }
        let rgb = HeatmapPointCreator.theColorMixer.getTargetColourRGB(inDestiny: target)

        let redRow    : UTF8Char = rgb.redRow
        let greenRow  : UTF8Char = rgb.greenRow
        let blueRow   : UTF8Char = rgb.blueRow
        let alpha     : UTF8Char = rgb.alphaRow

        self.heatmapPointColourArray[byteCount]   = redRow
        self.heatmapPointColourArray[byteCount+1] = greenRow
        self.heatmapPointColourArray[byteCount+2] = blueRow
        self.heatmapPointColourArray[byteCount+3] = alpha
        byteCount += 4
      }
    }
  }
}

class HeatmapFlatPointCreator: HeatmapPointCreator
{

  // this function creates the heatmap point including calculating the colour required depending upon the point's proximity to other heatmap points
  // in effect, it adds the heatmap point to the actual heatmap heat area
  override func createHeatmapPoint()
  {
    print(#function + "w:\(fitnessIntSize.width),h:\(fitnessIntSize.height)")
    var byteCount : Int = 0
    for height in 0..<self.fitnessIntSize.height
    {
      for width in 0..<self.fitnessIntSize.width
      {
        var target : Float = 0
        for heatmapPoint in self.heatmapPointArray
        {
          let pixelCGPoint = CGPoint(x: width, y: height)
          let bytesDistanceToPoint : Float = pixelCGPoint.distanceTo(anther: heatmapPoint.localCGpoint)
          let ratio : Float = 1 - (bytesDistanceToPoint / Float(heatmapPoint.radius))
          if (ratio > 0)
          {
            target += ratio * heatmapPoint.heatlevel
          }
        }
        if (target == 0)
        {
          target += 0.01
        }

        if(target > 1)
        {
          target = 1
        }

        let rgb = HeatmapPointCreator.theColorMixer.getTargetColourRGB(inDestiny: target)

        let redRow    : UTF8Char = rgb.redRow
        let greenRow  : UTF8Char = rgb.greenRow
        let blueRow   : UTF8Char = rgb.blueRow
        let alpha     : UTF8Char = UTF8Char(Int(target * 255))

        self.heatmapPointColourArray[byteCount]   = redRow
        self.heatmapPointColourArray[byteCount+1] = greenRow
        self.heatmapPointColourArray[byteCount+2] = blueRow
        self.heatmapPointColourArray[byteCount+3] = alpha
        byteCount += 4
      }
    }
  }
}



extension CGPoint
{
  func distanceTo(anther point:CGPoint)->Float
  {
    let xDistance = (self.x - point.x) * (self.x - point.x)
    let yDistance = (self.y - point.y) * (self.y - point.y)
    return sqrtf(Float(xDistance + yDistance))
  }
}
