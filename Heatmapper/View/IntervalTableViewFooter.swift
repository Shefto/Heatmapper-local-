//
//  IntervalFooterView.swift
//  FIT
//
//  Created by Richard English on 17/12/2020.
//  Copyright © 2020 Richard English. All rights reserved.
//

import UIKit

class IntervalTableViewFooter: UITableViewHeaderFooterView, UIPickerViewDelegate, UIPickerViewDataSource {

  static let reuseIdentifier: String = String(describing: self)

  static var nib: UINib {
    return UINib(nibName: String(describing: self), bundle: nil)

  }

  var minuteArray                   = [String]()
  var largeMinuteArray              = [String]()
  var secondArray                   = [String]()

  var durationDragStartPosition: CGPoint!
  var durationDragEndPosition: CGPoint!
  var durationOriginalWidth: CGFloat!
  var indexPath: IndexPath?

  @IBOutlet weak var largeMinutePicker: UIPickerView!
  @IBOutlet weak var minutePicker: UIPickerView!
  @IBOutlet weak var secondPicker: UIPickerView!

  @IBOutlet weak var totalLabel: ThemeColumnHeaderUILabel!
  @IBOutlet weak var hhMMColon: ThemeColumnHeaderUILabel!
  @IBOutlet weak var mmSSColon: ThemeColumnHeaderUILabel!
  @IBOutlet weak var hourPicker: UIPickerView!

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }

  override init(reuseIdentifier: String?) {
    super.init(reuseIdentifier: reuseIdentifier)
    loadUI()
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    contentView.frame = contentView.frame.inset(by: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0))
  }

  func loadUI() {

    loadMinuteItems()
    loadSecondItems()
    loadLargeMinuteItems()
    self.largeMinutePicker.dataSource = self
    self.largeMinutePicker.delegate = self
    self.hourPicker.dataSource = self
    self.hourPicker.delegate = self
    self.minutePicker.dataSource = self
    self.minutePicker.delegate = self
    self.secondPicker.dataSource = self
    self.secondPicker.delegate = self

  }

  func numberOfComponents(in pickerView: UIPickerView) -> Int {
    return 1
  }

  func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
    switch pickerView.tag {
    case 1:
      return minuteArray.count
    case 2:
      return secondArray.count
    default:
      return largeMinuteArray.count
    }

  }

  func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {

    switch pickerView.tag {
    case 1:
      return minuteArray[row]
    case 2:
      return secondArray[row]
    default:
      return largeMinuteArray[row]
    }

  }

  func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {

  }

  func loadMinuteItems() {
    for minute in 0...5 {
      let itemStr = String(minute)
      minuteArray.append(itemStr)
    }
  }

  func loadLargeMinuteItems() {
    for minute in 0...60 {
      let itemStr = String(minute)
      largeMinuteArray.append(itemStr)
    }
  }

  func loadSecondItems() {
    for second in stride(from: 0, through: 55, by: 5) {
      var itemStr = String(second)

      if itemStr == "0" {
        itemStr = "00"
      }

      if itemStr == "5" {
        itemStr = "05"
      }
      secondArray.append(itemStr)
    }
  }
 
  func reloadPickers() {
    minutePicker.reloadAllComponents()
    secondPicker.reloadAllComponents()
    largeMinutePicker.reloadAllComponents()
    hourPicker.reloadAllComponents()

  }

}
