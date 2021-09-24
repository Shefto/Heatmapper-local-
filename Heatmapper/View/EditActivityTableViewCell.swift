//
//  ActivityTableViewCell.swift
//  Heatmapper
//
//  Created by Richard English on 30/08/2021.
//  Copyright © 2021 Richard English. All rights reserved.
//

import UIKit

protocol EditActivityTableViewCellDelegate: AnyObject {

  func updateSportForActivity(newSport: Sport, indexPathRow: Int)

}

class EditActivityTableViewCell: ThemeTableViewCellNoBackground {

  weak var delegate : EditActivityTableViewCellDelegate?

//  @IBOutlet weak var activityLabel: TableRowNameUILabel!
//  @IBOutlet weak var sportPicker: UIPickerView!

  @IBOutlet var activityField: UITextField!

//  var sportArray = [String]()

  override func layoutSubviews() {
    super.layoutSubviews()

    contentView.frame = contentView.frame.inset(by: UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 0))
  }



  override func awakeFromNib() {
    super.awakeFromNib()

//    loadSportItems()
//    sportPicker.delegate = self
//    sportPicker.dataSource = self
  }

//  func numberOfComponents(in pickerView: UIPickerView) -> Int {
//    return 1
//  }
//
//  func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
//      return sportArray.count
//  }
//
//  func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
//      return sportArray[row]
//  }
//
//  func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
//    MyFunc.logMessage(.debug, "ActivityTableViewCell.didSelectRow: \(row)")
//  }
//
//  func loadSportItems() {
//    sportArray = ["Football - 11-a-side", "Football - 5-a-side", "Rugby", "Kabbaddi"]
//
//  }


}
