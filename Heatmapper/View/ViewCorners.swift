//
//  ViewCorners.swift
//  Heatmapper
//
//  Created by Richard English on 13/02/2022.
//  Copyright © 2022 Richard English. All rights reserved.
//

import UIKit

// this struct manages the conversion of the rotated view to create a rotated MKMapRect
struct ViewCorners {
  private(set) var topLeft:     CGPoint!
  private(set) var topRight:    CGPoint!
  private(set) var bottomLeft:  CGPoint!
  private(set) var bottomRight: CGPoint!

  private let originalCenter: CGPoint
  private let transformedView: UIView

  private func pointWith(multipliedWidth: CGFloat, multipliedHeight: CGFloat) -> CGPoint {
    var x = originalCenter.x
    x += transformedView.bounds.width  / 2 * multipliedWidth

    var y = originalCenter.y
    y += transformedView.bounds.height / 2 * multipliedHeight

    var result = CGPoint(x: x, y: y).applying(transformedView.transform)
    result.x += transformedView.transform.tx
    result.y += transformedView.transform.ty

    return result
  }

  init(view: UIView) {
    transformedView = view
    originalCenter = view.center.applying(view.transform.inverted())

    topLeft =     pointWith(multipliedWidth:-1, multipliedHeight:-1)
    topRight =    pointWith(multipliedWidth: 1, multipliedHeight:-1)
    bottomLeft =  pointWith(multipliedWidth:-1, multipliedHeight: 1)
    bottomRight = pointWith(multipliedWidth: 1, multipliedHeight: 1)

  }
}
