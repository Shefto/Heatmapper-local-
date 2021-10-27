//
//  FootballPitchOverlayView.swift
//  Heatmapper
//
//  Created by Richard English on 15/10/2021.
//  Copyright © 2021 Richard English. All rights reserved.
//

import MapKit

class FootballPitchOverlayView: MKOverlayRenderer {
  let overlayImage: UIImage
  let angle : CGFloat

  // 1
  init(overlay: MKOverlay, overlayImage: UIImage, angle: CGFloat) {
    self.overlayImage = overlayImage
    self.angle = angle
    super.init(overlay: overlay)
  }

  // 2
  override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
    guard let imageReference = overlayImage.cgImage else { return }

    let rect = self.rect(for: overlay.boundingMapRect)
    context.scaleBy(x: 1.0, y: -1.0)
    context.translateBy(x: 0.0, y: -rect.size.height)
    context.rotate(by: angle)
    context.draw(imageReference, in: rect)

  }
}

