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

class FootballPitchOverlayView: MKOverlayRenderer {
  let overlayImage: UIImage
  let angle : CGFloat
//  let pointsDistance : CGFloat

  init(overlay: MKOverlay, overlayImage: UIImage, angle: CGFloat) {
//    init(overlay: MKOverlay, overlayImage: UIImage, angle: CGFloat, pointsDistance: CGFloat) {

    self.overlayImage = overlayImage
    self.angle = angle
//    self.pointsDistance = pointsDistance
    super.init(overlay: overlay)
  }


  override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
    guard let imageReference = overlayImage.cgImage else { return }


//    let imageHeight = overlayImage.size.height
//    let imageWidth  = overlayImage.size.width
//
//    let imageHeightSquared = imageHeight * imageHeight
//    let imageWidthSquared =  imageWidth * imageWidth
//    let imageHypotenuseSquared = imageHeightSquared + imageWidthSquared
//    let imageHypotenuse = sqrt(imageHypotenuseSquared)
//

//    MyFunc.logMessage(.debug, "imageHypotenuse: \(imageHypotenuse)")
//    let imageScale = pointsDistance / imageHypotenuse
//    MyFunc.logMessage(.debug, "imageScale: \(imageScale)")

    let rect = self.rect(for: overlay.boundingMapRect)
    context.scaleBy(x: 1.0, y: -1.0)
//    context.scaleBy(x: imageScale, y: imageScale)
//    context.translateBy(x: 0.0, y: -rect.size.height)
    context.rotate(by: angle)
    let contextCTMStr = String(describing: context.ctm)
    print ("contextCTMStr: \(contextCTMStr)")
    context.draw(imageReference, in: rect)

  }
}

