//
//  IntervalTypeTableViewCell.swift
//  FIT
//
//  Created by Richard English on 30/11/2020.
//  Copyright © 2020 Richard English. All rights reserved.
//

import UIKit

protocol IntervalTypeTableViewCellDelegate: class {
  func durationUpdated(newTimeInterval: TimeInterval, indexPath: IndexPath)

}

class IntervalTypeTableViewCell: ThemeTableViewCellNoBackground, UIPickerViewDelegate, UIPickerViewDataSource {

  weak var delegate: IntervalTypeTableViewCellDelegate?

  var minuteArray                   = [String]()
  var largeMinuteArray              = [String]()
  var secondArray                   = [String]()

  var durationDragStartPosition: CGPoint!
  var durationDragEndPosition: CGPoint!
  var durationOriginalWidth: CGFloat!
  var indexPath: IndexPath?

  @IBOutlet weak var intervalImageView: UIImageView!

  @IBOutlet weak var durationContainerView: ThemeView!
  @IBOutlet weak var durationValueView: UIView!
  @IBOutlet weak var largeMinutePicker: UIPickerView!
  @IBOutlet weak var minutePicker: UIPickerView!
  @IBOutlet weak var secondPicker: UIPickerView!
  @IBOutlet weak var durationWidth: NSLayoutConstraint!
  @IBOutlet weak var totalLabel: ThemeColumnHeaderUILabel!
  @IBOutlet weak var hhMMColon: ThemeColumnHeaderUILabel!
  @IBOutlet weak var mmSSColon: ThemeColumnHeaderUILabel!
  @IBOutlet weak var hourPicker: UIPickerView!

  override func layoutSubviews() {
    super.layoutSubviews()

    contentView.frame = contentView.frame.inset(by: UIEdgeInsets(top: 5, left: 0, bottom: 5, right: 0))
  }

  override func awakeFromNib() {
    super.awakeFromNib()
    totalLabel.isHidden = true
    largeMinutePicker.isHidden = true
    hhMMColon.isHidden = true
    hourPicker.isHidden = true

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
    let recognizer = UIPanGestureRecognizer(target: self, action: #selector(panDuration(sender:)))
    recognizer.delegate = self
    durationContainerView.addGestureRecognizer(recognizer)
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
    MyFunc.logMessage(.debug, "didSelectRow: \(row)")
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

  //  @IBAction func panDuration(_ sender: UIPanGestureRecognizer) {
  @objc func panDuration(sender: UIPanGestureRecognizer) {
    if sender.state == .began {
      durationOriginalWidth = durationValueView.bounds.width
      durationDragStartPosition = sender.location(in: self.contentView)

    }

    if sender.state == .changed {
      // get final co-ordinates
      durationDragEndPosition = sender.location(in: self.contentView)

      let difference = durationDragEndPosition.x - durationDragStartPosition.x
      var newWidth = durationOriginalWidth + difference

      if newWidth >= durationContainerView.bounds.width {
        newWidth = durationContainerView.bounds.width
      }
      let newWidthFloat = CGFloat(newWidth)
      durationWidth.constant = newWidthFloat

      if delegate != nil && durationWidth != nil {
        // notify the delegate (e.g. parent VC) of the new width together with the indexPath
        let durationScale = Float(durationValueView.bounds.width / durationContainerView.bounds.width)
        let durationTimeInterval = MyFunc.getTimeIntervalFromScale(scale: durationScale, stride: 5, sliderSize: 300)
        delegate!.durationUpdated(newTimeInterval: durationTimeInterval, indexPath: indexPath!)
      }

    }
    if sender.state == .ended {
      if delegate != nil && durationWidth != nil {
        // notify the delegate (e.g. parent VC) of the new width together with the indexPath
        let durationScale = Float(durationValueView.bounds.width / durationContainerView.bounds.width)
        let durationTimeInterval = MyFunc.getTimeIntervalFromScale(scale: durationScale, stride: 5, sliderSize: 300)
        delegate!.durationUpdated(newTimeInterval: durationTimeInterval, indexPath: indexPath!)
      }

    }

  }

  func reloadPickers() {
    minutePicker.reloadAllComponents()
    secondPicker.reloadAllComponents()
    largeMinutePicker.reloadAllComponents()
    hourPicker.reloadAllComponents()

  }

}
