//
//  FootballPitchOverlayView.swift
//  Heatmapper
//
//  Created by Richard English on 15/10/2021.
//  Copyright © 2021 Richard English. All rights reserved.
//
//  This class is the overlay renderer for the Football Pitch overlay
//

import MapKit

class FootballPitchOverlayRenderer: MKOverlayRenderer {
  let overlayImage: UIImage
  let angle : CGFloat
//  let pointsDistance : CGFloat

  init(overlay: MKOverlay, overlayImage: UIImage, angle: CGFloat) {
//    init(overlay: MKOverlay, overlayImage: UIImage, angle: CGFloat, pointsDistance: CGFloat) {

    self.overlayImage = overlayImage
    self.angle = angle
    super.init(overlay: overlay)
  }


  override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
    guard let imageReference = overlayImage.cgImage else { return }

    let rect = self.rect(for: overlay.boundingMapRect)
    context.scaleBy(x: 1.0, y: -1.0)
    context.rotate(by: angle)
    context.draw(imageReference, in: rect)

  }
}

