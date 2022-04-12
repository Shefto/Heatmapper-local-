//
//  ActivityViewController.swift
//  Heatmapper
//
//  Created by Richard English on 18/09/2021.
//  Copyright © 2021 Richard English. All rights reserved.
//

import UIKit
import CloudKit

class ActivityViewController: UIViewController {

  //CloudKit initialisations
  let container = CKContainer(identifier: "iCloud.com.wimbledonappcompany.Heatmapper")
  var privateDatabase: CKDatabase?
  //  var sharedDatabase: CKDatabase?
  var currentRecord: CKRecord?
  var recordZone: CKRecordZone?

  let theme = ColourTheme()
  let defaults = UserDefaults.standard
  var activityToUpdate : Activity?
  private var activityArray = [Activity]()
  var activityToUpdateRow : Int?
  var sportArray = [Sport]()
  var newActivity : Bool = false
  var sportSelected = Sport()

  @IBOutlet weak var saveButton: UIBarButtonItem!
  @IBOutlet weak var activityNameField: ThemeTextField!
  @IBOutlet weak var sportPicker: ThemePickerView!


  override func viewDidLoad() {
    super.viewDidLoad()
    if activityToUpdate == nil {
      newActivity = true
    }
    saveButton.isEnabled = false
    sportPicker.dataSource = self
    sportPicker.delegate = self
    getData()
    updateUI()
    initialiseCloudKitDB()
  }

  func getData() {
    activityArray = MyFunc.getHeatmapperActivityDefaults()
    activityToUpdateRow = activityArray.firstIndex(where: { $0 == activityToUpdate })
    sportArray = Sport.allCases.map { $0 }
  }

  func updateUI() {
    activityNameField.text = activityToUpdate?.name
    let activitySportRow : Int = sportArray.firstIndex(where: { $0 == activityToUpdate?.sport  }) ?? 0
    sportPicker.selectRow(activitySportRow, inComponent: 0, animated: true)
    if #available(iOS 14.0, *) {
      sportPicker.subviews[1].backgroundColor = .clear
    }

    func textFieldDidEndEditing(_ textField: UITextField) {

      if activityNameField.text != activityToUpdate?.name {
        saveButton.isEnabled = true
      } else {
        saveButton.isEnabled = false
      }
    }


  }

  @IBAction func btnSave(_ sender: Any) {

//    saveRecord()
  }

  func saveRecord() {

    if newActivity == true {

      let newActivityName = activityNameField.text ?? ""
      let newSport = sportSelected
      let newActivity = Activity(name: newActivityName, sport: newSport)
      activityArray.append(newActivity)


      // insert Activity into CloudKit database
      insertActivityIntoCloudKit(activity: newActivity)

    } else {

      guard let activityToUpdateRowUnwrapped = activityToUpdateRow else {
        MyFunc.logMessage(.error, "ActivityViewController: activityToUpdateRow empty")
        return
      }
      activityArray[activityToUpdateRowUnwrapped].name = activityNameField.text ?? ""
      activityArray[activityToUpdateRowUnwrapped].sport = sportSelected
    }

    MyFunc.saveHeatmapActivityDefaults(activityArray)
    MyFunc.logMessage(.debug, "updates Saved")
  }

  @IBAction func activityNameEditingDidBegin(_ sender: Any) {
    MyFunc.logMessage(.debug, "activityNameEditingDidBegin called")
    saveButton.isEnabled = true
  }

  @IBAction func activityNameEditingDidEnd(_ sender: Any) {
    MyFunc.logMessage(.debug, "activityNameEditingDidEnd called")
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    saveRecord()
  }

  @IBAction func activityNameDidEndOnExit(_ sender: Any) {
  }

  func insertActivityIntoCloudKit(activity: Activity) {

    let activityToInsert = CKRecord(recordType: "Activity")
    activityToInsert.setObject(activity.name as CKRecordValue?, forKey: "name")
    let sportName = activity.sport.rawValue
    activityToInsert.setObject(sportName as CKRecordValue?, forKey: "sport")

    let modifyRecordsOperation = CKModifyRecordsOperation(
      recordsToSave: [activityToInsert],
      recordIDsToDelete: nil)

    modifyRecordsOperation.timeoutIntervalForRequest = 10
    modifyRecordsOperation.timeoutIntervalForResource = 10

    modifyRecordsOperation.modifyRecordsCompletionBlock =
    { records, recordIDs, error in
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
    privateDatabase?.add(modifyRecordsOperation)
  }

  func notifyUser(_ title: String, message: String) -> Void
  {
    let alert = UIAlertController(title: title,
                                  message: message,
                                  preferredStyle: .alert)

    let cancelAction = UIAlertAction(title: "OK",
                                     style: .cancel, handler: nil)

    alert.addAction(cancelAction)
    self.present(alert, animated: true,
                 completion: nil)
  }

  func initialiseCloudKitDB() {
    privateDatabase = container.privateCloudDatabase
    //    privateDatabase = container().sharedCloudDatabase
    // recordZone = CKRecordZone(zoneName: "HouseZone")
    recordZone = CKRecordZone.default()

//    privateDatabase?.save(recordZone!,
//                          completionHandler: {(recordzone, error) in
//      if (error != nil) {
//        DispatchQueue.main.async {
//
//          self.notifyUser("Record Zone Error : \(String(describing: error))",
//                          message: "Failed to create custom record zone.")
//        }
//      } else {
//        print("Saved record zone")
//      }
//    })


    let predicate = NSPredicate(format: "TRUEPREDICATE")

    let subscription = CKQuerySubscription(recordType: "Activity",
                                           predicate: predicate,
                                           options: .firesOnRecordCreation)

    let notificationInfo = CKSubscription.NotificationInfo()

    notificationInfo.alertBody = "A new Activity was added"
    notificationInfo.shouldBadge = true

    subscription.notificationInfo = notificationInfo

    privateDatabase?.save(subscription,
                          completionHandler: ({returnRecord, error in
      if let err = error {
        print("Subscription failed %@",
              err.localizedDescription)
      } else {
        DispatchQueue.main.async() {
          self.notifyUser("Success",
                          message: "Subscription set up successfully")
        }
      }
    }))

  }

}

extension ActivityViewController:  UITableViewDataSource, UITableViewDelegate {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return 1
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "ActivityTitleViewCell", for: indexPath)
    cell.textLabel?.text = activityToUpdate?.name
    //    activityTableView.reloadData()
    return cell
  }

}

extension ActivityViewController: UIPickerViewDelegate, UIPickerViewDataSource {

  func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
    MyFunc.logMessage(.debug, "ActivityViewController.didSelectRow: \(row)")
    sportSelected = sportArray[row]

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
