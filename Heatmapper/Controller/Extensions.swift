//
//  Extensions.swift
//  Heatmapper
//
//  Created by Richard English on 10/09/2020.
//  Copyright © 2020 Richard English. All rights reserved.
//

import UIKit
import HealthKit

public protocol With {}

// extension to enable setting of closures while initializing - see https://github.com/devxoul/Then
public extension With where Self: Any {

  @discardableResult
  func with(_ block: (Self) -> Void) -> Self {
    block(self)
    return self
  }
}

extension NSObject: With {}

extension TimeInterval {

  func toMinutesAndSeconds() -> String {

    guard self >= 0 && self < Double.infinity else {
      return "unknown"
    }
    // using rounded function as simply truncatingRemainder does not cater for rounding
    let roundedTimeInterval = self.rounded(digits: 1)
    let seconds = Int(roundedTimeInterval) % 60
    let minutes = (Int(roundedTimeInterval) / 60) % 60
    let hours = (Int(roundedTimeInterval) / 3600)
    if hours != 0 {
      return String(format: "%0.2d:%0.2d", minutes, seconds)
    }
    if minutes != 0 {
      return String(format: "%2d:%0.2d", minutes, seconds)
    }
    return String(format: "%1d:%0.2d", minutes, seconds)

  }

  func toHours() -> String {

    guard self >= 0 && self < Double.infinity else {
      return "unknown"
    }
    // using rounded function as simply truncatingRemainder does not cater for rounding
    let roundedTimeInterval = self.rounded(digits: 1)

    let hours = (Int(roundedTimeInterval) / 3600) % 3600

    var hourStr: String = ""
    if hours != 0 {
      hourStr = String(format: "%2d", hours)
    } else {
      hourStr =  String(format: "%1d", hours)
    }

    hourStr = hourStr.trimmingCharacters(in: .whitespacesAndNewlines)
    return hourStr
  }

  func toMinutes() -> String {

    guard self >= 0 && self < Double.infinity else {
      return "unknown"
    }
    // using rounded function as simply truncatingRemainder does not cater for rounding
    let roundedTimeInterval = self.rounded(digits: 1)

    let minutes = (Int(roundedTimeInterval) / 60) % 60

    var minutesStr: String = ""
    if minutes != 0 {
      minutesStr = String(format: "%2d", minutes)
    } else {
    minutesStr =  String(format: "%1d", minutes)
    }

    minutesStr = minutesStr.trimmingCharacters(in: .whitespacesAndNewlines)
    return minutesStr
  }

  func toSeconds(_ stride: Int? = 1) -> String {

    guard self >= 0 && self < Double.infinity else {
      return "unknown"
    }
    // using rounded function as simply truncatingRemainder does not cater for rounding
    let roundedTimeInterval = self.rounded(digits: 1)

    let seconds = Int(roundedTimeInterval) % 60
    let secondsToStride = (seconds / stride!) * stride!

    var secondsStr = String(describing: secondsToStride)
    secondsStr = secondsStr.trimmingCharacters(in: .whitespacesAndNewlines)

    if secondsStr == "0" {
      secondsStr = "00"
    }

    if secondsStr == "5" {
      secondsStr = "05"
    }
      return secondsStr
  }

  func toReadableString() -> String {

    guard self >= 0 && self < Double.infinity else {
      return "unknown"
    }

    // using rounded function as simply truncatingRemainder does not cater for rounding
    let roundedTimeInterval = self.rounded(digits: 1)

    // Deciseconds
    let deciseconds = Int((roundedTimeInterval.truncatingRemainder(dividingBy: 1)) * 10)

    // Seconds
    let seconds = Int(roundedTimeInterval) % 60
    // Minutes
    let minutes = (Int(roundedTimeInterval) / 60) % 60
    // Hours
    let hours = (Int(roundedTimeInterval) / 3600)

    if hours != 0 {
      return String(format: "%2d:%0.2d %0.2d", hours, minutes, seconds)
    }
    if minutes != 0 {
      return String(format: "%2d:%0.2d", minutes, seconds)
    }

    return String(format: "%2d.%0.1d", seconds, deciseconds)

  }

  var time: String {
    return String(format: "%02d:%02d", Int(self/60), Int(ceil(truncatingRemainder(dividingBy: 60))) )
  }
}

// extension for rounding Doubles to decimal places
extension Double {
  func rounded(digits: Int) -> Double {
    let multiplier = pow(10.0, Double(digits))
    return (self * multiplier).rounded() / multiplier
  }
}

extension HKHealthStore {

  // Fetches the single most recent quantity of the specified type.
  func mostRecentQuantitySampleOfType(_ quantityType: HKQuantityType, predicate: NSPredicate?, completion: ((HKQuantity?, Error?) -> Void)?) {
    let timeSortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

    // Since we are interested in retrieving the user's latest sample, we sort the samples in descending order, and set the limit to 1. We are not filtering the data, and so the predicate is set to nil.
    let query = HKSampleQuery(sampleType: quantityType, predicate: nil, limit: 1, sortDescriptors: [timeSortDescriptor]) {_, results, error in
      if results == nil {
        completion?(nil, error)

        return
      }

      if completion != nil {
        // If quantity isn't in the database, return nil in the completion block.
        let quantitySample = results!.first as? HKQuantitySample
        let quantity = quantitySample?.quantity

        completion!(quantity, error)
      }
    }

    self.execute(query)
  }

}

extension Int {
  var degreesToRadians: CGFloat {
    return CGFloat(self) * .pi / 180
  }
}

public extension UIWindow {

  // Unload all views and add back.
  // Useful for applying `UIAppearance` changes to existing views.
  func reload() {
    subviews.forEach { view in
      view.removeFromSuperview()
      addSubview(view)
    }
  }
}

public extension Array where Element == UIWindow {

  // Unload all views for each `UIWindow` and add back.
  // Useful for applying `UIAppearance` changes to existing views.
  func reload() {
    forEach { $0.reload() }
  }
}

extension UIColor {
  convenience init?(hex: String) {
    var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
    hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

    var rgb: UInt64 = 0

    var red: CGFloat = 0.0
    var green: CGFloat = 0.0
    var blue: CGFloat = 0.0
    var alpha: CGFloat = 1.0

    let length = hexSanitized.count

    guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

    if length == 6 {
      red = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
      green = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
      blue = CGFloat(rgb & 0x0000FF) / 255.0

    } else if length == 8 {
      red = CGFloat((rgb & 0xFF000000) >> 24) / 255.0
      green = CGFloat((rgb & 0x00FF0000) >> 16) / 255.0
      blue = CGFloat((rgb & 0x0000FF00) >> 8) / 255.0
      alpha = CGFloat(rgb & 0x000000FF) / 255.0

    } else {
      return nil
    }

    self.init(red: red, green: green, blue: blue, alpha: alpha)
  }
}

extension UIColor {

  public class func dynamicColor(light: UIColor, dark: UIColor) -> UIColor {
    if #available(iOS 13.0, *) {
      return UIColor {
        switch $0.userInterfaceStyle {
        case .dark:
          return dark
        default:
          return light
        }
      }
    } else {
      return light
    }
  }
}

extension UIView {
  var globalFrame: CGRect? {
    let keyWindow = UIApplication.shared.windows.first { $0.isKeyWindow }
    let rootView = keyWindow?.rootViewController?.view
    return self.superview?.convert(self.frame, to: rootView)
  }
}

extension UIButton {
  func roundCorners(corners: UIRectCorner, radius: Int = 9) {
    let maskPath1 = UIBezierPath(roundedRect: bounds,
                                 byRoundingCorners: corners,
                                 cornerRadii: CGSize(width: radius, height: radius))
    let maskLayer1 = CAShapeLayer()
    maskLayer1.frame = bounds
    maskLayer1.path = maskPath1.cgPath
    layer.mask = maskLayer1
  }
}

extension UIBarButtonItem {
  var view: UIView? {
    return value(forKey: "view") as? UIView
  }
}

extension Sequence where Element: NSAttributedString {

  func join(withSeparator separator: NSAttributedString) -> NSAttributedString {
    let finalString = NSMutableAttributedString()
    for (index, string) in enumerated() {
      if index > 0 {
        finalString.append(separator)
      }
      finalString.append(string)
    }
    return finalString
  }
}

extension UIFont {
  func withTraits(traits:UIFontDescriptor.SymbolicTraits) -> UIFont {
    let descriptor = fontDescriptor.withSymbolicTraits(traits)
    return UIFont(descriptor: descriptor!, size: 0) //size 0 means keep the size as it is
  }

  func bold() -> UIFont {
    return withTraits(traits: .traitBold)
  }

  func italic() -> UIFont {
    return withTraits(traits: .traitItalic)
  }

  func regular() -> UIFont {
    let descriptor = UIFontDescriptor.init()
    return UIFont(descriptor: descriptor, size: 0)
  }

}

extension UnitSpeed {
  class var secondsPerMeter: UnitSpeed {
    return UnitSpeed(symbol: "sec/m", converter: UnitConverterPace(coefficient: 1))
  }

  class var minutesPerKilometer: UnitSpeed {
    return UnitSpeed(symbol: "min/km", converter: UnitConverterPace(coefficient: 50/3))
  }

  class var minutesPerMile: UnitSpeed {
    return UnitSpeed(symbol: "min/mi", converter: UnitConverterPace(coefficient: 26.8224))
  }
}
