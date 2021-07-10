//
//  RE_DTMDiffHeatmap.swift
//  Heatmapper
//
//  Created by Richard English on 08/07/2021.
//  Copyright © 2021 Richard English. All rights reserved.
//
//  Converted to Swift 5.4 by Swiftify v5.4.29596 - https://swiftify.com/i//  Converted to Swift 5.4 by Swiftify v5.4.29596 - https://swiftify.com/


class DTMDiffHeatmap {
  private var maxValue = 0.0
  private var zoomedOutMax = 0.0
  private var pointsWithHeat: [AnyHashable : Any]?
  private var center: CLLocationCoordinate2D?
  private var boundingRect: MKMapRect!

  init() {
    super.init()
    colorProvider = DTMDiffColorProvider()
  }

  func setBeforeData(
    _ before: [AnyHashable : Any]?,
    afterData after: [AnyHashable : Any]?
  ) {
    maxValue = 0

    var newHeatMapData: [AnyHashable : Any] = [:]
    for mapPointValue in before?.keys ?? [] {
      guard let mapPointValue = mapPointValue as? NSValue else {
        continue
      }
      newHeatMapData[mapPointValue] = NSNumber(value: -1 * (before?[mapPointValue] as? NSNumber)?.doubleValue ?? 0.0)
    }

    for mapPointValue in after?.keys ?? [] {
      guard let mapPointValue = mapPointValue as? NSValue else {
        continue
      }
      if newHeatMapData[mapPointValue] != nil {
        let beforeValue = (newHeatMapData[mapPointValue] as? NSNumber).doubleValue
        let afterValue = (after?[mapPointValue] as? NSNumber)?.doubleValue ?? 0.0
        newHeatMapData[mapPointValue] = NSNumber(value: beforeValue + afterValue)
      } else {
        if let aAfter = after?[mapPointValue] {
          newHeatMapData[mapPointValue] = aAfter
        }
      }
    }

    super.data = newHeatMapData
  }
}
