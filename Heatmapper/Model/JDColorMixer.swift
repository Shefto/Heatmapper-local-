//
//  JDColorMixer.swift
//  Heatmapper
//
//  Created by Richard English on 24/04/2021.
//  Copyright © 2021 Richard English. All rights reserved.
//

import UIKit

// Blurry mode creates the nice heatmap style effect
enum ColorMixerMode
{
  case BlurryMode
  case DistinctMode
}

// structure for the colour mix
// this is used to pass colour definitions between modules
struct BytesRGB
{
  var redRow      : UTF8Char = 0
  var greenRow    : UTF8Char = 0
  var blueRow     : UTF8Char = 0
  var alphaRow    : UTF8Char = 255
}

// as its name suggests, this class mixes the colours to be applied to the heatmap and heatmap points
class JDHeatMapColorMixer :  NSObject
{
  var colourArray         : [UIColor]  = []
  var mixerMode           : ColorMixerMode = .DistinctMode
  let colorMixerThread    = DispatchQueue(label: "ColorMixer.Thread")

  // initialize the colour mixer - set up the array of colours to be used (
  init (array: [UIColor], level: Int)
  {
    super.init()
    colorMixerThread.async {[weak self] in

      let divideLevel = level
      if (divideLevel == 0) {
        MyFunc.logMessage(.error, "JDHeatMapColorMixer received invalid level 0")
      }

      if (divideLevel == 1) {
        self?.colourArray = array
        return
      }

      for index in 0..<array.count
      {
        // this line included to break out of for...in loop if the array is empty
        if (index == array.count-1) {
          break
        }

        if let rgb = array[index].rgb(), let rgb2 = array[index+1].rgb()
        {
          let greenDiff = (rgb2.green - rgb.green)  / Float(divideLevel)
          let redDiff   = (rgb2.red   - rgb.red)    / Float(divideLevel)
          let blueDiff  = (rgb2.blue  - rgb.blue)   / Float(divideLevel)

          // add all colours to the array
          for colourDivide in 0..<(divideLevel+1)
          {
            let colourStep  : Float = Float(colourDivide)
            let red   = CGFloat(rgb.red   + (redDiff   * colourStep)) / 255.0
            let green = CGFloat(rgb.green + (greenDiff * colourStep)) / 255.0
            let blue  = CGFloat(rgb.blue  + (blueDiff  * colourStep)) / 255.0
            let color = UIColor(red:red, green: green, blue: blue, alpha: 1.0)
            self?.colourArray.append(color)
          }
        }
      }
    }
  }

  func getTargetColourRGB(targetLevel targetFloat: Float) -> BytesRGB
  {
    
    func getDistinctRGB(inDestiny targetFloat : Float) -> BytesRGB
    {
      if (targetFloat == 0) // Only None Flat Data Type will Have 0 target
      {
        let rgb : BytesRGB = BytesRGB(redRow: 0,
                                      greenRow: 0,
                                      blueRow: 0,
                                      alphaRow: 0)
        return rgb
      }

      let colorCount = colourArray.count

      // if there is only one colour in the palette, add clear so we have a range to work with
      if (colorCount < 2)
      {
        colourArray.append(UIColor.clear)
      }

      var targetColour    : UIColor = UIColor()
      // average weight is the average value of each colour
      // e.g if there are 10 colours in the palette, the average weight of each is 1/9th (hmmm)
      let averageWeight   : Float = 1.0 / Float(colorCount - 1)
      var counter         : Float = 0.0

      for colour in colourArray
      {
        // initial next value will be average weight
        let next = counter + averageWeight

        // if the counter is below the target colour
        // and the target colour is below the average weight
        // need to work out what this is doing
        if ((counter <= targetFloat) && targetFloat < next)
        {
          // set the target UIColor to the colour in the array and exit the loop
          targetColour = colour
          break
        }
        else
        {
          counter = next
        }
      }
      // this code  sets the BytesRGB value for the generated colour
      let rgb = targetColour.rgb()

      let redRow    : UTF8Char = UTF8Char(Int((rgb?.red)!))
      let GreenRow  : UTF8Char = UTF8Char(Int((rgb?.green)!))
      let BlueRow   : UTF8Char = UTF8Char(Int((rgb?.blue)!))

      let colourRGB : BytesRGB = BytesRGB(redRow: redRow,
                                         greenRow: GreenRow,
                                         blueRow: BlueRow,
                                         alphaRow: 255)
      return colourRGB
    }

    func getBlurryRGB(inDestiny targetFloat :Float) -> BytesRGB
    {
      if(targetFloat == 0)
      {
        let rgb : BytesRGB = BytesRGB(redRow: 0,
                                      greenRow: 0,
                                      blueRow: 0,
                                      alphaRow: 0)
        return rgb
      }

      let colorCount = colourArray.count
      if(colorCount < 2)
      {
        colourArray.append(UIColor.clear)
      }

      var targetColour    : [UIColor] = []
      let averageWeight   : Float = 1.0 / Float(colorCount-1)
      var counter         : Float = 0.0
      var rightDifference           : Float = 0.0
      var index = 0

      for colour in colourArray
      {
        if( ((targetFloat < (counter + averageWeight)) && (targetFloat > counter))) //The Target colour is between these two colours
        {
          targetColour.append(colour)
          let secondColour = colourArray[index+1]
          targetColour.append(secondColour)
          //
          rightDifference = (targetFloat - counter)
          break
        }
        else if(counter == targetFloat)
        {
          targetColour = [colour,colour]
          break
        }
        index += 1
        counter += averageWeight
      }

      if(rightDifference > 1) { fatalError("RDiff Error") }
      let leftDifference = 1.0 - rightDifference

      func calculateRGB() -> BytesRGB
      {
        if(targetColour.count != 2) {
          fatalError("Color Mixer Problem")
        }
        let leftCGColor         = targetColour[0].rgb()
        let leftRed     :Float  = (leftCGColor?.red)!
        let leftGreen   :Float  = (leftCGColor?.green)!
        let leftBlue    :Float  = (leftCGColor?.blue)!

        let rightCGColor = targetColour[1].rgb()
        let rightRed:Float = (rightCGColor?.red)!
        let rightGreen:Float = (rightCGColor?.green)!
        let rightBlue:Float = (rightCGColor?.blue)!

        //
        let redRow:UTF8Char = UTF8Char(Float(leftRed * leftDifference + rightRed * rightDifference) * targetFloat)
        let greenRow:UTF8Char = UTF8Char(Float(leftGreen * leftDifference + rightGreen * rightDifference) * targetFloat)
        let blueRow:UTF8Char = UTF8Char(Float(leftBlue * leftDifference + rightBlue * rightDifference) * targetFloat)

        return BytesRGB(redRow: redRow,
                        greenRow: greenRow,
                        blueRow: blueRow,
                        alphaRow: UTF8Char(targetFloat * 255))
      }
      return calculateRGB()
    }

    if (mixerMode == .BlurryMode)
    {
      return getBlurryRGB(inDestiny: targetFloat)
    }
    else if(mixerMode == .DistinctMode)
    {
      return getDistinctRGB(inDestiny: targetFloat)
    }
    return BytesRGB(redRow: 0,
                    greenRow: 0,
                    blueRow: 0,
                    alphaRow: 0)
  }
}

extension UIColor {

  func rgb() -> (red: Float, green: Float, blue:Float, alpha: Float)? {

    var floatRed    : CGFloat = 0
    var floatGreen  : CGFloat = 0
    var floatBlue   : CGFloat = 0
    var floatAlpha  : CGFloat = 0

    if self.getRed(&floatRed, green: &floatGreen, blue: &floatBlue, alpha: &floatAlpha) {
      let iRed    = Float(floatRed * 255.0)
      let iGreen  = Float(floatGreen * 255.0)
      let iBlue   = Float(floatBlue * 255.0)
      let iAlpha  = Float(floatAlpha * 255.0)

      return (red: iRed, green: iGreen, blue: iBlue, alpha: iAlpha)
    } else {
      // Could not extract RGBA components:
      return nil
    }
  }
}
