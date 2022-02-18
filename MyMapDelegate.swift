//
//  MyMapDelegate.swift
//  Heatmapper
//
//  Created by Richard English on 18/02/2022.
//  Copyright © 2022 Richard English. All rights reserved.
//  Based upon https://medium.com/@dmytrobabych/getting-actual-rotation-and-zoom-level-for-mapkit-mkmapview-e7f03f430aa9
//

import Foundation
import MapKit

@objc public protocol MyMapListener {


  @objc optional func mapView(_ mapView: MyMKMapView, rotationDidChange rotation: Double)
  // message is sent when map rotation is changed

}
