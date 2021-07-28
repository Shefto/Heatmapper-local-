//
//  JDHeatmapManager.swift
//  Heatmapper
//
//  Created by Richard English on 24/04/2021.
//  Copyright © 2021 Richard English. All rights reserved.
//

import Foundation
import MapKit

// this class manages the whole heatmap creation process
// it requires the heatmap view, datapoint type and colour mixer mode
class JDHeatMapManager: NSObject
{

  // Declare Variables

  // this creates an alias for the key-value pair below
  typealias pointCreator = [JDHeatmapOverlayRenderer : JDHeatmapPointCreator]

  // creates a variable of the key-value pair declared above
  var rendererPointCreatorPair  : pointCreator = [:]

  weak var jdHeatMapView    : JDHeatMapView!
  var calculationInProgress : Bool = false
  var dataPointType         : DataPointType = .RadiusPoint
  let mapWidthInUIView      : CGFloat

  var biggestMapRegion      : MKMapRect = MKMapRect(origin: MKMapPoint(), size: MKMapSize(width: 0, height: 0))
  var maxHeatLevelInMap     : Int = 0

  let missionThread         = DispatchQueue(label: "MissionThread")

  // initializer
  // as stated, this class needs the heatmap view, data point type and colour mixer
  init (JDSwiftHeatMapView: JDHeatMapView, datapointType: DataPointType, mode: ColorMixerMode)
  {
    jdHeatMapView     = JDSwiftHeatMapView
    dataPointType     = datapointType
    mapWidthInUIView  = JDSwiftHeatMapView.frame.width
    JDHeatmapPointCreator.theColorMixer.mixerMode = mode
  }

  // main function called when the heatmap needs to be updated to reflect the new data
  func refresh()
  {
    rendererPointCreatorPair = [:]

    // check to ensure the delegate is of the right object type
    guard let heatmapDelegate = jdHeatMapView.heatmapDelegate else {
      return
    }

    // remove the existing overlays - start from a clean slate
    jdHeatMapView.removeOverlays(jdHeatMapView.overlays)

    // get the total number of CLLocation points to be added to the heatmap
    let locationPoints = heatmapDelegate.heatmap(HeatPointCount: jdHeatMapView)

    // *** the main heatmap creation process ***
    // loop through each location point we have
    for locationPoint in 0..<locationPoints
    {
      let radius = heatmapDelegate.heatmap(RadiusInKMFor: locationPoint)
      let coordinate = heatmapDelegate.heatmap(CoordinateFor: locationPoint)
      let heatLevel = heatmapDelegate.heatmap(HeatLevelFor: locationPoint)
      MyFunc.logMessage(.debug, "heatLevel: \(heatLevel)")

      // if the heat level of this point is greater than the current max, increase the current max
      maxHeatLevelInMap = (heatLevel > maxHeatLevelInMap) ? heatLevel : maxHeatLevelInMap

      // create a new heatmap point from the location point and heat level calculated above
      let newHeatPoint = heatmapPoint2D(heatLevel: heatLevel, coordinate: coordinate, radiusInKM: radius)

      if (dataPointType == .FlatPoint)
      {
        // Flat point heatmaps  (i.e with a coloured background)  only require a single overlay because they include the rectangle
        // for some reason declaring this function then calling it immediately afterwards affects the functionality
        // need to understand why
        func collectToOneOverlay()
        {
          if(jdHeatMapView.overlays.count == 1)
          {
            if let flatOverlay = jdHeatMapView.overlays.first as? JDHeatmapOverlay
            {
              flatOverlay.insertHeatpoint(input: newHeatPoint)
            }
            return
          }
          // if an overlay has not been created yet, this creates one
          else if(jdHeatMapView.overlays.count == 0) //First Overlay
          {
            let bigOverlay = JDHeatmapOverlay(first: newHeatPoint)
            jdHeatMapView.addOverlay(bigOverlay, level: MKOverlayLevel.aboveLabels)
            return
          }
        }
        collectToOneOverlay()
      }

      else if(dataPointType == .RadiusPoint)
      {

        // RadiusPoint requires multiple overlays
        func closeToOverlay()
        {
          //  loop through the overlays in the heatmap
          for overlay in jdHeatMapView.overlays
          {
            let overlayMapRect = overlay.boundingMapRect
            // if the heat point is within the bounds of the current overlay...
            if(overlayMapRect.intersects(newHeatPoint.mapRect))
            {
              //...then use this overlay and insert the current heatpoint into it
              if let heatmapOverlay = overlay as? JDHeatmapOverlay
              {
                heatmapOverlay.insertHeatpoint(input: newHeatPoint)
                return
              }
            }
          }

          //Create New Overlay, OverlayRenderer will create together
          let heatmapOverlay = JDHeatmapOverlay(first: newHeatPoint)
          jdHeatMapView.addOverlay(heatmapOverlay, level: MKOverlayLevel.aboveLabels)
        }

        closeToOverlay()
      }
      
    } // func refresh

    if (maxHeatLevelInMap == 0) {
//      fatalError("Max Heat level should not be 0")
      MyFunc.logMessage(.error, "Max Heat level should not be 0")
    }

    // this function reduces the overlay size to fit just the points
    func reduceOverlaySize() {
      var overlayReductionComplete : Bool = false
      repeat
      {
        overlayReductionComplete = false
        // loop through every overlay we have
        for overlayX in jdHeatMapView.overlays
        {
          //  check the overlay is the correct object type
          guard let heatmapOverlayX = overlayX as? JDHeatmapOverlay
          else {
            MyFunc.logMessage(.error, "Invalid overlay type passed to JDHeatmap Manager")
            return
          }
          // inner loop through overlays
          for overlayY  in jdHeatMapView.overlays
          {
            // if the overlays match we cannot reduce any further
            if(overlayY.isEqual(overlayX)) {
              // so break out of the loop
              continue
            }

            let overlayXMapRect = overlayX.boundingMapRect
            let overlayYMapRect = overlayY.boundingMapRect
            if(overlayXMapRect.intersects(overlayYMapRect))
            {
              overlayReductionComplete = true
              if let heatmapOverlayY = overlayY as? JDHeatmapOverlay
              {
                for point in heatmapOverlayY.heatmapPoint2DArray
                {
                  heatmapOverlayX.insertHeatpoint(input: point)
                }
              }
              jdHeatMapView.removeOverlay(overlayY)
              break
            }
          }

          if(overlayReductionComplete) {break}
        }
      } while(overlayReductionComplete)
    }

    reduceOverlaySize()

    MyFunc.logMessage(.debug, "Number of overlays: \(jdHeatMapView.overlays.count)")

    // this loop calculates the biggest map region from the overlay's boundingMapRect
    // this is used later to set the zoom size for the map
    for overlay in jdHeatMapView.overlays
    {
      if let heatmapOverlay = overlay as? JDHeatmapOverlay
      {
        let heatmapOverlayRect = heatmapOverlay.boundingMapRect
        let heatmapOverlayArea = heatmapOverlayRect.size.height * heatmapOverlayRect.size.width
        let biggestMapArea = biggestMapRegion.size.height * biggestMapRegion.size.width
        // increase the size of the mapRect
        biggestMapRegion = (heatmapOverlayArea > biggestMapArea) ? heatmapOverlayRect : biggestMapRegion

      }

    }
    // now calculate the heatmap point objects for the overlay
    calculateHeatmapPointObjects()
  }

  // create CGPoint versions of each heatmapPoint object
  func calculateHeatmapPointObjects()
  {
    print(#function)
    lastVisibleMapRect = jdHeatMapView.visibleMapRect

    // this calls the compute function below and the startCalculating - these are not called anywhere else in the app
    // retaining this structure however as it makes it clear what is asynchronous and saves on adding self references
    missionThread.async(execute: {
      callRenderers()
      self.startCalculating()
    })

    func callRenderers()
    {
      // this function calls the overlay renderer
      // if the heatmap has no background (.RadiusPoint) then multiple overlays required rendering
      if (dataPointType == .RadiusPoint)
      {
        // this loops through all the overlays which require rendering
        for overlay in jdHeatMapView.overlays
        {
          // checks the overlays conform to our custom subclass of MKOverlay
          if let heatmapOverlay = overlay as? JDHeatmapOverlay
          {
            // and renders them if they do
            renderOverlay(heatmapOverlay: heatmapOverlay)
          }
        }
      }
      else if (dataPointType == .FlatPoint)
      {
        // .FlatPoint (i.e. with a background) heatmaps only require one overlay to be rendered
        // this if statement checks that the mapView only has a single overlay
        if(jdHeatMapView.overlays.count == 1)
        {
          if let heatmapOverlay = jdHeatMapView.overlays[0] as? JDHeatmapOverlay
          {
            renderOverlay(heatmapOverlay: heatmapOverlay)
          }
        }
      }
    }

    // this function actually renders the map overlay
    func renderOverlay(heatmapOverlay: JDHeatmapOverlay)
    {
      // first check the overlay passed in is of the correct type
      if let rendererForHeatmapOverlay = rendererFor(overlay: heatmapOverlay)
      {
        // now calculate the CG Points and Rectangle based upon the points and the maximum heat level (calculated elsewhere in this class)
        if let calculatedHeatmapData = rendererForHeatmapOverlay.calcHeatmapPointsAndRect(maxHeat: maxHeatLevelInMap)
        {

          var heatmapPointCreator : JDHeatmapPointCreator!
          let overlayCGRect = calculatedHeatmapData.heatmapCGect
          let heatmapPointCGArray = calculatedHeatmapData.heatmapPointCGArray

          // depending upon the type of Heatmap passed in (i.e. flat or radius) call the relevant creator function
          if (dataPointType == .RadiusPoint)
          {
            heatmapPointCreator  = HeatmapRadiusPointCreator(size: (overlayCGRect.size), heatmapPointArray: heatmapPointCGArray)
          }
          else if (dataPointType == .FlatPoint)
          {
            heatmapPointCreator = HeatmapFlatPointCreator(size: (overlayCGRect.size), heatmapPointArray: heatmapPointCGArray)
          }

          rendererPointCreatorPair[rendererForHeatmapOverlay] = heatmapPointCreator

          // set the visible area to the biggest map region
          let visibleMapRect = biggestMapRegion

          // set the map rectangle scale to the map view's display size divided by the visible rectangle
          let scaleUIView_MapRect : Double = Double(mapWidthInUIView) / visibleMapRect.size.width

          // now reduce the size of the map based upon this scale
          heatmapPointCreator?.reduceSize(scales: scaleUIView_MapRect)

          return
        }
      }

    }


  }

  /**
   3.0 Most Take time task
   **/
  func startCalculating()
  {
    print(#function)
    self.calculationInProgress = true

    func generateHeatmap()
    {
      for overlay in jdHeatMapView.overlays
      {
        if let heatmapOverlay = overlay as? JDHeatmapOverlay
        {
          if let rendererForHeatmapOverlay = rendererFor(overlay: heatmapOverlay)
          {
            if let heatmapRenderer = rendererPointCreatorPair[rendererForHeatmapOverlay]
            {
              // from the point pair, create the heatmap point
              heatmapRenderer.createHeatmapPoint()
              // set the bitmap size and bytes
              rendererForHeatmapOverlay.bitmapSize = heatmapRenderer.fitnessIntSize
              rendererForHeatmapOverlay.bytesPerRow = heatmapRenderer.BytesPerRow
              // append the colour used to the renderer's set of colour references
              rendererForHeatmapOverlay.dataReference.append(contentsOf: heatmapRenderer.heatmapPointColourArray)
              rendererForHeatmapOverlay.setNeedsDisplay()
              heatmapRenderer.heatmapPointColourArray = []
            }
          }
        }
      }

      self.calculationInProgress = false

      DispatchQueue.main.sync {
        if(jdHeatMapView.showIndicator)
        {
          jdHeatMapView.inProgressWheel?.stopAnimating()
        }
        // set the zoom to fit the heatmap
        let zoomOrigin = MKMapPoint(x: biggestMapRegion.origin.x - biggestMapRegion.size.width * 2, y: biggestMapRegion.origin.y - biggestMapRegion.size.height * 2)
        let zoomedoutRect = MKMapRect(origin: zoomOrigin, size: MKMapSize(width: biggestMapRegion.size.width * 4, height: biggestMapRegion.size.height * 4))
        jdHeatMapView.setVisibleMapRect(zoomedoutRect, animated: true)

        // may be able to convert the overlay here

      }
    }
    generateHeatmap()
  }

  var lastVisibleMapRect: MKMapRect = MKMapRect.init()
}

extension JDHeatMapManager
{
  // this functiona called at the start of the map view rendering process
  func mapViewWillStartRenderingMap()
  {
    // check if a rendering is in progress
    if (calculationInProgress)
    {
      // if one is, return so that can finish
      return
    }

    // set the visible map area up
    let visibleHeatmapRect = jdHeatMapView.visibleMapRect

    // if the visible area is the same as the biggest map region then we're done
    if (visibleHeatmapRect.size.width == biggestMapRegion.size.width &&
          visibleHeatmapRect.origin.x == biggestMapRegion.origin.x &&
          visibleHeatmapRect.origin.y == biggestMapRegion.origin.y) {
      return
    }

    // set a variable up to check how big the zoom change is from the last visible area calculated
    let rerenderReqdCheck = lastVisibleMapRect.size.width / visibleHeatmapRect.size.width

    // if the zoome change is within an acceptable scale then we're done
    if (rerenderReqdCheck > 0.7 && rerenderReqdCheck < 1.66 )
    {
      return
    }

    print(#function)

    // note that we are about to start calculating
    self.calculationInProgress = true
    lastVisibleMapRect = visibleHeatmapRect

    // display the progress wheel to let the user know we're doing stuff
    if(jdHeatMapView.showIndicator)
    {
      jdHeatMapView.inProgressWheel?.startAnimating()
    }

    // this function calculates the map size
    func computing()
    {
      // loop through all the overlays in the MapView
      for overlay in jdHeatMapView.overlays
      {
        // if the overlay is a JDHeatmapOverlay
        if let heatmapOverlay = overlay as? JDHeatmapOverlay
        {
          // then recalculate the renderer to use
          // again JD has declared a function immediately before calling it - why?
          func recalculateOverlayRenderer()
          {
            // if the renderer for the heatmap is actually a heatmap overlay renderer
            // (i.e. the overlay is using the correct type of renderer)
            if let rendererForHeatmapOverlay = rendererFor(overlay: heatmapOverlay)
            {

              let scaleUIView_MapRect:  Double = Double(mapWidthInUIView) / visibleHeatmapRect.size.width
              if let heatmapRenderer = rendererPointCreatorPair[rendererForHeatmapOverlay]
              {


                let newWidth = Int(heatmapRenderer.originalCGSize.width * CGFloat(scaleUIView_MapRect) * 1.5)
                if let lastimage = rendererForHeatmapOverlay.lastImage
                {
                  if(lastimage.width > newWidth) { return }
                  else { rendererForHeatmapOverlay.lastImage = nil } //Make it can draw
                }
                /*
                 Recalculate new Size new Data to draw a new cgimage
                 (Probably user zoom in)
                 */
                heatmapRenderer.reduceSize(scales: scaleUIView_MapRect) //Recaculate new FitnessSize
                heatmapRenderer.createHeatmapPoint()
                rendererForHeatmapOverlay.bitmapSize = heatmapRenderer.fitnessIntSize
                rendererForHeatmapOverlay.bytesPerRow = heatmapRenderer.BytesPerRow
                rendererForHeatmapOverlay.dataReference.append(contentsOf: heatmapRenderer.heatmapPointColourArray)
                rendererForHeatmapOverlay.setNeedsDisplay()
                heatmapRenderer.originalHeatmapPointArray = []
              }
            }
          }
          recalculateOverlayRenderer()
        }
      }
    }


    missionThread.async(execute: {
      computing()
      DispatchQueue.main.sync(execute: {
        if(self.jdHeatMapView.showIndicator)
        {
          self.jdHeatMapView.inProgressWheel?.stopAnimating()
        }
        self.calculationInProgress = false
      })
    })
  }

  // this function simply returns the Renderer corresponding to the Overlay passed in
  // different Overlays have different Renderers depending upon their class and other attributes
  func rendererFor(overlay: JDHeatmapOverlay) -> JDHeatmapOverlayRenderer?
  {
    let renderer = self.jdHeatMapView.renderer(for: overlay)
    let heatmapRenderer = renderer as? JDHeatmapOverlayRenderer
    return heatmapRenderer
  }

}

