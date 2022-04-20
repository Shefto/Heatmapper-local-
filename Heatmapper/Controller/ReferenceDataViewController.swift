//
//  ReferenceDataViewController
//  Heatmapper
//
//  Created by Richard English on 28/08/2021.
//  Copyright © 2021 Richard English. All rights reserved.
//

import UIKit
import CloudKit

class ReferenceDataViewController: UIViewController {
  
  //CloudKit initialisations
  let container = CKContainer(identifier: "iCloud.com.wimbledonappcompany.Heatmapper")
  var privateDatabase: CKDatabase?
  var currentRecord: CKRecord?
  var recordZone: CKRecordZone?
  
  let theme = ColourTheme()
  let defaults = UserDefaults.standard
  private var activityArray = [Activity]()
  
  var sportArray = [Sport]()
  
  var selectedIndexPath : Int?
  var currentIndexPath  = IndexPath()
  
  @IBOutlet weak var activityTableView: ThemeTableViewNoBackground!
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    getData()
    activityTableView.reloadData()
    
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    initialiseCloudKitDB()
    activityTableView.dataSource = self
    activityTableView.delegate = self
    
    activityTableView.allowsSelection = true
    activityTableView.register(UINib(nibName: "ActivityCell", bundle: nil), forCellReuseIdentifier: "ActivityTableViewCell")
    activityTableView.register(UINib(nibName: "EditActivityCell", bundle: nil), forCellReuseIdentifier: "EditActivityTableViewCell")
    
    activityTableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: activityTableView.frame.size.width, height: 1))
    activityTableView.tableHeaderView?.backgroundColor = UIColor.clear
    
  }
  
  func getData() {

    getActivitiesFromCloud()
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
    self.performSegue(withIdentifier: "referenceDataToActivity", sender: nil)

  }
  
  func updateSportForActivity(newSport: Sport, indexPathRow: Int) {
    activityArray[indexPathRow].sport = newSport
    MyFunc.saveHeatmapActivityDefaults(activityArray)
  }
  
  
  func getActivitiesFromCloud()  {

    let predicate = NSPredicate(value: true)
    let query = CKQuery(recordType: "Activity", predicate: predicate)
    
    privateDatabase?.perform(query, inZoneWith: recordZone?.zoneID, completionHandler: ({results, error in
      
      if (error != nil) {
        DispatchQueue.main.async() {
          self.notifyUser("Cloud Access Error", message: error!.localizedDescription)
        }
      } else {
        if results!.count > 0 {
          self.activityArray.removeAll()
          results?.forEach( {
            let recordId = $0.recordID.recordName
            let recordName = $0.object(forKey: "name" as String )
            let recordSport = $0.object(forKey: "sport" as String )
            let activitySport : Sport = Sport(rawValue: recordSport as! String) ?? .none
            let activityFromRecord = Activity(recordId: recordId, name: recordName as! String, sport: activitySport)
            self.activityArray.append(activityFromRecord)
          })
          
          DispatchQueue.main.async() {
            
            let resultsStr = String(describing: results)
            print("Activities retrieved: \(resultsStr)")

            MyFunc.logMessage(.debug, "activityArray: \(self.activityArray)")
            self.activityTableView.reloadData()
            
          }
        } else {
          DispatchQueue.main.async() {
            self.notifyUser("No Match Found", message: "No record matching the address was found")
          }
        }
      }
    }))
    
    
  }
  
  
  func notifyUser(_ title: String, message: String) -> Void
  {
    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
    let cancelAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
    
    alert.addAction(cancelAction)
    self.present(alert, animated: true, completion: nil)
  }
  
  func initialiseCloudKitDB() {
    privateDatabase = container.privateCloudDatabase
    recordZone = CKRecordZone.default()
  }
}

extension ReferenceDataViewController: UITableViewDelegate, UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return activityArray.count
  }
  
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = activityTableView.dequeueReusableCell(withIdentifier: "ActivityTableViewCell", for: indexPath) as! ActivityTableViewCell
    
    cell.activityLabel.text = activityArray[indexPath.row].name
    cell.sportLabel.text = activityArray[indexPath.row].sport.rawValue
    return cell
  }
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
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
  
  // this function controls the two swipe controls
  func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
    
    let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { _, _, complete in

      let activityToDeleteID = self.activityArray[indexPath.row].recordId
      privateDatabase?.delete(withRecordID: activityToDeleteID, completionHandler: {  recordID, error in
        if let err = error {
          DispatchQueue.main.async {

            self.notifyUser("Save Error", message:
                              err.localizedDescription)
          }
        } else {
          DispatchQueue.main.async {
            self.notifyUser("Success",
                            message: "Record saved successfully")
          }
          self.currentRecord = activityToInsert
        }
      }
      )
      self.activityArray.remove(at: indexPath.row)
      tableView.deleteRows(at: [indexPath], with: .fade)
      MyFunc.saveHeatmapActivityDefaults(self.activityArray)



      self.activityTableView.reloadData()
      complete(true)
    }
    
    deleteAction.backgroundColor = .red
    deleteAction.image = UIImage(systemName: "trash")
    
    let editAction = UIContextualAction(style: .destructive, title: "Edit") { _, _, complete in
      // switch table into edit mode
      let activityToSend = self.activityArray[indexPath.row]
      self.performSegue(withIdentifier: "referenceDataToActivity", sender: activityToSend)
      
      complete(true)
    }
    
    editAction.backgroundColor = .systemGray
    editAction.image = UIImage(systemName: "pencil")
    
    let configuration = UISwipeActionsConfiguration(actions: [deleteAction, editAction])
    configuration.performsFirstActionWithFullSwipe = false
    return configuration
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
