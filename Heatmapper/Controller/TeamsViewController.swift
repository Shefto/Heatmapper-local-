//
//  TeamsViewController.swift
//  Heatmapper
//
//  Created by Richard English on 01/10/2021.
//  Copyright © 2021 Richard English. All rights reserved.
//

import UIKit


class TeamsViewController: UIViewController {

  let theme = ColourTheme()
  let defaults = UserDefaults.standard
//  private var teamArray = [Team]()
  private var teamArray = [Activity]()
  var sportArray = [Sport]()

  var selectedIndexPath : Int?
  var currentIndexPath  = IndexPath()

  @IBOutlet weak var teamTableView: ThemeTableViewNoBackground!


  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    getData()


  }

  override func viewDidLoad() {
    super.viewDidLoad()

    teamTableView.dataSource = self
    teamTableView.delegate = self

    teamTableView.allowsSelection = true
    teamTableView.register(UINib(nibName: "ActivityCell", bundle: nil), forCellReuseIdentifier: "ActivityTableViewCell")
    teamTableView.register(UINib(nibName: "EditActivityCell", bundle: nil), forCellReuseIdentifier: "EditActivityTableViewCell")

    teamTableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: teamTableView.frame.size.width, height: 1))
    teamTableView.tableHeaderView?.backgroundColor = UIColor.clear

  }

  func getData() {

//    teamArray = MyFunc.getTeams()

    teamArray = MyFunc.getHeatmapperActivityDefaults()
    MyFunc.logMessage(.debug, "team: \(teamArray)")
    teamTableView.reloadData()

    sportArray = Sport.allCases.map { $0 }

  }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    let segueToUse = segue.identifier
    if segueToUse == "referenceDataToActivity" {
      let activityVC = segue.destination as! ActivityViewController
      activityVC.activityToUpdate = sender as? Activity
    }
    navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
  }


  @IBAction func addButton(_ sender: UIBarButtonItem) {

    self.performSegue(withIdentifier: "teamsToActivity", sender: nil)

  }

  func updateSportForTeam(newSport: Sport, indexPathRow: Int) {
    teamArray[indexPathRow].sport = newSport
    MyFunc.saveHeatmapActivityDefaults(teamArray)
  }

}

extension TeamsViewController: UITableViewDelegate, UITableViewDataSource {

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return teamArray.count
  }


  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

    let cell = teamTableView.dequeueReusableCell(withIdentifier: "ActivityTableViewCell", for: indexPath) as! ActivityTableViewCell

    cell.activityLabel.text = teamArray[indexPath.row].name
    cell.sportLabel.text = teamArray[indexPath.row].sport.rawValue
//    cell.sportPicker.delegate = self


    // set Picker value
//    let activitySportRow : Int = sportArray.firstIndex(where: { $0 == teamArray[indexPath.row].sport  }) ?? 0

//    cell.sportPicker.selectRow(activitySportRow, inComponent: 0, animated: true)
//    if #available(iOS 14.0, *) {
//      cell.sportPicker.subviews[1].backgroundColor = .clear
//    }
    return cell
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

    selectedIndexPath = indexPath.row
    teamTableView.reloadData()

  }

  func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    return true
  }

  func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
    selectedIndexPath = nil
    self.teamTableView.reloadData()
  }



  // this function controls the two swipe controls
  func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {

    let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { _, _, complete in

      self.teamArray.remove(at: indexPath.row)
      tableView.deleteRows(at: [indexPath], with: .fade)
      MyFunc.saveHeatmapActivityDefaults(self.teamArray)
      self.teamTableView.reloadData()
      complete(true)
    }

    deleteAction.backgroundColor = .red
    deleteAction.image = UIImage(systemName: "trash")

    let editAction = UIContextualAction(style: .destructive, title: "Edit") { _, _, complete in
      // switch table into edit mode
      let activityToSend = self.teamArray[indexPath.row]
      self.performSegue(withIdentifier: "teamsToActivity", sender: activityToSend)

      complete(true)
    }

    editAction.backgroundColor = .systemGray
    editAction.image = UIImage(systemName: "pencil")

    let configuration = UISwipeActionsConfiguration(actions: [deleteAction, editAction])
    configuration.performsFirstActionWithFullSwipe = false
    return configuration
  }

}

extension TeamsViewController: UIPickerViewDelegate, UIPickerViewDataSource {

  func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
    MyFunc.logMessage(.debug, "ReferenceDataViewController.didSelectRow: \(row)")
    let sportSelected = sportArray[row]

    let tableViewCell = pickerView.superview?.superview as! ActivityTableViewCell
    guard let tableIndexPath = self.teamTableView.indexPath(for: tableViewCell) else {
      MyFunc.logMessage(.error, "Invalid or missing indexPath for tableViewCell")
      return
    }
    let tableIndexPathRow = tableIndexPath.row
    MyFunc.logMessage(.debug, "tableIndexPathRow: \(tableIndexPathRow)")
    updateSportForTeam(newSport: sportSelected, indexPathRow: tableIndexPath.row)



  }

  func numberOfComponents(in pickerView: UIPickerView) -> Int {
    return 1
  }

  func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
    return sportArray.count
  }

  func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
    return sportArray[row].rawValue
  }

}


