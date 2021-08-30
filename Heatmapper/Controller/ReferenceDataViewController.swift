//
//  ReferenceDataViewController
//  Heatmapper
//
//  Created by Richard English on 28/08/2021.
//  Copyright © 2021 Richard English. All rights reserved.
//

import UIKit

class ReferenceDataViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

  let theme = ColourTheme()
  let defaults = UserDefaults.standard
  private var activityArray = [String]()


  var selectedIndexPath : Int? = 0
  var currentIndexPath  = IndexPath()
//  var deleteRecord      : Bool = false

  @IBOutlet weak var activityTableView: ThemeTableViewNoBackground!

  override func viewDidLoad() {
    super.viewDidLoad()

    activityTableView.dataSource = self
    activityTableView.delegate = self
    activityTableView.allowsSelection = true


    activityTableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: activityTableView.frame.size.width, height: 1))
    activityTableView.tableHeaderView?.backgroundColor = UIColor.clear

    activityArray = defaults.stringArray(forKey: "Activity") ?? []

    MyFunc.logMessage(.debug, "activityArray: \(activityArray)")
    activityTableView.reloadData()
  }


  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return activityArray.count
  }


  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

    let cell = activityTableView.dequeueReusableCell(withIdentifier: "activityCell", for: indexPath)
    cell.textLabel?.text = activityArray[indexPath.row]
    return cell
  }


  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: false)

    selectedIndexPath = indexPath.row
    self.activityTableView.reloadData()

  }

  func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {

    selectedIndexPath = nil
    self.activityTableView.reloadData()
  }

  // this function manages the swipe-to-delete
  func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
    if editingStyle == .delete {
      currentIndexPath = indexPath
      confirmDelete(indexPath: currentIndexPath)

    } else if editingStyle == .insert {
      // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }
  }

  // function to handle confirmation after swiping to delete
  func confirmDelete(indexPath: IndexPath) {
    let alert = UIAlertController(title: "Delete Activity", message: "Are you sure you want to delete \(activityArray[indexPath.row])?", preferredStyle: .actionSheet)

    let deleteAction = UIAlertAction(title: "Delete", style: .destructive, handler: deleteActivityHandler)
    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: cancelActivityHandler)
    alert.addAction(deleteAction)
    alert.addAction(cancelAction)

    self.present(alert, animated: true, completion: nil)

  }

  func deleteActivityHandler(alertAction: UIAlertAction!)  {

    activityArray.remove(at: currentIndexPath.row)
    activityTableView.deleteRows(at: [currentIndexPath], with: UITableView.RowAnimation.fade)
    defaults.set(activityArray, forKey: "Activity")
    activityTableView.reloadData()

  }

  func cancelActivityHandler(alertAction: UIAlertAction!) {

  }


  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

    navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
  }


  @IBAction func addButton(_ sender: UIBarButtonItem) {

    var textField = UITextField()

    let alert = UIAlertController(title: "Add New Activity", message: "", preferredStyle: .alert)

    let action = UIAlertAction(title: "Add", style: .default) { (action) in

      let newActivity = textField.text!

      self.activityArray.append(newActivity)
      self.defaults.set(self.activityArray, forKey: "Activity")
      self.activityTableView.reloadData()
    }

    alert.addAction(action)

    alert.addTextField { (field) in
      textField = field
      textField.placeholder = "Add New Activity"
    }

    present(alert, animated: true, completion: nil)

  }


}
