//
//  LocationManager.swift
//  Heatmapper
//
//  Created by Richard English on 13/04/2021.
//  Copyright © 2021 Richard English. All rights reserved.
//
//  This class manages the CLLocationManager


import UIKit
import CoreLocation

public class LocationManager: NSObject, CLLocationManagerDelegate {

  public static var sharedInstance = LocationManager()
  let locationManager: CLLocationManager
  public var locationDataArray: [CLLocation]
  var useFilter: Bool


  override init() {
    locationManager = CLLocationManager()

    locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
    locationManager.distanceFilter = 1

    locationManager.requestWhenInUseAuthorization()
    locationManager.allowsBackgroundLocationUpdates = true
    locationManager.pausesLocationUpdatesAutomatically = false
    locationDataArray = [CLLocation]()

    useFilter = true

    super.init()

    locationManager.delegate = self

  }


  func startUpdatingLocation(){
    if CLLocationManager.locationServicesEnabled(){
      locationManager.startUpdatingLocation()
    } else {
      //tell view controllers to show an alert
      showTurnOnLocationServiceAlert()
    }
  }


  //MARK: CLLocationManagerDelegate protocol methods
  public func locationManager(_ manager: CLLocationManager,
                              didUpdateLocations locations: [CLLocation]){

    if let newLocation = locations.last{
      print("(\(newLocation.coordinate.latitude), \(newLocation.coordinate.latitude))")

      var locationAdded: Bool
      if useFilter {
        locationAdded = filterAndAddLocation(newLocation)
      } else {
        locationDataArray.append(newLocation)
        locationAdded = true
      }


      if locationAdded{
        notifiyDidUpdateLocation(newLocation: newLocation)
      }

    }
  }

  func filterAndAddLocation(_ location: CLLocation) -> Bool{
    let age = -location.timestamp.timeIntervalSinceNow

    if age > 10{
      print("Locaiton is old.")
      return false
    }

    if location.horizontalAccuracy < 0{
      print("Latitidue and longitude values are invalid.")
      return false
    }

    if location.horizontalAccuracy > 100{
      print("Accuracy is too low.")
      return false
    }

    print("Location quality is good enough.")
    locationDataArray.append(location)

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
