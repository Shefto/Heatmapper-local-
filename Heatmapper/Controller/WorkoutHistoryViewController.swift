////
////  WorkoutHistoryViewController.swift
////  Heatmapper
////
////  Created by Richard English on 24/04/2021.
////  Copyright © 2021 Richard English. All rights reserved.
////
//
//import UIKit
//import HealthKit
//import CoreLocation
//
//class WorkoutHistoryViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
//
//  let theme = ColourTheme()
//
//  private var workoutArray: [HKWorkout]?
//  private let workoutCellId = "workoutCell"
//  var workoutId : UUID?
//  var selectedIndexPath : Int? = 0
//
//  let locationManager          = CLLocationManager()
//  let healthstore = HKHealthStore()
//  lazy var dateFormatter: DateFormatter = {
//    let formatter = DateFormatter()
//    formatter.timeStyle = .short
//    formatter.dateStyle = .medium
//    return formatter
//  } ()
//
//
//  @IBOutlet weak var workoutTableView: ThemeTableViewNoBackground!
//  @IBOutlet weak var reButton: UIButton!
//  @IBOutlet weak var jdButton: UIButton!
//  @IBOutlet weak var dtmButton: UIButton!
//
//  @IBAction func btnDTMHeatmap(_ sender: Any) {
//    self.performSegue(withIdentifier: "historyToDTMHeatmap", sender: workoutId)
//  }
//
//  @IBAction func btnJDHeatmap(_ sender: Any) {
//    self.performSegue(withIdentifier: "historyToJDHeatmap", sender: workoutId)
//  }
//
//  @IBAction func btnREHeatmap(_ sender: Any) {
//    self.performSegue(withIdentifier: "historyToREHeatmap", sender: workoutId)
//  }
//
//  override func viewDidLoad() {
//    super.viewDidLoad()
//    // added this to ensure Location tracking turned off (it should be by the time this screen is displayed though)
//    locationManager.stopUpdatingLocation()
//    workoutTableView.dataSource = self
//    workoutTableView.delegate = self
//    workoutTableView.allowsSelection = true
//
//    workoutTableView.register(UINib(nibName: "WorkoutCell", bundle: nil), forCellReuseIdentifier: "WorkoutTableViewCell")
//    workoutTableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: workoutTableView.frame.size.width, height: 1))
//    workoutTableView.tableHeaderView?.backgroundColor = UIColor.clear
//
//
//    loadWorkouts { (workouts, error) in
//      self.workoutArray = workouts
//      MyFunc.logMessage(.debug, "workouts:")
//      MyFunc.logMessage(.debug, String(describing: self.workoutArray))
//      self.workoutTableView.reloadData()
//    }
//
//
//  }
//
//  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//    return workoutArray?.count ?? 0
//  }
//
//
//  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//    tableView.deselectRow(at: indexPath, animated: false)
//    workoutId = workoutArray?[indexPath.row].uuid
//    MyFunc.logMessage(.debug, "workoutId: \(String(describing: workoutId))")
//    selectedIndexPath = indexPath.row
//    self.workoutTableView.reloadData()
//
////    self.performSegue(withIdentifier: "historyToREHeatmap", sender: workoutId)
//  }
//
//  func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
//
//    selectedIndexPath = nil
//    self.workoutTableView.reloadData()
//    //    self.performSegue(withIdentifier: "historyToREHeatmap", sender: workoutId)
//  }
//
//
//
//  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//    guard let workouts = workoutArray else {
//      fatalError("""
//               CellForRowAtIndexPath should \
//               not get called if there are no workouts
//               """)
//    }
//
//    // use custom WorkoutCell xib
//    let cell = tableView.dequeueReusableCell(withIdentifier:
//                                              "WorkoutTableViewCell", for: indexPath) as! WorkoutTableViewCell
//
////    // get workout for the row
//    let workout = workouts[indexPath.row]
////    MyFunc.logMessage(.debug, "workout for row \(String(describing: indexPath.row))")
////    MyFunc.logMessage(.debug, String(describing: workout))
//
//
//    // load activity date
//    cell.activityDate.text = dateFormatter.string(from: workout.startDate)
//    cell.activityType.text = workout.workoutActivityType.name
//
//    // load energy used
//    if let caloriesBurned = workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) {
//      let formattedCalories = String(format: "%.2f kcal",
//                                     caloriesBurned)
//
//      cell.caloriesLabel.text = formattedCalories
//    } else {
//      cell.caloriesLabel.text = nil
//    }
//
//    // load average BPM
////    let heartRateSet = getHeartRateSampleForWorkout(workout: workout)
////    MyFunc.logMessage(.debug, "heartRateSet: ")
////    MyFunc.logMessage(.debug, String(describing: heartRateSet))
////
////    totalDistance?.doubleValue(for: .meter()) {
////      let formattedDistance = String(format: "%.2f m", averageBPM)
////      cell.distanceLabel.text = formattedDistance
////    } else {
////      cell.distanceLabel.text = nil
////    }
//    // load distance
//    if let workoutDistance = workout.totalDistance?.doubleValue(for: .meter()) {
//      let formattedDistance = String(format: "%.2f m", workoutDistance)
//      cell.distanceLabel.text = formattedDistance
//    } else {
//      cell.distanceLabel.text = nil
//    }
//
//    // load average speed
//
//    // configure cellUI
//    cell.heartImageView.image = cell.heartImageView.image?.withRenderingMode(.alwaysTemplate)
//    cell.heartImageView.tintColor = UIColor.systemRed
//
//    cell.caloriesImageView.image = cell.caloriesImageView.image?.withRenderingMode(.alwaysTemplate)
//    cell.caloriesImageView.tintColor = UIColor.systemOrange
//
//    cell.speedometerImageView.image = cell.speedometerImageView.image?.withRenderingMode(.alwaysTemplate)
//    cell.speedometerImageView.tintColor = UIColor.systemBlue
//
//    cell.distanceImageView.image = cell.distanceImageView.image?.withRenderingMode(.alwaysTemplate)
//    cell.distanceImageView.tintColor = UIColor.systemGreen
////    MyFunc.logMessage(.debug, "SelectedIndexPath: \(String(describing: selectedIndexPath))")
//    if selectedIndexPath != nil && indexPath.row == selectedIndexPath {
//      cell.contentView.backgroundColor = UIColor.red
//    } else {
//      cell.contentView.backgroundColor = UIColor.clear
//    }
//
//    return cell
//  }
//
//
//  func loadWorkouts(completion:
//                      @escaping ([HKWorkout]?, Error?) -> Void) {
//
//    let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate,
//                                          ascending: false)
//    let sourcePredicate = HKQuery.predicateForObjects(from: .default())
//
//    let query = HKSampleQuery(
//      sampleType: .workoutType(),
//      predicate: sourcePredicate,
////      predicate: nil,
//      limit: 0,
//      sortDescriptors: [sortDescriptor]) { (query, samples, error) in
//      DispatchQueue.main.async {
//        //4. Cast the samples as HKWorkout
//        guard
//          let samples = samples as? [HKWorkout],
//          error == nil
//        else {
//          completion(nil, error)
//          return
//        }
//
//        completion(samples, nil)
//      }
//    }
//
//    healthstore.execute(query)
//
//  }
//
//
//  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//
//    let segueToUse = segue.identifier
//
//    if segueToUse == "historyToDTMHeatmap" {
//      let destinationVC = segue.destination as! DTMHeatmapViewController
//      destinationVC.heatmapWorkoutId = (sender as! UUID)
//    }
//
//    if segueToUse == "historyToREHeatmap" {
//      let destinationVC = segue.destination as! REHeatmapViewController
//      destinationVC.heatmapWorkoutId = (sender as! UUID)
//    }
//
//    if segueToUse == "historyToJDHeatmap" {
//      let destinationVC = segue.destination as! JDHeatmapViewController
//      destinationVC.heatmapWorkoutId = (sender as! UUID)
//    }
//
//    navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
//  }
//
//}
//
//
