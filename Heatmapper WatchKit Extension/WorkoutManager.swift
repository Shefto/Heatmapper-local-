//
//  WorkoutManager.swift
//  Heatmapper WatchKit Extension
//
//  Created by Richard English on 06/01/2021.
//  Copyright © 2021 Richard English. All rights reserved.
//

import WatchKit
import HealthKit
import Combine

class WorkoutManager: NSObject, ObservableObject, HKLiveWorkoutBuilderDelegate {

  let healthStore   = HKHealthStore()
  var session       : HKWorkoutSession!
  var builder       : HKLiveWorkoutBuilder!
  var routeBuilder  : HKWorkoutRouteBuilder!
  var delegate      : WorkoutManagerDelegate!
  

  // Request authorization to access HealthKit.
  func requestAuthorization() {

    let typesToShare: Set = [
      HKQuantityType.workoutType()
    ]

    let typesToRead: Set = [
      HKQuantityType.quantityType(forIdentifier: .heartRate)!,
      HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
      HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!,
      HKQuantityType.workoutType()
    ]

    healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { (success, error) in
      // Handle error.
    }
  }

  // Provide the workout configuration.
  func workoutConfiguration() -> HKWorkoutConfiguration {
    /// - Tag: WorkoutConfiguration
    let configuration = HKWorkoutConfiguration()
    configuration.activityType = .running
    configuration.locationType = .outdoor


    return configuration
  }

  // Start the workout.
  func startWorkout() {

    do {
      // create the workout session with the configuration specified above
      session = try HKWorkoutSession(healthStore: healthStore, configuration: workoutConfiguration())
      // create the WorkoutBuilder for the session
      builder = session.associatedWorkoutBuilder()
      routeBuilder = HKWorkoutRouteBuilder(healthStore: healthStore, device: nil)

    } catch {
      MyFunc.logMessage(.error, "Error creating Workout Session and Builder")
      return
    }

    // assign the interface controller as delegate for the session and WorkoutBuilder
    session.delegate = self
    builder.delegate = self

    // set the builder's data source as the live workout
    builder.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: workoutConfiguration())

    // Start the workout session and begin data collection.
    session.startActivity(with: Date())
    builder.beginCollection(withStart: Date()) { (success, error) in
      // The workout has started.
    }
    let metadata = ["Sport" : "Football - 5-a-side", "Event" : "Dad's Football", "Venue" : "Goals Wimbledon", "Pitch" : "9 - Estadio de Luz"]
    builder.addMetadata(metadata) { (success, error) in
      print(success ? "Success saving metadata" : error as Any)
    }
  }


  func pauseWorkout() {
    session.pause()
  }

  func resumeWorkout() {
    session.resume()
  }

  func endWorkout() {
    session.end()
  }


  // MARK: - Update the UI
  // Update the published values.
  func updateForStatistics(_ statistics: HKStatistics?) {
    guard let statistics = statistics else { return }

    DispatchQueue.main.async {
      switch statistics.quantityType {
      case HKQuantityType.quantityType(forIdentifier: .heartRate):
        /// - Tag: SetLabel
        //        let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
        //        let value = statistics.mostRecentQuantity()?.doubleValue(for: heartRateUnit)
        //        let roundedValue = Double( round( 1 * value! ) / 1 )
        let label = self.delegate?.labelForQuantityType(statistics.quantityType)
        self.delegate?.updateLabel(label, withStatistics: statistics)

        return


      case HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned):
        //        let energyUnit = HKUnit.kilocalorie()
        //        let value = statistics.sumQuantity()?.doubleValue(for: energyUnit)
        let label = self.delegate?.labelForQuantityType(statistics.quantityType)
        self.delegate?.updateLabel(label, withStatistics: statistics)

        return
      case HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning):
        //        let meterUnit = HKUnit.meter()
        //        let value = statistics.sumQuantity()?.doubleValue(for: meterUnit)
        //        let roundedValue = Double( round( 1 * value! ) / 1 )
        let label = self.delegate?.labelForQuantityType(statistics.quantityType)
        self.delegate?.updateLabel(label, withStatistics: statistics)

        return
      default:
        return
      }
    }
  }
}

// MARK: - HKWorkoutSessionDelegate
extension WorkoutManager: HKWorkoutSessionDelegate {
  func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState,
                      from fromState: HKWorkoutSessionState, date: Date) {
    // Wait for the session to transition states before ending the builder.
    /// - Tag: SaveWorkout
    if toState == .ended {
      MyFunc.logMessage(.debug, "The workout has now ended.")
      builder.endCollection(withEnd: Date()) { (success, error) in
        self.builder.finishWorkout { (workout, error) in

        }
      }
    }
  }

  func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {

  }


  //// MARK: - HKLiveWorkoutBuilderDelegate
  //extension WorkoutManager: HKLiveWorkoutBuilderDelegate {
  func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
    MyFunc.logMessage(.debug, "WorkoutManager.workoutBuilderDidCollectEvent called")
  }

  func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
    for type in collectedTypes {
      guard let quantityType = type as? HKQuantityType else {
        return // Nothing to do.
      }
      // - Tag: GetStatistics
      let statistics = workoutBuilder.statistics(for: quantityType)
      MyFunc.logMessage(.debug, "WorkoutManager.workoutBuilder.didCollectDataOf called")
      // Update the published values.
      updateForStatistics(statistics)
    }
  }

  func addWorkoutEvents(eventArray: [HKWorkoutEvent]) {


    builder.addWorkoutEvents(eventArray, completion: { (success, error) in
      
      guard success == true else {
        MyFunc.logMessage(.error, "Error appending workout event to array: \(String(describing: error))")
        return
      }
      MyFunc.logMessage(.info, "Events added to Workout:")
      let eventsStr = String(describing: eventArray)
      MyFunc.logMessage(.info, eventsStr)

    })

  }

  func endDataCollection(date: Date) {

    // end Workout Builder data collection
    builder.endCollection(withEnd: date, completion: { (success, error) in
      guard success else {
        MyFunc.logMessage(.error, "workoutManager.endDataCollection: builder.endCollection error: \(String(describing: error))")
        return
      }

      // save the Workout
      self.builder.finishWorkout { [self] (savedWorkout, error) in

        guard savedWorkout != nil else {
          MyFunc.logMessage(.error, "Failed to save Workout with error : \(String(describing: error))")
          return
        }

        let workoutStr = String(describing: savedWorkout)
        MyFunc.logMessage(.debug, "Workout saved successfully:")
        MyFunc.logMessage(.debug, workoutStr)

        // insert the route data from the Location array
        let locationArray : [CLLocation] = LocationManager.sharedInstance.locationDataArray
        MyFunc.logMessage(.debug, "locationArray")
        MyFunc.logMessage(.debug, String(describing: locationArray))

        routeBuilder.insertRouteData(locationArray) { (success, error) in
          if !success {
            MyFunc.logMessage(.error, "Error inserting Route data: \(String(describing: error))")
          }
          MyFunc.logMessage(.debug, "Success inserting Route data: \(String(describing: success))")


          // save the Workout Route
          self.routeBuilder.finishRoute(with: savedWorkout!, metadata: ["Activity Type": "Heatmapper"]) {(workoutRoute, error) in
            guard workoutRoute != nil else {
              MyFunc.logMessage(.error, "Failed to save Workout Route with error : \(String(describing: error))")
              return
            }
            let routeStr = String(describing: workoutRoute)
            MyFunc.logMessage(.debug, "Workout Route saved successfully:")
            MyFunc.logMessage(.debug, routeStr)

            let savedEventsStr = String(describing: savedWorkout?.workoutEvents)
            MyFunc.logMessage(.debug, "Saved Events: \(savedEventsStr)")

            // add each Sample Array to the Workout
            self.addSamplesToWorkout(sampleArray: HeatmapperWorkout.sampleArray)


          } // self.routeBuilder.insertRouteDate

        } // self.routeBuilder.finishRoute

        session.end()

      } // self.builder.finishWorkout

    }) // self.builder.endCollection

  }

  func addSamplesToWorkout(sampleArray: [HKSample]) {

    MyFunc.logMessage(.default, "Adding samples: \(sampleArray.description)")
    self.builder.add(sampleArray, completion: { (success, error) in
      guard success
      else {
        MyFunc.logMessage(.error, "Error adding Samples to workout: \(error as Any)")
        return }
      MyFunc.logMessage(.info, "Samples added to workout successfully")
    })

  }

  func getHeartRateSample(startDate: Date, endDate: Date, quantityType: HKQuantityType, option: HKStatisticsOptions) -> HKSample {
    MyFunc.logMessage(.debug, "getHeartRateSample: \(String(describing: startDate)) to \(String(describing: endDate))")

    let quantityPredicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)
    var quantityResult: Double = 0.0

    let squery = HKStatisticsQuery(quantityType: quantityType, quantitySamplePredicate: quantityPredicate, options: .discreteAverage, completionHandler: {(_: HKStatisticsQuery, result: HKStatistics?, _: Error?) -> Void in
      DispatchQueue.main.async(execute: {() -> Void in
        let quantity: HKQuantity? = result?.averageQuantity()
        quantityResult = quantity?.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute())) ?? 0.0
        MyFunc.logMessage(.debug, "squery returned: \(String(format: "%.f", quantityResult))")
      })
    })
    healthStore.execute(squery)

    let quantity = HKQuantity(unit: HKUnit.count().unitDivided(by: HKUnit.minute()), doubleValue: quantityResult)
    let quantitySample = HKQuantitySample(type: quantityType, quantity: quantity, start: startDate, end: endDate, metadata: ["": ""])

    return quantitySample
  }

  // this function returns a HealthKit Sample for a given period and quantity type
  func getSampleForType(startDate: Date, endDate: Date, quantityType: HKQuantityType, option: HKStatisticsOptions) -> HKSample {

    MyFunc.logMessage(.debug, "getSampleForType quantityType: \(String(describing: quantityType.debugDescription))")
    let queryStartDate = startDate
    let queryEndDate = endDate
    var quantityValue: Double = 0.0

    let quantityPredicate = HKQuery.predicateForSamples(withStart: queryStartDate, end: queryEndDate)

    let quantityStatsQuery = HKStatisticsQuery(quantityType: quantityType, quantitySamplePredicate: quantityPredicate, options: option) { (_, statisticsOrNil, _) in

      guard let statistics = statisticsOrNil else {
        MyFunc.logMessage(.debug, "No data returned from sample query")
        return
      }
      let sum = statistics.sumQuantity()

      quantityValue = (sum?.doubleValue(for: HKUnit.largeCalorie()))!

    }
    healthStore.execute(quantityStatsQuery)
    MyFunc.logMessage(.debug, "StatsQuery for Quantity returned: \(quantityStatsQuery)")

    let quantity = HKQuantity(unit: HKUnit.kilocalorie(), doubleValue: quantityValue)
    let quantitySample = HKQuantitySample(type: quantityType, quantity: quantity, start: queryStartDate, end: queryEndDate, metadata: ["": ""])

    return quantitySample
  }


}
