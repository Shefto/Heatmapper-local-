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
  var workoutSelectedId : UUID?
  var selectedIndexPath : Int?
  var workoutSelected : String = ""
  var documentsDirectoryStr : String = ""
  var workoutHasHeatmap : Bool = false

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
  @IBOutlet weak var createdHeatmapButton: ThemeActionButton!

  @IBAction func btnDTMHeatmap(_ sender: Any) {
    self.performSegue(withIdentifier: "historyToDTMHeatmap", sender: workoutSelectedId)
  }

  @IBAction func btnJDHeatmap(_ sender: Any) {
    self.performSegue(withIdentifier: "historyToJDHeatmap", sender: workoutSelectedId)
  }

  @IBAction func btnREHeatmap(_ sender: Any) {
    self.performSegue(withIdentifier: "historyToREHeatmap", sender: workoutSelectedId)
  }

  @IBAction func btnCreatedHeatmap(_ sender: Any) {

    guard let workoutId = workoutSelectedId else {
      MyFunc.logMessage(.error, "No heatmapWorkoutId passed to btnCreatedHeatmap in WorkoutHistoryCollectionViewController")
      return
    }
    let workoutSelectedString = String(describing: workoutId)
    let heatmapImageString = "JDHeatmap_" + workoutSelectedString + ".png"

    let heatmapImageFileExists = MyFunc.checkFileExists(filename: heatmapImageString)

    if heatmapImageFileExists {
      self.performSegue(withIdentifier: "historyToCreatedHeatmap", sender: workoutSelectedId)
    } else {
      self.performSegue(withIdentifier: "historyToJDHeatmap", sender: workoutSelectedId)
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

    loadHeatmapImages()
    loadWorkouts { (workouts, error) in
      self.workoutArray = workouts
      MyFunc.logMessage(.debug, "workouts:")
      MyFunc.logMessage(.debug, String(describing: self.workoutArray))
      self.workoutCollectionView.reloadData()
    }

  }


  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return workoutArray?.count ?? 0
  }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = workoutCollectionView.dequeueReusableCell(withReuseIdentifier: "WorkoutCollectionViewCell", for: indexPath) as! WorkoutCollectionViewCell

    let workout = workoutArray![indexPath.row]
    let workoutId = workout.uuid

    let heatmapImage = MyFunciOS.getHeatmapImageForWorkout(workoutID: workoutId)

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
      workoutSelectedId = workoutArray?[indexPath.row].uuid
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

//  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//    return workoutArray?.count ?? 0
//  }
//
//
//  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//    tableView.deselectRow(at: indexPath, animated: false)
//    workoutSelectedId = workoutArray?[indexPath.row].uuid
//    MyFunc.logMessage(.debug, "workoutId: \(String(describing: workoutSelectedId))")
//    selectedIndexPath = indexPath.row
//
//  }

  // retrieve all Heatmapper workouts
  func loadWorkouts(completion: @escaping ([HKWorkout]?, Error?) -> Void) {

    let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate,
                                          ascending: false)
    let sourcePredicate = HKQuery.predicateForObjects(from: .default())

    let query = HKSampleQuery(
      sampleType: .workoutType(),
      predicate: sourcePredicate,

      limit: 0,
      sortDescriptors: [sortDescriptor]) { (query, samples, error) in
      DispatchQueue.main.async {
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
      let destinationVC = segue.destination as! JDHeatmapViewController
      destinationVC.heatmapWorkoutId = (sender as! UUID)
    }

    if segueToUse == "historyToCreatedHeatmap" {
      let destinationVC = segue.destination as! SavedHeatmapViewController
      destinationVC.heatmapWorkoutId = (sender as! UUID)
    }


    navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
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


