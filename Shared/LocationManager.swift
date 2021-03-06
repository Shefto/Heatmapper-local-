//
//  LocationManager.swift
//  Heatmapper
//
//  Created by Richard English on 13/04/2021.
//  Copyright © 2021 Richard English. All rights reserved.
//
//  This class manages the CLLocationManager


import Foundation
import CoreLocation

public class LocationManager: NSObject, CLLocationManagerDelegate {

  public static var sharedInstance = LocationManager()
  let locationManager: CLLocationManager
  public var locationDataArray: [CLLocation]
  public var locationDataAsCoordinates: [CLLocationCoordinate2D]
  public var currentLocation: CLLocation

  override init() {
    locationManager = CLLocationManager()

    locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
    locationManager.distanceFilter = 1

    locationManager.requestWhenInUseAuthorization()
    locationManager.allowsBackgroundLocationUpdates = true
//    locationManager.pausesLocationUpdatesAutomatically = false
    locationDataArray = [CLLocation]()
    locationDataAsCoordinates = [CLLocationCoordinate2D]()
    currentLocation = CLLocation()


    super.init()

    locationManager.delegate = self

  }


  func startUpdatingLocation(){
    if CLLocationManager.locationServicesEnabled(){
      locationManager.startUpdatingLocation()
      MyFunc.logMessage(.debug, "startUpdatingLocation called")
    } else {
      //tell view controllers to show an alert
      showTurnOnLocationServiceAlert()
    }
  }


  func stopUpdatingLocation(){
    if CLLocationManager.locationServicesEnabled(){
      locationManager.stopUpdatingLocation()
      MyFunc.logMessage(.debug, "stopUpdatingLocation called")
    }
//    MyFunc.logMessage(.debug, "locations captured:")
//    MyFunc.logMessage(.debug, String(describing: locationDataArray))
//    locationDataAsCoordinates = locationDataArray.map {$0.coordinate}
//    MyFunc.logMessage(.debug, String(describing: locationDataAsCoordinates))
  }

  //MARK: CLLocationManagerDelegate protocol methods
  public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]){

    if let newLocation = locations.last{
//      print("(\(newLocation.coordinate.latitude), \(newLocation.coordinate.longitude))")
      currentLocation = newLocation
      var locationAdded: Bool

      locationAdded = filterAndAddLocation(newLocation)

      if locationAdded{
        notifiyDidUpdateLocation(newLocation: newLocation)
      }

    }
  }

  func filterAndAddLocation(_ location: CLLocation) -> Bool{
    let age = -location.timestamp.timeIntervalSinceNow

    if age > 10{
//      print("Location is old.")
      return false
    }

    if location.horizontalAccuracy < 0{
//      print("Latitidue and longitude values are invalid.")
      return false
    }

    if location.horizontalAccuracy > 100{
//      print("Accuracy is too low.")
      return false
    }

//    print("Location quality is good enough.")
    locationDataArray.append(location)
//    locationDataAsCoordinates.append(location.coordinate)

    return true
  }

  public func locationManager(_ manager: CLLocationManager,
                              didFailWithError error: Error){
    if (error as NSError).domain == kCLErrorDomain && (error as NSError).code == CLError.Code.denied.rawValue{
      //User denied your app access to location information.
      showTurnOnLocationServiceAlert()
    }
  }

  public func locationManager(_ manager: CLLocationManager,
                              didChangeAuthorization status: CLAuthorizationStatus){
    if status == .authorizedWhenInUse{
      //You can resume logging by calling startUpdatingLocation here
    }
  }

  func showTurnOnLocationServiceAlert(){
    NotificationCenter.default.post(name: Notification.Name(rawValue:"showTurnOnLocationServiceAlert"), object: nil)
  }

  func notifiyDidUpdateLocation(newLocation:CLLocation){
    NotificationCenter.default.post(name: Notification.Name(rawValue:"didUpdateLocation"), object: nil, userInfo: ["location" : newLocation])
  }
}
