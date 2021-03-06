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

//  struct WorkoutInfo {
//    var uuid            : UUID
//    var samples         : Bool
//    var locations       : Bool
//    var sampleCount     : Int
//    var locationsCount  : Int
//
//    init(uuid: UUID, samples: Bool, locations: Bool, sampleCount: Int, locationsCount: Int) {
//      self.uuid           = uuid
//      self.samples        = samples
//      self.locations      = locations
//      self.sampleCount    = sampleCount
//      self.locationsCount = locationsCount
//    }
//  }

  let theme = ColourTheme()

  var heatmapImagesArray          = [UIImage]()
  var heatmapImagesStringArray    = [String]()
  private var workoutArray        = [HKWorkout]()
  private var workoutInfoArray    = [WorkoutInfo]()
  var workoutMetadataArray        = [WorkoutMetadata]()
//  var workoutMetadata             = WorkoutMetadata(workoutId: UUID.init(), activity: "", sport: "", venue: "", pitch: "")
  var workoutMetadata             = WorkoutMetadata()


  var workoutSelectedId : UUID?
  var selectedIndexPath : Int?
  var workoutSelected : String = ""
  var documentsDirectoryStr : String = ""
  var workoutHasHeatmap : Bool = false

  let locationManager          = CLLocationManager()
  let healthStore = HKHealthStore()
  lazy var dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.timeStyle = .short
    formatter.dateStyle = .short
    return formatter
  } ()

  @IBOutlet weak var workoutCollectionView: UICollectionView!
  @IBOutlet weak var workoutCollectionViewCell: WorkoutCollectionViewCell!

  @IBOutlet weak var heatmapButton: ThemeButton!
  @IBOutlet weak var heatmapTesterButton: ThemeButton!
  @IBOutlet weak var heatmapInfoButton: ThemeButton!

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    heatmapButton.isEnabled = false
    heatmapInfoButton.isEnabled = false
    heatmapTesterButton.isEnabled = false

    workoutInfoArray.removeAll()
    loadHeatmapImages()
    loadWorkouts { (workouts, error) in
      guard let workoutsReturned = workouts else {
        MyFunc.logMessage(.debug, "No workouts returned")
        return
      }
//      MyFunc.logMessage(.debug, "loadWorkouts returned workouts:")
//      MyFunc.logMessage(.debug, String(describing: workoutsReturned))

      self.workoutArray = workoutsReturned

      for workoutToProcess in workoutsReturned {
        let workoutToAppend = WorkoutInfo(uuid: workoutToProcess.uuid, samples: false, locations: false, sampleCount: 0, locationsCount: 0)
        self.workoutInfoArray.append(workoutToAppend)
        self.getRouteSampleObject(workout: workoutToProcess)
      }
      self.getWorkoutMetadata()
      self.workoutCollectionView.reloadData()
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

  }

  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return workoutArray.count
  }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = workoutCollectionView.dequeueReusableCell(withReuseIdentifier: "WorkoutCollectionViewCell", for: indexPath) as! WorkoutCollectionViewCell

    let workout = workoutArray[indexPath.row]
//    MyFunc.logMessage(.debug, "workout metadata: \(String(describing: workout.metadata))")
    let workoutId = workout.uuid

    var metadata = WorkoutMetadata()

    if let workoutMetadataRow = self.workoutMetadataArray.firstIndex(where: {$0.workoutId == workoutId}) {
      metadata = self.workoutMetadataArray[workoutMetadataRow]
    }
    workoutMetadata = metadata

    let heatmapImage = MyFunciOS.getHeatmapImageForWorkout(workoutID: workoutId)


    cell.heatmapImageView.image = heatmapImage
    cell.workoutDateLabel.text = dateFormatter.string(from: workout.startDate)
//    cell.venueLabel.text = workoutMetadata.playingAreaVenue
    cell.activityLabel.text = workoutMetadata.activity

//    if selectedIndexPath != nil && indexPath.row == selectedIndexPath {
//      cell.contentView.backgroundColor = theme.buttonPrimary
//    } else {
//      cell.contentView.backgroundColor = UIColor.clear
//    }

    cell.layer.cornerRadius = 6
    return cell
  }

  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    if (workoutCollectionView.cellForItem(at: indexPath) as? WorkoutCollectionViewCell) != nil {
      workoutSelectedId = workoutArray[indexPath.row].uuid
//      selectedIndexPath = indexPath.row
      self.performSegue(withIdentifier: "historyToHeatmap", sender: workoutSelectedId)

//      workoutCollectionView.reloadData()
//      heatmapButton.isEnabled = true
//      heatmapInfoButton.isEnabled = true
//      heatmapTesterButton.isEnabled = true
    }
  }

//  func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
//    if (workoutCollectionView.cellForItem(at: indexPath) as? WorkoutCollectionViewCell) != nil {
//    }
//  }

//  func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
//    if (workoutCollectionView.cellForItem(at: indexPath) as? WorkoutCollectionViewCell) != nil {
//    }
//    workoutSelected = workoutArray[indexPath.row].description
//
//    selectedIndexPath = indexPath.row
//    print("workoutSelected: \(workoutSelected)")
//  }
//
//  func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
//
//    if (workoutCollectionView.cellForItem(at: indexPath) as? WorkoutCollectionViewCell) != nil {
//    }
//
//  }

  //MARK: Data load functions
  func loadHeatmapImages() {
    let fm = FileManager.default
    let path = Bundle.main.resourcePath!
//    let path = getDocumentsDirectory().absoluteString
    let items = try! fm.contentsOfDirectory(atPath: path)


    for item in items {
      if item.hasSuffix("png") || item.hasSuffix("jpg") || item.hasSuffix("jpeg") {
        if item.hasPrefix("Heatmap_") {
          heatmapImagesArray.append(UIImage(named: item)!)
          heatmapImagesStringArray.append(item)
        }
      }
    }
  }

  func getDocumentsDirectory() -> URL {
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    let documentsDirectory = paths[0]
    return documentsDirectory
  }




  // retrieve all Heatmapper workouts
  func loadWorkouts(completion: @escaping ([HKWorkout]?, Error?) -> Void) {

    let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
    let sourcePredicate = HKQuery.predicateForObjects(from: .default())

    let query = HKSampleQuery(sampleType: .workoutType(), predicate: sourcePredicate, limit: 0, sortDescriptors: [sortDescriptor]) { (query, samples, error) in
      DispatchQueue.main.async {
        guard
          let samples = samples as? [HKWorkout], error == nil
        else {
          completion(nil, error)
          return
        }
        completion(samples, nil)
      }
    }
    healthStore.execute(query)

  }



  func getRouteSampleObject(workout: HKWorkout)  {

//    var samplesReturned : Bool = false
    let runningObjectQuery = HKQuery.predicateForObjects(from: workout)

    let routeQuery = HKAnchoredObjectQuery(type: HKSeriesType.workoutRoute(), predicate: runningObjectQuery, anchor: nil, limit: HKObjectQueryNoLimit) { (query, samples, deletedObjects, anchor, error) in

      guard error == nil else {
        // Handle any errors here.
        fatalError("The initial query failed.")
      }

      // Process the initial route data here.

      DispatchQueue.main.async {
        guard
          let routeSamples = samples as? [HKWorkoutRoute],
          error == nil
        else {
          return
        }
        guard let routeReturned = samples?.first as? HKWorkoutRoute else {
//          MyFunc.logMessage(.debug, "No Route returned for workout \(String(describing: workout.startDate))")

          return
        }

        if let workoutInfoRow = self.workoutInfoArray.firstIndex(where: {$0.uuid == workout.uuid}) {
          self.workoutInfoArray[workoutInfoRow].samples = true
          self.workoutInfoArray[workoutInfoRow].sampleCount = routeSamples.count
        }
        self.getRouteLocationData(route: routeReturned, workoutId: workout.uuid)



      }

    }

    routeQuery.updateHandler = { (query, samples, deleted, anchor, error) in

      guard error == nil else {
        // Handle any errors here.
        fatalError("The update failed.")
      }

      // Process updates or additions here.
    }

    healthStore.execute(routeQuery)

  }

  func getRouteLocationData(route: HKWorkoutRoute, workoutId: UUID)  {

    var locationsReturned : Bool = false
//    let samplesCount = route.count
//    MyFunc.logMessage(.debug, "Number of samples: \(samplesCount)")

    // Create the route query.
    let query = HKWorkoutRouteQuery(route: route) { (query, locationsOrNil, done, errorOrNil) in
//
      // This block may be called multiple times.
//      MyFunc.logMessage(.debug, "Workout Start Date: \(String(describing: route.startDate))")
      if errorOrNil != nil {
        // Handle any errors here.
        MyFunc.logMessage(.debug, "Error retrieving workout locations")

      }

      guard let locations = locationsOrNil else {
        fatalError("*** Invalid State: This can only fail if there was an error. ***")
      }

      //      MyFunc.logMessage(.debug, "Workout Location Data: \(String(describing: locations))")
      let locationsAsCoordinates = locations.map {$0.coordinate}
//      MyFunc.logMessage(.debug, "Locations retrieved: \(locationsAsCoordinates)")

      if locationsAsCoordinates.count == 0 {
        locationsReturned = false
      } else {
        locationsReturned = true
      }
      if let workoutInfoRow = self.workoutInfoArray.firstIndex(where: {$0.uuid == workoutId}) {
        self.workoutInfoArray[workoutInfoRow].locations = locationsReturned
        self.workoutInfoArray[workoutInfoRow].locationsCount = locationsAsCoordinates.count
      }


    }
    healthStore.execute(query)

  }


  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

    let segueToUse = segue.identifier

//    if segueToUse == "historyToDTMHeatmap" {
//      let destinationVC = segue.destination as! DTMHeatmapViewController
//      destinationVC.heatmapWorkoutId = (sender as! UUID)
//    }

    if segueToUse == "historyToHeatmap" {
      let destinationVC = segue.destination as! HeatmapViewController
      destinationVC.heatmapWorkoutId = (sender as! UUID)
    }

//    if segueToUse == "historyToTester" {
//      let destinationVC = segue.destination as! TesterViewController
//      destinationVC.heatmapWorkoutId = (sender as! UUID)
//    }
//
//    if segueToUse == "historyToJDHeatmap" {
//      let destinationVC = segue.destination as! JDHeatmapViewController
//      destinationVC.heatmapWorkoutId = (sender as! UUID)
//    }
//
//    if segueToUse == "historyToCreatedHeatmap" {
//      let destinationVC = segue.destination as! SavedHeatmapViewController
//      destinationVC.heatmapWorkoutId = (sender as! UUID)
//    }


    navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
  }

  func getWorkoutMetadata() {

    // currently retrieving the whole array but will tighten this up once working
    workoutMetadataArray = MyFunc.getWorkoutMetadata()
//    MyFunc.logMessage(.debug, "updateWorkout: workoutMetadataArray: \(String(describing: workoutMetadataArray))")
  }

}

// Apple code from https://developer.apple.com/documentation/uikit/views_and_controls/collection_views/using_collection_view_compositional_layouts_and_diffable_data_sources
extension WorkoutHistoryCollectionViewController {

  private func createLayout() -> UICollectionViewLayout {

    let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.5), heightDimension: .fractionalHeight(1.0))
    let item = NSCollectionLayoutItem(layoutSize: itemSize)

//    let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalWidth(0.5))
    let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(300))

    let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

    let section = NSCollectionLayoutSection(group: group)
    let layout = UICollectionViewCompositionalLayout(section: section)
    
    return layout
  }

}


