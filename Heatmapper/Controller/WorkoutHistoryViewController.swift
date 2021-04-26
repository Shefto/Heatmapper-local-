//
//  WorkoutHistoryViewController.swift
//  Heatmapper
//
//  Created by Richard English on 24/04/2021.
//  Copyright © 2021 Richard English. All rights reserved.
//

import UIKit
import HealthKit

class WorkoutHistoryViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

  private var workouts: [HKWorkout]?
  private let workoutCellId = "workoutCell"
  lazy var dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.timeStyle = .short
    formatter.dateStyle = .medium
    return formatter
  }()


  @IBOutlet weak var workoutTableView: UITableView!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    workoutTableView.dataSource = self
    workoutTableView.delegate = self
    loadWorkouts { (workouts, error) in
      self.workouts = workouts
      self.workoutTableView.reloadData()
    }
    MyFunc.logMessage(.debug, "Workouts:")
    MyFunc.logMessage(.debug, String(describing: workouts))

  }
  var workoutArray = [HKWorkout]()

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return workouts?.count ?? 0
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard let workouts = workouts else {
      fatalError("""
               CellForRowAtIndexPath should \
               not get called if there are no workouts
               """)
    }

    //1. Get a cell to display the workout in
    let cell = tableView.dequeueReusableCell(withIdentifier:
                                              workoutCellId, for: indexPath)

    //2. Get the workout corresponding to this row
    let workout = workouts[indexPath.row]

    //3. Show the workout's start date in the label
    cell.textLabel?.text = dateFormatter.string(from: workout.startDate)

    //4. Show the Calorie burn in the lower label
    if let caloriesBurned =
        workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) {
      let formattedCalories = String(format: "CaloriesBurned: %.2f",
                                     caloriesBurned)

      cell.detailTextLabel?.text = formattedCalories
    } else {
      cell.detailTextLabel?.text = nil
    }

    return cell
  }


  func loadWorkouts(completion:
                      @escaping ([HKWorkout]?, Error?) -> Void) {
    //1. Get all workouts with the "Other" activity type.
//    let workoutPredicate = HKQuery.predicateForWorkouts(with: .running)

    //2. Get all workouts that only came from this app.
    let sourcePredicate = HKQuery.predicateForObjects(from: .default())

    //3. Combine the predicates into a single predicate.
//    let compound = NSCompoundPredicate(andPredicateWithSubpredicates:
//                                        [workoutPredicate, sourcePredicate])

    let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate,
                                          ascending: false)

    let query = HKSampleQuery(
      sampleType: .workoutType(),
      predicate: sourcePredicate,
      limit: 0,
      sortDescriptors: [sortDescriptor]) { (query, samples, error) in
      DispatchQueue.main.async {
        //4. Cast the samples as HKWorkout
        guard
          let samples = samples as? [HKWorkout],
          error == nil
        else {
          completion(nil, error)
          return
        }

        completion(samples, nil)
      }
    }

    HKHealthStore().execute(query)

  }


}


