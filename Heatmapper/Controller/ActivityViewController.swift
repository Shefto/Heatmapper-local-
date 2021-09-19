//
//  ActivityViewController.swift
//  Heatmapper
//
//  Created by Richard English on 18/09/2021.
//  Copyright © 2021 Richard English. All rights reserved.
//

import UIKit

class ActivityViewController: UIViewController {

  let theme = ColourTheme()
  let defaults = UserDefaults.standard
  var activityToUpdate : Activity?
  private var activityArray = [Activity]()
  var activityToUpdateRow : Int?
  var sportArray = [Sport]()

  @IBOutlet weak var saveButton: UIBarButtonItem!

  @IBOutlet weak var activityNameField: UITextField!
  @IBOutlet weak var sportPicker: UIPickerView!


    override func viewDidLoad() {
      super.viewDidLoad()
      saveButton.isEnabled = false
      sportPicker.dataSource = self
      sportPicker.delegate = self
      getData()
      updateUI()
    }

  func getData() {
    activityArray = MyFunc.getHeatmapperActivityDefaults()
    activityToUpdateRow = activityArray.firstIndex(where: { $0 == activityToUpdate  })
    sportArray = Sport.allCases.map { $0 }
  }

  func updateUI() {
    activityNameField.text = activityToUpdate?.name
    let activitySportRow : Int = sportArray.firstIndex(where: { $0 == activityToUpdate!.sport  }) ?? 0
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

    guard let activityToUpdateRowUnwrapped = activityToUpdateRow else {
      MyFunc.logMessage(.error, "ActivityViewController: activityToUpdateRow empty")
      return
    }

    activityArray[activityToUpdateRowUnwrapped].name = activityNameField.text ?? ""
    MyFunc.saveHeatmapActivityDefaults(activityArray)
    MyFunc.logMessage(.debug, "updates Saved called")
  }

  @IBAction func activityNameEditingDidBegin(_ sender: Any) {
    MyFunc.logMessage(.debug, "activityNameEditingDidBegin called")
    saveButton.isEnabled = true
  }

  @IBAction func activityNameEditingDidEnd(_ sender: Any) {
    MyFunc.logMessage(.debug, "activityNameEditingDidEnd called")
    guard let activityToUpdateRowUnwrapped = activityToUpdateRow else {
      MyFunc.logMessage(.error, "ActivityViewController: activityToUpdateRow empty")
      return
    }

    activityArray[activityToUpdateRowUnwrapped].name = activityNameField.text ?? ""


  }

  @IBAction func activityNameDidEndOnExit(_ sender: Any) {
    MyFunc.logMessage(.debug, "activityNameDidEndOnExit called")
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
    let sportSelected = sportArray[row]

    guard let activityToUpdateRowUnwrapped = activityToUpdateRow else {
      MyFunc.logMessage(.error, "ActivityViewController: activityToUpdateRow empty")
      return
    }
    activityArray[activityToUpdateRowUnwrapped].sport = sportSelected
//    MyFunc.saveHeatmapActivityDefaults(activityArray)



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
