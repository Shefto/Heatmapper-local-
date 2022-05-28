//
//  PlayingAreasViewController.swift
//  Heatmapper
//
//  Created by Richard English on 22/03/2022.
//  Copyright © 2022 Richard English. All rights reserved.
//

import UIKit

class PlayingAreasViewController: UIViewController {


  let theme = ColourTheme()
  let defaults = UserDefaults.standard
  private var playingAreaArray = [PlayingArea]()

  var selectedIndexPath : Int?
  var currentIndexPath  = IndexPath()

  @IBOutlet weak var playingAreaTableView: ThemeTableViewNoBackground!

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    getData()
    playingAreaTableView.reloadData()
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    initialiseUI()


  }

  func initialiseUI() {
    playingAreaTableView.dataSource = self
    playingAreaTableView.delegate = self

    playingAreaTableView.allowsSelection = true

    playingAreaTableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: playingAreaTableView.frame.size.width, height: 1))
    playingAreaTableView.tableHeaderView?.backgroundColor = UIColor.clear

  }

  func getData() {
    playingAreaArray = MyFunc.getPlayingAreas()
    MyFunc.logMessage(.debug, "playingAreaArray: \(playingAreaArray)")

  }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    let segueToUse = segue.identifier
    if segueToUse == "playingAreasToPlayingArea" {
      let playingAreaVC = segue.destination as! PlayingAreaViewController
      playingAreaVC.playingAreaToUpdate = sender as? PlayingArea
    }
    navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
  }


  @IBAction func addButton(_ sender: UIBarButtonItem) {


    self.performSegue(withIdentifier: "referenceDataToActivity", sender: nil)

  }

//  func updateSportForActivity(newSport: Sport, indexPathRow: Int) {
//    playingAreaArray[indexPathRow].sport = newSport
//    MyFunc.saveHeatmapActivityDefaults(playingAreaArray)
//  }

}

extension PlayingAreasViewController: UITableViewDelegate, UITableViewDataSource {

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return playingAreaArray.count
  }


  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

    let cell = playingAreaTableView.dequeueReusableCell(withIdentifier: "PlayingAreaTableViewCell", for: indexPath)

    cell.textLabel!.text = playingAreaArray[indexPath.row].name
    cell.detailTextLabel!.text = playingAreaArray[indexPath.row].venue

    return cell
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

    selectedIndexPath = indexPath.row
    let playingAreaToSend = self.playingAreaArray[indexPath.row]
    self.performSegue(withIdentifier: "playingAreasToPlayingArea", sender: playingAreaToSend)
    //    self.playingAreaTableView.reloadData()

  }

  func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    return true
  }

  func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
    selectedIndexPath = nil

  }



  // this function controls the two swipe controls
  func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {

    let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { _, _, complete in

      self.playingAreaArray.remove(at: indexPath.row)
      tableView.deleteRows(at: [indexPath], with: .fade)
//      MyFunc.saveHeatmapActivityDefaults(self.playingAreaArray)
      self.playingAreaTableView.reloadData()
      complete(true)
    }

    deleteAction.backgroundColor = .red
    deleteAction.image = UIImage(systemName: "trash")

    let editAction = UIContextualAction(style: .destructive, title: "Edit") { _, _, complete in
      // switch table into edit mode
      let playingAreaToSend = self.playingAreaArray[indexPath.row]
      self.performSegue(withIdentifier: "playingAreasToPlayingArea", sender: playingAreaToSend)

      complete(true)
    }

    editAction.backgroundColor = .systemGray
    editAction.image = UIImage(systemName: "pencil")

    let configuration = UISwipeActionsConfiguration(actions: [deleteAction, editAction])
    configuration.performsFirstActionWithFullSwipe = false
    return configuration
  }

}

