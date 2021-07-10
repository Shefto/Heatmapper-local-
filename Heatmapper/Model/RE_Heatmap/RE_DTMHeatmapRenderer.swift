//
//  RE_HeatmapRenderer.swift
//  Heatmapper
//
//  Created by Richard English on 08/07/2021.
//  Copyright © 2021 Richard English. All rights reserved.
//


import MapKit
import DTMHeatmap


private let kSBHeatRadiusInPoints = 48

class DTMHeatmapRenderer {
  private var scaleMatrix: UnsafeMutablePointer<Float>?

  init(overlay: MKOverlay?) {
    if let overlay = overlay {
      super.init(overlay: overlay)
      scaleMatrix = malloc(2 * kSBHeatRadiusInPoints * 2 * kSBHeatRadiusInPoints * MemoryLayout<Float>.size)
      populateScaleMatrix()
    }
  }

  deinit {
    free(scaleMatrix)
  }

  func populateScaleMatrix() {
    for i in 0..<(2 * kSBHeatRadiusInPoints) {
      for j in 0..<(2 * kSBHeatRadiusInPoints) {
        let distance = sqrt((i - kSBHeatRadiusInPoints) * (i - kSBHeatRadiusInPoints) + (j - kSBHeatRadiusInPoints) * (j - kSBHeatRadiusInPoints))
        var scaleFactor = 1 - distance / Float(kSBHeatRadiusInPoints)
        if scaleFactor < 0 {
          scaleFactor = 0
        } else {
          scaleFactor = (expf(-distance / 10.0) - expf(Double(-kSBHeatRadiusInPoints) / 10.0)) / expf(0)
        }

        scaleMatrix?[j * 2 * kSBHeatRadiusInPoints + i] = scaleFactor
      }
    }
  }
}


func draw(
  _ mapRect: MKMapRect,
  zoomScale: MKZoomScale,
  in context: CGContext
) {
  let usRect = rect(for: mapRect) //rect in user space coordinates (NOTE: not in screen points)
  let visibleRect = overlay.boundingMapRect
  let mapIntersect = mapRect.intersection(visibleRect)
  let usIntersect = rect(for: mapIntersect) //rect in user space coordinates (NOTE: not in screen points)
  //
  //- (void)drawMapRect:(MKMapRect)mapRect
  //zoomScale:(MKZoomScale)zoomScale
  //inContext:(CGContextRef)context
  //{
  //  CGRect usRect = [self rectForMapRect:mapRect]; //rect in user space coordinates (NOTE: not in screen points)
  //  MKMapRect visibleRect = [self.overlay boundingMapRect];
  //  MKMapRect mapIntersect = MKMapRectIntersection(mapRect, visibleRect);
  //  CGRect usIntersect = [self rectForMapRect:mapIntersect]; //rect in user space coordinates (NOTE: not in screen points)
  let columns = ceil(usRect.width * zoomScale)
  let rows = ceil(usRect.height * zoomScale)
  let arrayLen = columns * rows

  // allocate an array matching the screen point size of the rect
  let pointValues = calloc(arrayLen, MemoryLayout<Float>.size)

  if let pointValues = pointValues {
    // pad out the mapRect with the radius on all sides.
    // we care about points that are not in (but close to) this rect
    let paddedRect = rect(for: mapRect)
    paddedRect.origin.x -= kSBHeatRadiusInPoints / zoomScale
    paddedRect.origin.y -= kSBHeatRadiusInPoints / zoomScale
    paddedRect.size.width += 2 * kSBHeatRadiusInPoints / zoomScale
    paddedRect.size.height += 2 * kSBHeatRadiusInPoints / zoomScale
    let paddedMapRect = mapRect(for: paddedRect)

    // Get the dictionary of values out of the model for this mapRect and zoomScale.
    let hm = overlay as? DTMHeatmap
    let heat = hm?.mapPointsWithHeat(
      in: paddedMapRect,
      atScale: zoomScale)

    for key in heat ?? [:] {
      guard let key = key as? NSValue else {
        continue
      }
      // convert key to mapPoint
      var mapPoint: MKMapPoint
      key.getValue(&mapPoint)
      let value = (heat?[key] as? NSNumber)?.doubleValue ?? 0.0

      // figure out the correspoinding array index
      let usPoint = point(for: mapPoint)

      let matrixCoord = CGPoint(
        x: (usPoint.x - usRect.origin.x) * zoomScale,
        y: (usPoint.y - usRect.origin.y) * zoomScale)
      if value != 0 && !value.isNaN {
        // don't bother with 0 or NaN
        // iterate through surrounding pixels and increase
        for i in 0..<(2 * kSBHeatRadiusInPoints) {
          for j in 0..<(2 * kSBHeatRadiusInPoints) {
            // find the array index
            let column = floor(matrixCoord.x - kSBHeatRadiusInPoints + i)
            let row = floor(matrixCoord.y - kSBHeatRadiusInPoints + j)

            // make sure this is a valid array index
            if row >= 0 && column >= 0 && row < rows && column < columns {
              let index = columns * row + column
              let addVal: Double = value * scaleMatrix[j * 2 * kSBHeatRadiusInPoints + i]
              pointValues[index] += addVal
            }
          }
        }
      }


      var red: CGFloat
      var green: CGFloat
      var blue: CGFloat
      var alpha: CGFloat
      var indexOrigin: UInt
      let rgba = UnsafePointer<UInt8>(UInt8(calloc(arrayLen * 4, MemoryLayout<UInt8>.size)))
      let colorProvider = hm.colorProvider()
      for i in 0..<arrayLen {
        if pointValues[i] != 0 {
          indexOrigin = UInt(4 * i)
          colorProvider?.color(
            forValue: pointValues[i],
            red: &red,
            green: &green,
            blue: &blue,
            alpha: &alpha)

          rgba[indexOrigin] = red
          rgba[indexOrigin + 1] = green
          rgba[indexOrigin + 2] = blue
          rgba[indexOrigin + 3] = alpha
        }
      }

      //            free(pointValues);

      let colorSpace = CGColorSpaceCreateDeviceRGB()
      let bitmapContext = CGContext(
        data: &rgba,
        width: columns,
        height: rows,
        bitsPerComponent: 8,
        bytesPerRow: 4 * columns,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | 0)


      let cgImage = bitmapContext?.makeImage()
      var img: UIImage? = nil
      if let cgImage = cgImage {
        img = UIImage(cgImage: cgImage)
      }
      UIGraphicsPushContext(context)
      img?.draw(in: usIntersect)
      UIGraphicsPopContext()
      free(rgba)
    }

  }

}
