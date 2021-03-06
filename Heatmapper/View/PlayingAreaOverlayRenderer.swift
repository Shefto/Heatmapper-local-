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

class PlayingAreaOverlayRenderer: MKOverlayRenderer {
  let overlayImage      : UIImage
  let angle             : CGFloat
  var workoutId         : UUID?

  init(overlay: MKOverlay, overlayImage: UIImage, angle: CGFloat, workoutId: UUID) {

    self.overlayImage = overlayImage
    self.angle        = angle
    self.workoutId    = workoutId
    super.init(overlay: overlay)
  }

  init(overlay: MKOverlay, overlayImage: UIImage, angle: CGFloat) {

    self.overlayImage = overlayImage
    self.angle        = angle
    super.init(overlay: overlay)
  }


  override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
    guard let imageReference = overlayImage.cgImage else { return }

    let rect = self.rect(for: overlay.boundingMapRect)
    context.scaleBy(x: 1.0, y: -1.0)
    context.rotate(by: angle)
    context.draw(imageReference, in: rect)

  }

  func getDocumentsDirectory() -> URL {
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    let documentsDirectory = paths[0]
    return documentsDirectory
  }

}

