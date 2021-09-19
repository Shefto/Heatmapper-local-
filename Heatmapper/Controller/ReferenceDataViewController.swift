//
//  ReferenceDataViewController
//  Heatmapper
//
//  Created by Richard English on 28/08/2021.
//  Copyright © 2021 Richard English. All rights reserved.
//

import UIKit

class ReferenceDataViewController: UIViewController {

  let theme = ColourTheme()
  let defaults = UserDefaults.standard
  private var activityArray = [Activity]()
  var sportArray = [Sport]()

  var selectedIndexPath : Int?
  var currentIndexPath  = IndexPath()

  @IBOutlet weak var activityTableView: ThemeTableViewNoBackground!

  override func viewDidLoad() {
    super.viewDidLoad()

    activityTableView.dataSource = self
    activityTableView.delegate = self
    activityTableView.allowsSelection = true
    activityTableView.register(UINib(nibName: "ActivityCell", bundle: nil), forCellReuseIdentifier: "ActivityTableViewCell")
    activityTableView.register(UINib(nibName: "EditActivityCell", bundle: nil), forCellReuseIdentifier: "EditActivityTableViewCell")

    activityTableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: activityTableView.frame.size.width, height: 1))
    activityTableView.tableHeaderView?.backgroundColor = UIColor.clear

    getData()
    
  }

  func getData() {

    activityArray = MyFunc.getHeatmapperActivityDefaults()
    MyFunc.logMessage(.debug, "activityArray: \(activityArray)")
    activityTableView.reloadData()
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

    var textField = UITextField()

    let alert = UIAlertController(title: "Add New Activity", message: "", preferredStyle: .alert)

    let action = UIAlertAction(title: "Add", style: .default) { (action) in

      let newActivityName = textField.text!
      let newSport = Sport.none
      let newActivity = Activity(name: newActivityName, sport: newSport)

      self.activityArray.append(newActivity)
      MyFunc.saveHeatmapActivityDefaults(self.activityArray)
      self.activityTableView.reloadData()
    }

    alert.addAction(action)

    alert.addTextField { (field) in
      textField = field
      textField.placeholder = "Add New Activity"
    }

    present(alert, animated: true, completion: nil)

  }


  func updateSportForActivity(newSport: Sport, indexPathRow: Int) {
    activityArray[indexPathRow].sport = newSport
    //    let activityToSave = activityArray[indexPath.row]
    MyFunc.saveHeatmapActivityDefaults(activityArray)
  }


  // functions to handle confirmation after swiping to delete
  func confirmDelete(indexPath: IndexPath) {
    let alert = UIAlertController(title: "Delete Activity", message: "Are you sure you want to delete \(activityArray[indexPath.row].name)?", preferredStyle: .actionSheet)

    let deleteAction = UIAlertAction(title: "Delete", style: .destructive, handler: deleteActivityHandler)
    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: cancelActivityHandler)
    alert.addAction(deleteAction)
    alert.addAction(cancelAction)

    self.present(alert, animated: true, completion: nil)

  }

  func deleteActivityHandler(alertAction: UIAlertAction!)  {

    activityArray.remove(at: currentIndexPath.row)
    activityTableView.deleteRows(at: [currentIndexPath], with: UITableView.RowAnimation.fade)
    //    defaults.set(activityArray, forKey: "Activity")
    MyFunc.saveHeatmapActivityDefaults(self.activityArray)
    activityTableView.reloadData()

  }

  func cancelActivityHandler(alertAction: UIAlertAction!) {
  }

}

extension ReferenceDataViewController: UITableViewDelegate, UITableViewDataSource {

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return activityArray.count
  }


  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

    let cell = activityTableView.dequeueReusableCell(withIdentifier: "ActivityTableViewCell", for: indexPath) as! ActivityTableViewCell

    cell.activityLabel.text = activityArray[indexPath.row].name
    cell.sportPicker.delegate = self

    // set Picker value
    let activitySportRow : Int = sportArray.firstIndex(where: { $0 == activityArray[indexPath.row].sport  }) ?? 0

    cell.sportPicker.selectRow(activitySportRow, inComponent: 0, animated: true)
    if #available(iOS 14.0, *) {
      cell.sportPicker.subviews[1].backgroundColor = .clear
    }
    return cell
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//    MyFunc.logMessage(.debug, "ReferenceDataViewController.didSelectRow: \(indexPath.row)")
    selectedIndexPath = indexPath.row
    activityTableView.reloadData()

  }

  func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    return true
  }

  func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
    selectedIndexPath = nil
    self.activityTableView.reloadData()
  }

//  func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
//    MyFunc.logMessage(.debug, "editingStyleForRowAt called")
//    return .none
//  }

  func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {

    let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { _, _, complete in
      self.activityArray.remove(at: indexPath.row)
      tableView.deleteRows(at: [indexPath], with: .fade)
      MyFunc.saveHeatmapActivityDefaults(self.activityArray)
      self.activityTableView.reloadData()
      complete(true)
    }

    deleteAction.backgroundColor = .red
//    deleteAction.image = UIImage(systemName: "trash")

    let editAction = UIContextualAction(style: .destructive, title: "Edit") { _, _, complete in
      // switch table into edit mode

      MyFunc.saveHeatmapActivityDefaults(self.activityArray)
      self.activityTableView.reloadData()
      complete(true)
    }

    editAction.backgroundColor = .systemGray
//    editAction.image = UIImage(systemName: "pencil")

    let configuration = UISwipeActionsConfiguration(actions: [deleteAction, editAction])
    configuration.performsFirstActionWithFullSwipe = false
    return configuration
  }

  // this function manages the swipe-to-delete
  func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
    if editingStyle == .delete {
      currentIndexPath = indexPath
      confirmDelete(indexPath: currentIndexPath)

    } else if editingStyle == .insert {

    }
  }



}

extension ReferenceDataViewController: UIPickerViewDelegate, UIPickerViewDataSource {

  func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
    MyFunc.logMessage(.debug, "ReferenceDataViewController.didSelectRow: \(row)")
    let sportSelected = sportArray[row]

    let tableViewCell = pickerView.superview?.superview as! ActivityTableViewCell
    guard let tableIndexPath = self.activityTableView.indexPath(for: tableViewCell) else {
      MyFunc.logMessage(.error, "Invalid or missing indexPath for tableViewCell")
      return
    }
    let tableIndexPathRow = tableIndexPath.row
    MyFunc.logMessage(.debug, "tableIndexPathRow: \(tableIndexPathRow)")
    updateSportForActivity(newSport: sportSelected, indexPathRow: tableIndexPath.row)



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
