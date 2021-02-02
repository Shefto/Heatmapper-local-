//
//  UnitConverterPace.swift
//  Heatmapper
//
//  Created by Richard English on 14/01/2021.
//  Copyright © 2021 Richard English. All rights reserved.
//

import Foundation

class UnitConverterPace: UnitConverter {
  private let coefficient: Double

  init(coefficient: Double) {
    self.coefficient = coefficient
  }

  override func baseUnitValue(fromValue value: Double) -> Double {
    return reciprocal(value * coefficient)
  }

  override func value(fromBaseUnitValue baseUnitValue: Double) -> Double {
    return reciprocal(baseUnitValue * coefficient)
  }

  private func reciprocal(_ value: Double) -> Double {
    guard value != 0 else { return 0 }
    return 1.0 / value
  }
}
