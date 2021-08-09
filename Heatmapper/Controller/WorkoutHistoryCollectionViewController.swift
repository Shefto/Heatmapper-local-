//
//  WorkoutHistoryCollectionViewController.swift
//  Heatmapper
//
//  Created by Richard English on 24/04/2021.
//  Copyright © 2021 Richard English. All rights reserved.
//

import UIKit
import HealthKit
import CoreLocation

class WorkoutHistoryCollectionViewController: UIViewController,  UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout  {


  let theme = ColourTheme()

  var heatmapImagesArray = [UIImage]()
  var heatmapImagesStringArray = [String]()
  private var workoutArray: [HKWorkout]?
  private let workoutCellId = "workoutCell"
  var workoutId : UUID?
  var selectedIndexPath : Int? = 0
  var workoutSelected : String = ""

  let locationManager          = CLLocationManager()
  let healthstore = HKHealthStore()
  lazy var dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.timeStyle = .short
    formatter.dateStyle = .short
    return formatter
  } ()


  @IBOutlet weak var workoutCollectionView: UICollectionView!
  @IBOutlet weak var workoutCollectionViewCell: WorkoutCollectionViewCell!
  @IBOutlet weak var reButton: UIButton!
  @IBOutlet weak var jdButton: UIButton!
  @IBOutlet weak var dtmButton: UIButton!

  @IBAction func btnDTMHeatmap(_ sender: Any) {
    self.performSegue(withIdentifier: "historyToDTMHeatmap", sender: workoutId)
  }

  @IBAction func btnJDHeatmap(_ sender: Any) {
    self.performSegue(withIdentifier: "historyToJDHeatmap", sender: workoutId)
  }

  @IBAction func btnREHeatmap(_ sender: Any) {
    self.performSegue(withIdentifier: "historyToREHeatmap", sender: workoutId)
  }


  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return workoutArray?.count ?? 0
  }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = workoutCollectionView.dequeueReusableCell(withReuseIdentifier: "WorkoutCollectionViewCell", for: indexPath) as! WorkoutCollectionViewCell

    let workout = workoutArray![indexPath.row]
    var heatmapToDisplayString : String = ""
    heatmapToDisplayString = workout.description

    var heatmapImage = UIImage()
//    if heatmapToDisplayString == "" {
    heatmapImage = UIImage(named: "Work.png")!
//    } else {
//      heatmapImage = UIImage(named: heatmapToDisplayString)!
//    }

    cell.heatmapImageView.image = heatmapImage
    cell.workoutDateLabel.text = dateFormatter.string(from: workout.startDate)
    cell.workoutTypeLabel.text = workout.workoutActivityType.name

    if selectedIndexPath != nil && indexPath.row == selectedIndexPath {
      cell.contentView.backgroundColor = theme.buttonPrimary
    } else {
      cell.contentView.backgroundColor = UIColor.clear
    }
    return cell
  }

  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    if (workoutCollectionView.cellForItem(at: indexPath) as? WorkoutCollectionViewCell) != nil {
      workoutId = workoutArray?[indexPath.row].uuid
      selectedIndexPath = indexPath.row
      workoutCollectionView.reloadData()

    }
  }

  func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
    if (workoutCollectionView.cellForItem(at: indexPath) as? WorkoutCollectionViewCell) != nil {
    }
  }

  func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
    if (workoutCollectionView.cellForItem(at: indexPath) as? WorkoutCollectionViewCell) != nil {
    }
    workoutSelected = workoutArray![indexPath.row].description

    selectedIndexPath = indexPath.row
    print("workoutSelected: \(workoutSelected)")
  }

  func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {

    if (workoutCollectionView.cellForItem(at: indexPath) as? WorkoutCollectionViewCell) != nil {
    }

  }

  override func viewDidLoad() {
    super.viewDidLoad()
    // added this to ensure Location tracking turned off (it should be by the time this screen is displayed though)
    locationManager.stopUpdatingLocation()


    workoutCollectionView.delegate = self
    workoutCollectionView.dataSource = self
    workoutCollectionView.register(UINib(nibName: "WorkoutCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "WorkoutCollectionViewCell")
    workoutCollectionView.collectionViewLayout = createLayout()
    workoutCollectionView.allowsMultipleSelection = false


    loadWorkouts { (workouts, error) in
      self.workoutArray = workouts
      MyFunc.logMessage(.debug, "workouts:")
      MyFunc.logMessage(.debug, String(describing: self.workoutArray))
      self.workoutCollectionView.reloadData()
    }

  }

  func loadHeatmapImages() {
    let fm = FileManager.default
    let path = Bundle.main.resourcePath!
    let items = try! fm.contentsOfDirectory(atPath: path)

    for item in items {
      if item.hasSuffix("png") || item.hasSuffix("jpg") || item.hasSuffix("jpeg") {
        if item.hasPrefix("JDHeatmap_") {
          heatmapImagesArray.append(UIImage(named: item)!)
          heatmapImagesStringArray.append(item)
        }
      }
    }

  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return workoutArray?.count ?? 0
  }


  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: false)
    workoutId = workoutArray?[indexPath.row].uuid
    MyFunc.logMessage(.debug, "workoutId: \(String(describing: workoutId))")
    selectedIndexPath = indexPath.row

  }


  func loadWorkouts(completion:
                      @escaping ([HKWorkout]?, Error?) -> Void) {

    let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate,
                                          ascending: false)
    let sourcePredicate = HKQuery.predicateForObjects(from: .default())

    let query = HKSampleQuery(
      sampleType: .workoutType(),
      predicate: sourcePredicate,
      //      predicate: nil,
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

    if segueToUse == "historyToDTMHeatmap" {
      let destinationVC = segue.destination as! DTMHeatmapViewController
      destinationVC.heatmapWorkoutId = (sender as! UUID)
    }

    if segueToUse == "historyToREHeatmap" {
      let destinationVC = segue.destination as! REHeatmapViewController
      destinationVC.heatmapWorkoutId = (sender as! UUID)
    }

    if segueToUse == "historyToJDHeatmap" {
      let destinationVC = segue.destination as! jdHeatmapViewController
      destinationVC.heatmapWorkoutId = (sender as! UUID)
    }

    navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
  }

  func getHeartRateSampleForWorkout(workout: HKWorkout) -> [HKQuantitySample] {
    guard let heartRateType =
            HKObjectType.quantityType(forIdentifier:
                                        HKQuantityTypeIdentifier.heartRate) else {
      fatalError("*** Unable to create a distance type ***")
    }

    var samplesToReturnSet = [HKQuantitySample]()
    let workoutPredicate = HKQuery.predicateForObjects(from: workout)

    //2. Get all workouts that only came from this app.
    let sourcePredicate = HKQuery.predicateForObjects(from: .default())

    //3. Combine the predicates into a single predicate.
    let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates:
                                                  [workoutPredicate, sourcePredicate])

    let startDateSort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

    let query = HKSampleQuery(sampleType: heartRateType,
                              predicate: compoundPredicate,
                              limit: 0,
                              sortDescriptors: [startDateSort]) { (sampleQuery, results, error) -> Void in
      guard let heartRateSamples = results as? [HKQuantitySample] else {
        // Perform proper error handling here.
        return
      }
      samplesToReturnSet = heartRateSamples
      // Use the workout's heartrate samples here.
    }

    healthstore.execute(query)
    return samplesToReturnSet
  }

}

// Apple code from https://developer.apple.com/documentation/uikit/views_and_controls/collection_views/using_collection_view_compositional_layouts_and_diffable_data_sources
extension WorkoutHistoryCollectionViewController {

  private func createLayout() -> UICollectionViewLayout {

    let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.33), heightDimension: .fractionalHeight(1.0))
    let item = NSCollectionLayoutItem(layoutSize: itemSize)

    let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalWidth(0.33))

    let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

    let section = NSCollectionLayoutSection(group: group)
    let layout = UICollectionViewCompositionalLayout(section: section)
    return layout
  }
}


