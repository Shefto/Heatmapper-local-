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

  let theme = ColourTheme()

  private var workoutArray: [HKWorkout]?
  private let workoutCellId = "workoutCell"
  var workoutId : UUID?

  let healthstore = HKHealthStore()
  lazy var dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.timeStyle = .short
    formatter.dateStyle = .medium
    return formatter
  } ()


  @IBOutlet weak var workoutTableView: ThemeTableViewNoBackground!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    workoutTableView.dataSource = self
    workoutTableView.delegate = self

    workoutTableView.register(UINib(nibName: "WorkoutCell", bundle: nil), forCellReuseIdentifier: "WorkoutTableViewCell")
    workoutTableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: workoutTableView.frame.size.width, height: 1))
    workoutTableView.tableHeaderView?.backgroundColor = UIColor.clear


    loadWorkouts { (workouts, error) in
      self.workoutArray = workouts
      MyFunc.logMessage(.debug, "workouts:")
      MyFunc.logMessage(.debug, String(describing: self.workoutArray))
      self.workoutTableView.reloadData()
    }
//    MyFunc.logMessage(.debug, "Workouts:")
//    MyFunc.logMessage(.debug, String(describing: workoutArray))

  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return workoutArray?.count ?? 0
  }


  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: false)
    workoutId = workoutArray?[indexPath.row].uuid
    MyFunc.logMessage(.debug, "workoutId: \(String(describing: workoutId))")

    self.performSegue(withIdentifier: "historyToHeatmap", sender: workoutId)
  }


  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard let workouts = workoutArray else {
      fatalError("""
               CellForRowAtIndexPath should \
               not get called if there are no workouts
               """)
    }

    // use custom WorkoutCell xib
    let cell = tableView.dequeueReusableCell(withIdentifier:
                                              "WorkoutTableViewCell", for: indexPath) as! WorkoutTableViewCell

    // get workout for the row
    let workout = workouts[indexPath.row]
    MyFunc.logMessage(.debug, "workout for row \(String(describing: indexPath.row))")
    MyFunc.logMessage(.debug, String(describing: workout))


    // load activity date
    cell.activityDate.text = dateFormatter.string(from: workout.startDate)

    cell.activityType.text = workout.workoutActivityType.name

    // load workout metric fields
    // load energy used
    if let caloriesBurned =
        workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) {
      let formattedCalories = String(format: "%.2f kcal",
                                     caloriesBurned)

      cell.caloriesLabel.text = formattedCalories
    } else {
      cell.caloriesLabel.text = nil
    }

    // load average BPM

    // load distance
    if let workoutDistance = workout.totalDistance?.doubleValue(for: .meter()) {
      let formattedDistance = String(format: "%.2f m", workoutDistance)
      cell.distanceLabel.text = formattedDistance
    } else {
      cell.distanceLabel.text = nil
    }

    // load average speed


    return cell
  }


  func loadWorkouts(completion:
                      @escaping ([HKWorkout]?, Error?) -> Void) {

    let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate,
                                          ascending: false)

    let query = HKSampleQuery(
      sampleType: .workoutType(),
      predicate: nil,
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

    healthstore.execute(query)

  }


  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

    let segueToUse = segue.identifier

    if segueToUse == "historyToHeatmap" {
      let destinationVC = segue.destination as! HeatmapViewController
      destinationVC.heatmapWorkoutId = (sender as! UUID)
    }

    navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
  }



}


