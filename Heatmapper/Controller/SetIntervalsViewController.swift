//
//  SetIntervalsViewController.swift
//  FIT
//
//  Created by Richard English on 22/11/2020.
//  Copyright © 2020 Richard English. All rights reserved.
//

import UIKit
import WatchConnectivity

class SetIntervalsViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UITableViewDataSource, UITableViewDelegate, IntervalTypeTableViewCellDelegate, SessionCommands {

  let theme                       = ColourTheme()
  let screenSize: CGRect = UIScreen.main.bounds
  let workColour                  = UIColor.systemRed
  let restColour                  = UIColor.systemOrange
  var warmupCooldownColour        = UIColor.systemGreen

  var activityType                = ActivityType()
  var activityTemplate            = ActivityTemplate()
  var intervalTemplateArray: [IntervalTemplate] = []

  var secondStride: Int = 5
  let sliderSizeInSeconds: Float = 300
  var difficultyArray             = [String]()
  var minuteArray                 = [String]()
  var largeMinuteArray            = [String]()
  var secondArray                 = [String]()
  var patternArray                = [String]()
  var isTotalDurationRow: Bool = false

  var warmupDragStartPosition: CGPoint!
  var warmupDragEndPosition: CGPoint!
  var warmupOriginalWidth: CGFloat!

  var workDragStartPosition: CGPoint!
  var workDragEndPosition: CGPoint!
  var workOriginalWidth: CGFloat!

  var restDragStartPosition: CGPoint!
  var restDragEndPosition: CGPoint!
  var restOriginalWidth: CGFloat!

  var cooldownDragStartPosition: CGPoint!
  var cooldownDragEndPosition: CGPoint!
  var cooldownOriginalWidth: CGFloat!

  var selectedItemForRowMinutes: [Int] = [Int]()
  var selectedItemForRowSeconds: [Int] = [Int]()

  @IBOutlet weak var settingsRoutineTabView: UIView!
  @IBOutlet weak var settingsRoutineStackView: UIStackView!
  @IBOutlet weak var settingsButton: UIButton!
  @IBOutlet weak var routineButton: UIButton!

  @IBOutlet weak var setsStepper: UIStepper!

  @IBOutlet weak var warmupContainerView: UIView!
  @IBOutlet weak var warmupDurationView: UIView!

  @IBOutlet weak var warmupLabel: TableRowNameUILabel!
  @IBOutlet weak var warmupViewWidth: NSLayoutConstraint!
  @IBOutlet weak var warmupIconView: UIImageView!
  @IBOutlet weak var warmupMinutePicker: UIPickerView!
  @IBOutlet weak var warmupSecondPicker: UIPickerView!

  @IBOutlet weak var workLabel: TableRowNameUILabel!
  @IBOutlet weak var workContainerView: ThemeView!
  @IBOutlet weak var workDurationView: UIView!
  @IBOutlet weak var workViewWidth: NSLayoutConstraint!
  @IBOutlet weak var workIconView: UIImageView!
  @IBOutlet weak var workMinutePicker: UIPickerView!
  @IBOutlet weak var workSecondPicker: UIPickerView!

  @IBOutlet weak var restLabel: TableRowNameUILabel!
  @IBOutlet weak var restStackView: UIStackView!
  @IBOutlet weak var restContainerView: ThemeView!
  @IBOutlet weak var restDurationView: UIView!
  @IBOutlet weak var restViewWidth: NSLayoutConstraint!
  @IBOutlet weak var restIconView: UIImageView!
  @IBOutlet weak var restMinutePicker: UIPickerView!
  @IBOutlet weak var restSecondPicker: UIPickerView!
  @IBOutlet weak var restPickerStackView: UIStackView!

  @IBOutlet weak var cooldownLabel: TableRowNameUILabel!
  @IBOutlet weak var cooldownDurationView: UIView!
  @IBOutlet weak var cooldownContainerView: ThemeView!
  @IBOutlet weak var cooldownViewWidth: NSLayoutConstraint!
  @IBOutlet weak var cooldownIconView: UIImageView!
  @IBOutlet weak var cooldownMinutePicker: UIPickerView!
  @IBOutlet weak var cooldownSecondPicker: UIPickerView!

  @IBOutlet weak var setsValue: ThemeLargeNumericUILabel!
  @IBOutlet weak var setsLabel: TableRowNameUILabel!
  @IBOutlet weak var setsIconView: UIImageView!

  @IBOutlet weak var difficultyLabel: TableRowNameUILabel!
  @IBOutlet weak var difficultyPicker: UIPickerView!
  @IBOutlet weak var difficultyStackView: UIStackView!
  @IBOutlet weak var difficultyIconView: UIImageView!

  @IBOutlet weak var patternLabel: TableRowNameUILabel!
  @IBOutlet weak var patternPicker: UIPickerView!
  @IBOutlet weak var patternStackView: UIStackView!
  @IBOutlet weak var patternIconView: UIImageView!

  @IBOutlet weak var intervalTableView: ThemeTableViewNoBackground!
  @IBOutlet weak var settingsStackView: UIStackView!

  override func viewDidLoad() {
    super.viewDidLoad()
    warmupCooldownColour = theme.textAlternate
    intervalTableView.delegate = self
    intervalTableView.dataSource = self
    self.intervalTableView.register(UINib(nibName: "IntervalTypeTableViewCell", bundle: nil), forCellReuseIdentifier: "IntervalTypeTableViewCell")
    self.intervalTableView.register(IntervalTableViewFooter.nib, forHeaderFooterViewReuseIdentifier: IntervalTableViewFooter.reuseIdentifier)

    // get defaults for Activity Type passed in
    activityTemplate = MyFunc.getActivityDefaults(activityType)
    MyFunc.logMessage(.debug, "activityTemplate: \(activityTemplate)")

    loadIntervalTemplateArray()
    loadUI()

  }

  override func viewDidLayoutSubviews() {
    // rounding has to be applied here or autolayout shifts the buttons
    settingsButton.roundCorners(corners: [.topLeft, .topRight], radius: 6)
    routineButton.roundCorners(corners: [.topLeft, .topRight], radius: 6)

    // similarly need the subviews laid out before we can calculate the width of the duration views
    warmupViewWidth.constant = getWidthFromValue(activityTemplate.warmup.duration, warmupContainerView.bounds.width)
    workViewWidth.constant = getWidthFromValue(activityTemplate.work.duration, workContainerView.bounds.width)
    restViewWidth.constant = getWidthFromValue(activityTemplate.rest.duration, restContainerView.bounds.width)
    cooldownViewWidth.constant = getWidthFromValue(activityTemplate.cooldown.duration, cooldownContainerView.bounds.width)



  }
  func loadUI() {

    loadMinuteItems()
    loadSecondItems()
    loadLargeMinuteItems()

    // these arrays keep track of the indexPaths for the UIPickers for each row
    // the lines below populate them by assigning a 0 for each row in the Interval Template array
    selectedItemForRowMinutes = intervalTemplateArray.map { _ in return 0}
    selectedItemForRowSeconds = intervalTemplateArray.map { _ in return 0}

    self.title = NSLocalizedString("\(activityType.rawValue)", comment: "title")

    	intervalTableView.isHidden = true

    settingsButton.backgroundColor = theme.background
    routineButton.backgroundColor = theme.backgroundWithAlpha

    warmupMinutePicker.delegate = self
    warmupMinutePicker.dataSource = self
    warmupSecondPicker.delegate = self
    warmupSecondPicker.dataSource = self
    restMinutePicker.delegate = self
    restMinutePicker.dataSource = self
    restSecondPicker.delegate = self
    restSecondPicker.dataSource = self
    workMinutePicker.delegate = self
    workMinutePicker.dataSource = self
    workSecondPicker.delegate = self
    workSecondPicker.dataSource = self
    cooldownMinutePicker.delegate = self
    cooldownMinutePicker.dataSource = self
    cooldownSecondPicker.delegate = self
    cooldownSecondPicker.dataSource = self

    workLabel.text = NSLocalizedString("Work", comment: "Work")
    restLabel.text = NSLocalizedString("Rest", comment: "Rest")

    switch activityType {
    case .pyramid:
      workLabel.text = NSLocalizedString("Work (max)", comment: "Work (max)")
      restLabel.text = NSLocalizedString("Rest (max)", comment: "Rest (max)")
      difficultyStackView.isHidden = true
      difficultyLabel.isHidden = true
      patternStackView.isHidden = true
      patternLabel.isHidden = true

    case .random:
      // set up the Difficulty picker
      difficultyStackView.isHidden = false
      difficultyPicker.delegate = self
      difficultyPicker.dataSource = self

      difficultyArray = ActivityLevel.allCases.map { $0.rawValue }
      let difficultyDefault: Int = difficultyArray.firstIndex(where: { $0.description == activityTemplate.activityLevel!.rawValue  }) ?? 0
      difficultyPicker.selectRow(difficultyDefault, inComponent: 0, animated: false)
      difficultyIconView.image = difficultyIconView.image?.withRenderingMode(.alwaysTemplate)
      difficultyIconView.tintColor = theme.textAlternate

      // hide pattern and rest selectors
      patternStackView.isHidden = true
      patternLabel.isHidden = true
      restStackView.isHidden = true
      restLabel.isHidden = true

      workLabel.text = NSLocalizedString("Activity (Work + Rest)", comment: "Activity (Work + Rest)")

    case .custom:
      patternStackView.isHidden = false
      patternIconView.tintColor = theme.textAlternate
      patternPicker.delegate = self
      patternPicker.dataSource = self
      patternArray = ActivityPattern.allCases.map { $0.rawValue}
      let patternDefault: Int = patternArray.firstIndex(where: { $0.description == activityTemplate.activityPattern!.rawValue  }) ?? 0
      patternPicker.selectRow(patternDefault, inComponent: 0, animated: false)
      difficultyLabel.isHidden = true
      difficultyStackView.isHidden = true
      if activityTemplate.customIntervals == true {
        let resetString = NSLocalizedString("Reset", comment: "Reset")
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: resetString, style: .plain, target: self, action: #selector(resetIntervals))
      }

    case .tabata:
      difficultyStackView.isHidden = true
      difficultyLabel.isHidden = true
      patternStackView.isHidden = true
      patternLabel.isHidden = true
      workMinutePicker.isUserInteractionEnabled = false
      workSecondPicker.isUserInteractionEnabled = false
      workContainerView.isUserInteractionEnabled = false
      restMinutePicker.isUserInteractionEnabled = false
      restSecondPicker.isUserInteractionEnabled = false
      restContainerView.isUserInteractionEnabled = false

    default:
      difficultyStackView.isHidden = true
      difficultyLabel.isHidden = true
      patternStackView.isHidden = true
      patternLabel.isHidden = true
    }

//    warmupViewWidth.constant = getWidthFromValue(activityTemplate.warmup.duration, warmupContainerView.bounds.width)
    warmupIconView.image = warmupIconView.image?.withRenderingMode(.alwaysTemplate)
    warmupIconView.tintColor = warmupCooldownColour
    warmupDurationView.backgroundColor = warmupCooldownColour
    updateWarmupPickers()

//    workViewWidth.constant = getWidthFromValue(activityTemplate.work.duration, workContainerView.bounds.width)
    workIconView.image = workIconView.image?.withRenderingMode(.alwaysTemplate)
    workIconView.tintColor = workColour
    workDurationView.backgroundColor = workColour
    workLabel.textColor = workColour
    updateWorkPickers()


//    restViewWidth.constant = getWidthFromValue(activityTemplate.rest.duration, restContainerView.bounds.width)
    restIconView.image = restIconView.image?.withRenderingMode(.alwaysTemplate)
    restIconView.tintColor = restColour
    restDurationView.backgroundColor = restColour
    restLabel.textColor = restColour
    updateRestPickers()

//    cooldownViewWidth.constant = getWidthFromValue(activityTemplate.cooldown.duration, cooldownContainerView.bounds.width)
    cooldownIconView.image = cooldownIconView.image?.withRenderingMode(.alwaysTemplate)
    cooldownIconView.tintColor = warmupCooldownColour
    cooldownDurationView.backgroundColor = warmupCooldownColour
    updateCooldownPickers()

    setsStepper.transform = setsStepper.transform.scaledBy(x: 1, y: 1.25)
    setsStepper.value = Double(activityTemplate.sets)
    setsValue.text = String(describing: activityTemplate.sets)

    setsIconView.image = setsIconView.image?.withRenderingMode(.alwaysTemplate)
    setsIconView.tintColor = theme.textAlternate

    // remove translucent effect on Pickers
    if #available(iOS 14.0, *) {
      warmupMinutePicker.subviews[1].backgroundColor = .clear
      warmupSecondPicker.subviews[1].backgroundColor = .clear
      workMinutePicker.subviews[1].backgroundColor = .clear
      workSecondPicker.subviews[1].backgroundColor = .clear
      restMinutePicker.subviews[1].backgroundColor = .clear
      restSecondPicker.subviews[1].backgroundColor = .clear
      cooldownMinutePicker.subviews[1].backgroundColor = .clear
      cooldownSecondPicker.subviews[1].backgroundColor = .clear
      if difficultyStackView.isHidden == false {
        difficultyPicker.subviews[1].backgroundColor = .clear
      }
      if patternStackView.isHidden == false {
        patternPicker.subviews[1].backgroundColor = .clear
      }
    }
    let pickerColour: UIColor = theme.textPrimary
    warmupMinutePicker.setValue(pickerColour, forKey: "textColor")
    warmupSecondPicker.setValue(pickerColour, forKey: "textColor")
    workMinutePicker.setValue(pickerColour, forKey: "textColor")
    workSecondPicker.setValue(pickerColour, forKey: "textColor")
    restMinutePicker.setValue(pickerColour, forKey: "textColor")
    restSecondPicker.setValue(pickerColour, forKey: "textColor")
    cooldownMinutePicker.setValue(pickerColour, forKey: "textColor")
    cooldownSecondPicker.setValue(pickerColour, forKey: "textColor")
    if patternStackView.isHidden == false {
      patternPicker.setValue(pickerColour, forKey: "textColor")
    }
    if difficultyStackView.isHidden == false {
      difficultyPicker.setValue(pickerColour, forKey: "textColor")
    }

  }

  @IBAction func btnSettings(_ sender: Any) {

    settingsButton.backgroundColor = theme.background
    routineButton.backgroundColor = theme.backgroundWithAlpha
    settingsStackView.isHidden = false
    intervalTableView.isHidden = true

  }

  @IBAction func btnRoutine(_ sender: Any) {

    settingsButton.backgroundColor = theme.backgroundWithAlpha
    routineButton.backgroundColor = theme.background
    refreshIntervals()
    settingsStackView.isHidden = true
    intervalTableView.isHidden = false

  }

  func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
    return true
  }

  @objc func resetIntervals() {
    let resetMessage = NSLocalizedString("This will override any custom intervals you have created. Do you want to continue?", comment: "This will override any custom intervals you have created. Do you want to continue?")
    let resetTitle = NSLocalizedString("Reset Intervals", comment: "Reset Intervals")
    displayAlert(title: resetTitle, message: resetMessage)
  }

  @IBAction func panWork(_ sender: UIPanGestureRecognizer) {
    if activityType == .tabata {
      return
    }

    if sender.state == .began {
      workOriginalWidth = workDurationView.bounds.width
      workDragStartPosition = sender.location(in: self.view)
    }

    if sender.state == .changed {
      workDragEndPosition = sender.location(in: self.view)
      let difference = workDragEndPosition.x - workDragStartPosition.x
      var newWidth = workOriginalWidth + difference
      if newWidth <= workContainerView.bounds.width + 40 {
        if newWidth > workContainerView.bounds.width {
          newWidth = workContainerView.bounds.width
        }
        workViewWidth.constant = CGFloat(newWidth)
      }
      let workScale = Float(workDurationView.bounds.width / workContainerView.bounds.width)
      let workTimeInterval = getTimeIntervalFromScale(workScale)

      activityTemplate.work.duration = workTimeInterval

      saveIntervals()
      updateWorkPickers()
    }
  }

  @IBAction func panWarmup(_ sender: UIPanGestureRecognizer) {
    if sender.state == .began {
      warmupOriginalWidth = warmupDurationView.bounds.width
      warmupDragStartPosition = sender.location(in: self.view)
    }

    if sender.state == .changed {
      warmupDragEndPosition = sender.location(in: self.view)
      let difference = warmupDragEndPosition.x - warmupDragStartPosition.x
      var newWidth = warmupOriginalWidth + difference

      if newWidth >= warmupContainerView.bounds.width {
        newWidth = warmupContainerView.bounds.width
      }
      warmupViewWidth.constant = CGFloat(newWidth)

      let warmupScale = Float(warmupDurationView.bounds.width / warmupContainerView.bounds.width)
      let warmupTimeInterval = getTimeIntervalFromScale(warmupScale)

      activityTemplate.warmup.duration = warmupTimeInterval

      saveIntervals()
      updateWarmupPickers()
    }
  }

  @IBAction func panRest(_ sender: UIPanGestureRecognizer) {

    if activityType == .tabata {
      return
    }

    if sender.state == .began {
      restOriginalWidth = restDurationView.bounds.width
      restDragStartPosition = sender.location(in: self.view)
    }

    if sender.state == .changed {
      restDragEndPosition = sender.location(in: self.view)
      let difference = restDragEndPosition.x - restDragStartPosition.x
      var newWidth = restOriginalWidth + difference
      if newWidth <= restContainerView.bounds.width + 40 {
        if newWidth > restContainerView.bounds.width {
          newWidth = restContainerView.bounds.width
        }
        restViewWidth.constant = CGFloat(newWidth)
      }
      let restScale = Float(restDurationView.bounds.width / restContainerView.bounds.width)
      let restTimeInterval = getTimeIntervalFromScale(restScale)

      activityTemplate.rest.duration = restTimeInterval

      saveIntervals()
      updateRestPickers()
    }
  }

  @IBAction func panCooldown(_ sender: UIPanGestureRecognizer) {
    if sender.state == .began {
      cooldownOriginalWidth = cooldownDurationView.bounds.width
      cooldownDragStartPosition = sender.location(in: self.view)
    }

    if sender.state == .changed {
      cooldownDragEndPosition = sender.location(in: self.view)
      let difference = cooldownDragEndPosition.x - cooldownDragStartPosition.x
      var newWidth = cooldownOriginalWidth + difference
      if newWidth <= cooldownContainerView.bounds.width + 40 {
        if newWidth > cooldownContainerView.bounds.width {
          newWidth = cooldownContainerView.bounds.width
        }
        cooldownViewWidth.constant = CGFloat(newWidth)
      }
      let cooldownScale = Float(cooldownDurationView.bounds.width / cooldownContainerView.bounds.width)
      let cooldownTimeInterval = getTimeIntervalFromScale(cooldownScale)

      activityTemplate.cooldown.duration = cooldownTimeInterval

      saveIntervals()
      updateCooldownPickers()
    }
  }

  @IBAction func stepperSets(_ sender: UIStepper) {
    let setsPickedInt = Int(sender.value)

    if activityType == .custom {
      // calculate the new total of Intervals
      // each workout has 2 intervals per set (work, rest) minus a final rest, plus a warmup and a cooldown

      if setsPickedInt > activityTemplate.sets {
        let workInterval = IntervalTemplate(activityType: .work, duration: activityTemplate.work.duration)
        let restInterval = IntervalTemplate(activityType: .rest, duration: activityTemplate.rest.duration)
        // new intervals go before the cooldown
        let insertionPoint = intervalTemplateArray.count - 2
        intervalTemplateArray.insert(restInterval, at: insertionPoint)
        intervalTemplateArray.insert(workInterval, at: insertionPoint)
      } else {
        // likewise, don't remove the cooldown!
        let deletionPoint = intervalTemplateArray.count - 3
        intervalTemplateArray.remove(at: deletionPoint)
        intervalTemplateArray.remove(at: deletionPoint)
      }
      activityTemplate.intervals.removeAll()
      activityTemplate.intervals = intervalTemplateArray
      saveIntervals()

      refreshIntervals()

    }

    setsValue.text = String(setsPickedInt)
    // update defaults
    activityTemplate.sets = setsPickedInt

    MyFunc.saveActivityDefaults(activityTemplate)
    // update intervals array if sets changed for custom sets

    saveIntervals()

  }

  func numberOfComponents(in pickerView: UIPickerView) -> Int {
    return 1
  }

  func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
    var countToReturn: Int = 0
    switch pickerView.tag {
    case 0:
      countToReturn = ActivityLevel.allCases.count
    case 99:
      countToReturn = ActivityPattern.allCases.count
    case 3, 4:
      countToReturn = largeMinuteArray.count
    case 1, 11, 21, 31, 41:
      countToReturn = minuteArray.count
    case 2, 12, 22, 32, 42:
      countToReturn = secondArray.count

    default:
      MyFunc.logMessage(.error, "Invalid pickerView.tag: \(String(describing: pickerView.tag))")
      countToReturn = 0
    }
    return countToReturn
  }

  func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
    var titleToReturn: String = ""
    switch pickerView.tag {
    // difficulty Picker
    case 0:
      let localizedLevel = NSLocalizedString("\(ActivityLevel.allCases[row].localizedDescription)", comment: "Localized raw value")
      titleToReturn =  localizedLevel
    case 99:
      let localizedPattern = NSLocalizedString("\(ActivityPattern.allCases[row].localizedDescription)", comment: "Localized raw value")
      titleToReturn =  localizedPattern
    case 3, 4:
      titleToReturn = largeMinuteArray[row]
    case 1, 11, 21, 31, 41:
      titleToReturn = minuteArray[row]
    case 2, 12, 22, 32, 42:
      titleToReturn = secondArray[row]
    default:
      MyFunc.logMessage(.error, "Invalid pickerView.tag: \(String(describing: pickerView.tag))")
      titleToReturn = "No title"
    }
    return titleToReturn

  }

  func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {

    switch pickerView.tag {

    // difficulty Picker
    case 0:
     
      activityTemplate.activityLevel = ActivityLevel(rawValue: difficultyArray[row])
      MyFunc.saveActivityDefaults(activityTemplate)
      saveIntervals()
      return

    // pattern Picker
    case 99:
      activityTemplate.activityPattern = ActivityPattern(rawValue: patternArray[row])
      MyFunc.saveActivityDefaults(activityTemplate)
      saveIntervals()
      return

    // intervalTableViewCell minute Picker
    case 1:

      let tableViewCell = pickerView.superview?.superview?.superview as! UITableViewCell
      guard let tableIndexPath = self.intervalTableView.indexPath(for: tableViewCell) else {
        MyFunc.logMessage(.error, "Invalid or missing indexPath for tableViewCell")
        return
      }

      // update array of indexPaths
      self.selectedItemForRowMinutes[tableIndexPath.row] = row

      // populate the minute and second values for updating the duration
      let minuteStr = minuteArray[row]

      var secondRow: Int = 0
      // check the minutes are not at the maximum - if so set the seconds to 0
      // add 1 to row as start is 0
      if (row + 1) == minuteArray.count {
        secondRow = secondArray.firstIndex(where: { $0.description == "00" }) ?? 0
      } else {
        secondRow = selectedItemForRowSeconds[tableIndexPath.row]
      }

      let secondStr = secondArray[secondRow]

      // update the duration
      let newTimeInterval = getTimeIntervalFromPickers(minute: minuteStr, second: secondStr)
      durationUpdated(newTimeInterval: newTimeInterval, indexPath: tableIndexPath)

    case 2:
      let tableViewCell = pickerView.superview?.superview?.superview as! UITableViewCell
      guard let tableIndexPath = self.intervalTableView.indexPath(for: tableViewCell) else {
        MyFunc.logMessage(.error, "Invalid or missing indexPath for tableViewCell")
        return
      }

      self.selectedItemForRowSeconds[tableIndexPath.row] = row

      // populate the minute and second values for updating the duration
      let minuteRow = selectedItemForRowMinutes[tableIndexPath.row]
      let minuteStr = minuteArray[minuteRow]
      var secondStr = ""
      // check the minutes are not at the maximum - if so set the seconds to 00
      // add 1 to row as start is 0
      if (minuteRow + 1) == minuteArray.count {
        secondStr = "00"
      } else {
        secondStr = secondArray[row]
      }

      // update the duration
      let newTimeInterval = getTimeIntervalFromPickers(minute: minuteStr, second: secondStr)

      // update the ActivityTemplate and save this to the defaults
      durationUpdated(newTimeInterval: newTimeInterval, indexPath: tableIndexPath)
//

    case 11, 21, 31, 41:

      var intervalTemplateForUpdate = getIntervalTemplateForPicker(pickerTag: pickerView.tag)
      // flag to note if the seconds need a refresh in the event of a minute updating affecting them (i.e. set seconds to zero when at max minutes)
      var secondsNeedRefresh: Bool = false
      let minuteStr = minuteArray[row]

      var secondStr = ""
      let durationTimeInterval = intervalTemplateForUpdate.duration

      // check the minutes are not at the maximum - if so set the seconds to 0
      // add 1 to row as start is 0

      if (row + 1) == minuteArray.count {
        secondStr = "00"
        secondsNeedRefresh = true
      } else {
        secondStr = durationTimeInterval.toSeconds(secondStride)
      }

      let newTimeInterval = getTimeIntervalFromPickers(minute: minuteStr, second: secondStr)
      intervalTemplateForUpdate.duration = newTimeInterval

      // update the ActivityTemplate and save this to the defaults
      let updatedActivityTemplate = setIntervalTemplateForType(intervalTemplateForUpdate, activityTemplate)
      MyFunc.saveActivityDefaults(updatedActivityTemplate)
      activityTemplate = updatedActivityTemplate
      updateDurationView(intervalType: intervalTemplateForUpdate.intervalType)
      saveIntervals()

      if secondsNeedRefresh == true {
        switch pickerView.tag {
        case 11:
          updateWarmupPickers()
        case 21:
          updateWorkPickers()
        case 31:
          updateRestPickers()
        case 41:
          updateCooldownPickers()
        default:
          ()
        }
      }

    case 12, 22, 32, 42:
      var intervalTemplateForUpdate = getIntervalTemplateForPicker(pickerTag: pickerView.tag)
      var secondsNeedRefresh: Bool = false

      var secondStr: String = ""

      let durationTimeInterval = intervalTemplateForUpdate.duration
      let minuteStr = durationTimeInterval.toMinutes()

      let minutesIndex: Int = minuteArray.firstIndex(where: { $0.description == minuteStr }) ?? 0

      // check the minutes are not at the maximum - if so set the seconds to 00
      // add 1 to row as start is 0
      if (minutesIndex + 1) == minuteArray.count {
        secondStr = "00"
        secondsNeedRefresh = true
      } else {
        secondStr = secondArray[row]
      }

      let newTimeInterval = getTimeIntervalFromPickers(minute: minuteStr, second: secondStr)
      intervalTemplateForUpdate.duration = newTimeInterval

      // update the ActivityTemplate and save this to the defaults
      let updatedActivityTemplate = setIntervalTemplateForType(intervalTemplateForUpdate, activityTemplate)
      MyFunc.saveActivityDefaults(updatedActivityTemplate)
      activityTemplate = updatedActivityTemplate
      updateDurationView(intervalType: intervalTemplateForUpdate.intervalType)
      saveIntervals()

      if secondsNeedRefresh == true {
        switch pickerView.tag {
        case 12:
          updateWarmupPickers()
        case 22:
          updateWorkPickers()
        case 32:
          updateRestPickers()
        case 42:
          updateCooldownPickers()
        default:
          ()
        }
      }

    default:
      return
    }
  }

  func durationUpdated(newTimeInterval: TimeInterval, indexPath: IndexPath) {

    // this is invoked when a custom interval update is made so set flag to note custom intervals have been created
    activityTemplate.customIntervals = true
    let resetString = NSLocalizedString("Reset", comment: "Reset")
    navigationItem.rightBarButtonItem = UIBarButtonItem(title: resetString, style: .plain, target: self, action: #selector(resetIntervals))

    // update the duration for the interval
    intervalTemplateArray[indexPath.row].duration = newTimeInterval

    // save the Interval Template Array to the Activity Template for the Custom intervals Activity Type
    activityTemplate.intervals.removeAll()
    activityTemplate.intervals = intervalTemplateArray

    MyFunc.saveActivityDefaults(activityTemplate)
    // had added main queue use to attempt to resolve comms issues - removing to see if this affects buffer delay
    //    DispatchQueue.main.async {
      self.updateApplicationContextForActivityTemplate(activityTemplate: self.activityTemplate)
//    }
    UIView.setAnimationsEnabled(false)
//    intervalTableView.reloadData()
    intervalTableView.beginUpdates()

    self.intervalTableView.reloadRows(at: [indexPath], with: .none)
    let footerView = intervalTableView.footerView(forSection: 0) as! IntervalTableViewFooter

    var totalIntervalTime           = [Double]()
    var durationTotal: Double = 0

    // to get the workout duration, get the full TimeInterval since the workout started
    totalIntervalTime = intervalTemplateArray.map({$0.duration})

    // sum the total
    durationTotal = totalIntervalTime.reduce(0, {$0 + $1})
    MyFunc.logMessage(.debug, String(describing: durationTotal))
    let durationMinutes   = durationTotal.toMinutes()
    let durationSeconds = durationTotal.toSeconds(secondStride)

    if durationTotal >= 3600 {
      let durationHours = durationTotal.toHours()
      footerView.hourPicker.isHidden = false
      footerView.hhMMColon.isHidden = false
      let hoursIndex: Int = largeMinuteArray.firstIndex(where: { $0.description == durationHours }) ?? 0
      footerView.hourPicker.selectRow(hoursIndex, inComponent: 0, animated: false)
      footerView.hourPicker.reloadAllComponents()
      footerView.hourPicker.subviews[1].backgroundColor = .clear
    } else {
      footerView.hourPicker.isHidden = true
      footerView.hhMMColon.isHidden = true
    }

    footerView.largeMinutePicker.delegate = self
    footerView.largeMinutePicker.reloadAllComponents()
    let minutesIndex: Int = largeMinuteArray.firstIndex(where: { $0.description == durationMinutes }) ?? 0
    footerView.largeMinutePicker.selectRow(minutesIndex, inComponent: 0, animated: false)

    footerView.secondPicker.delegate = self
    let secondsIndex: Int = secondArray.firstIndex(where: { $0.description == durationSeconds }) ?? 0
    footerView.secondPicker.selectRow(secondsIndex, inComponent: 0, animated: false)

    footerView.largeMinutePicker.isUserInteractionEnabled = false
    footerView.secondPicker.isUserInteractionEnabled = false

    footerView.secondPicker.subviews[1].backgroundColor = .clear
    footerView.largeMinutePicker.subviews[1].backgroundColor = .clear

    let footerTextColor = theme.textSecondary
    footerView.largeMinutePicker.setValue(footerTextColor, forKey: "textColor")
    footerView.secondPicker.setValue(footerTextColor, forKey: "textColor")
    footerView.hourPicker.setValue(footerTextColor, forKey: "textColor")
    footerView.mmSSColon.textColor = footerTextColor
    footerView.hhMMColon.textColor = footerTextColor




    intervalTableView.endUpdates()

    UIView.setAnimationsEnabled(true)

  }

  func getTimeIntervalFromScale(_ scale: Float) -> TimeInterval {
    let newWarmupValue = sliderSizeInSeconds * scale
    let secondStrideFloat = Float(secondStride)
    let warmupDuration = round(newWarmupValue / secondStrideFloat) * secondStrideFloat
    let warmupTimeInterval = TimeInterval(warmupDuration)
    return warmupTimeInterval
  }

  func getWidthFromValue(_ value: TimeInterval, _ containerWidth: CGFloat) -> CGFloat {
    let valueFloat = Float(value)
    let newScale = valueFloat / sliderSizeInSeconds
    let containerWidthFloat = Float(containerWidth)
    let newWidth = containerWidthFloat * newScale
    let newWidthCGFloat = CGFloat(newWidth)
    return newWidthCGFloat
  }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

    let segueToUse = segue.identifier

    if segueToUse == "setIntervalsToWorkout" {
      let destinationVC = segue.destination as! WorkoutViewController
      destinationVC.activityType = activityType
    }

  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return intervalTemplateArray.count
  }


  func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {

    guard let footerView = intervalTableView.dequeueReusableHeaderFooterView(withIdentifier: IntervalTableViewFooter.reuseIdentifier) as? IntervalTableViewFooter else {
      return nil
    }

    footerView.totalLabel.isHidden = false
    footerView.minutePicker.isHidden = true
    footerView.largeMinutePicker.isHidden = false
    footerView.contentView.backgroundColor = theme.background

    var totalIntervalTime           = [Double]()
    var durationTotal: Double = 0

    // to get the workout duration, get the full TimeInterval since the workout started
    totalIntervalTime = intervalTemplateArray.map({$0.duration})

    // sum the total
    durationTotal = totalIntervalTime.reduce(0, {$0 + $1})
    MyFunc.logMessage(.debug, String(describing: durationTotal))
    let durationMinutes   = durationTotal.toMinutes()
    let durationSeconds = durationTotal.toSeconds(secondStride)

    if durationTotal >= 3600 {
      let durationHours = durationTotal.toHours()
      footerView.hourPicker.isHidden = false
      footerView.hhMMColon.isHidden = false
      let hoursIndex: Int = largeMinuteArray.firstIndex(where: { $0.description == durationHours }) ?? 0
      footerView.hourPicker.selectRow(hoursIndex, inComponent: 0, animated: false)
      footerView.hourPicker.reloadAllComponents()
      footerView.hourPicker.subviews[1].backgroundColor = .clear
    } else {
      footerView.hourPicker.isHidden = true
      footerView.hhMMColon.isHidden = true
    }

    footerView.largeMinutePicker.delegate = self
    footerView.largeMinutePicker.reloadAllComponents()
    let minutesIndex: Int = largeMinuteArray.firstIndex(where: { $0.description == durationMinutes }) ?? 0
    footerView.largeMinutePicker.selectRow(minutesIndex, inComponent: 0, animated: false)

    footerView.secondPicker.delegate = self
    let secondsIndex: Int = secondArray.firstIndex(where: { $0.description == durationSeconds }) ?? 0
    footerView.secondPicker.selectRow(secondsIndex, inComponent: 0, animated: false)

    footerView.largeMinutePicker.isUserInteractionEnabled = false
    footerView.secondPicker.isUserInteractionEnabled = false

    footerView.secondPicker.subviews[1].backgroundColor = .clear
    footerView.largeMinutePicker.subviews[1].backgroundColor = .clear

    let footerTextColor = theme.textSecondary
    footerView.largeMinutePicker.setValue(footerTextColor, forKey: "textColor")
    footerView.secondPicker.setValue(footerTextColor, forKey: "textColor")
    footerView.hourPicker.setValue(footerTextColor, forKey: "textColor")
    footerView.mmSSColon.textColor = footerTextColor
    footerView.hhMMColon.textColor = footerTextColor

    return footerView
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

    let cell = tableView.dequeueReusableCell(withIdentifier: "IntervalTypeTableViewCell", for: indexPath) as! IntervalTypeTableViewCell

    cell.totalLabel.isHidden = true

    let cellIntervalTemplate = intervalTemplateArray[indexPath.row]
    MyFunc.logMessage(.debug, String(describing: cellIntervalTemplate))
    cell.durationWidth.constant = getWidthFromValue(cellIntervalTemplate.duration, cell.durationContainerView.bounds.width)

    let durationTimeInterval = cellIntervalTemplate.duration
    let durationMinutes = durationTimeInterval.toMinutes()
    let durationSeconds = durationTimeInterval.toSeconds(secondStride)

    cell.minutePicker.delegate = self
    cell.minutePicker.reloadAllComponents()
    let minutesIndex: Int = minuteArray.firstIndex(where: { $0.description == durationMinutes }) ?? 0
    cell.minutePicker.selectRow(minutesIndex, inComponent: 0, animated: false)

    // populate the indexPath array - we will need to reference the minutes stored value when the seconds are updated
    // in order to have both values from which to update the duration
    //    MyFunc.logMessage(.debug, "indexPath.row: \(indexPath.row)")
    if indexPath.row < selectedItemForRowMinutes.count {
      selectedItemForRowMinutes[indexPath.row] = minutesIndex
    } else {
      selectedItemForRowMinutes.append(0)
    }

    cell.secondPicker.delegate = self
    let secondsIndex: Int = secondArray.firstIndex(where: { $0.description == durationSeconds }) ?? 0
    cell.secondPicker.selectRow(secondsIndex, inComponent: 0, animated: false)

    if indexPath.row < selectedItemForRowSeconds.count {
      selectedItemForRowSeconds[indexPath.row] = secondsIndex
    } else {
      selectedItemForRowSeconds.append(0)
    }

    cell.secondPicker.reloadAllComponents()

    // pass the indexPath to the cell, it will need this to pass back in the event of the gesture recognizer being used
    cell.indexPath = indexPath
    cell.delegate = self
    cell.secondPicker.subviews[1].backgroundColor = .clear
    cell.minutePicker.subviews[1].backgroundColor = .clear

    let imageName = cellIntervalTemplate.intervalType.rawValue + ".png"
    cell.intervalImageView.image = UIImage(named: imageName)
    var rowTintColor = UIColor()
    switch cellIntervalTemplate.intervalType {
    case .work:
      rowTintColor = workColour
    case .rest:
      rowTintColor = restColour
    default:
      rowTintColor = warmupCooldownColour
    }
    cell.durationValueView.backgroundColor = rowTintColor
    cell.intervalImageView.image = cell.intervalImageView.image?.withRenderingMode(.alwaysTemplate)
    cell.intervalImageView.tintColor = rowTintColor
    cell.secondPicker.setValue(rowTintColor, forKey: "textColor")
    cell.minutePicker.setValue(rowTintColor, forKey: "textColor")
    cell.mmSSColon.textColor = rowTintColor

    if activityType == .custom {
      cell.isUserInteractionEnabled = true
    } else {
      cell.isUserInteractionEnabled = false
    }

    return cell

  }

  func loadMinuteItems() {
    for minute in 0...5 {
      let itemStr = String(minute)
      minuteArray.append(itemStr)
    }
  }

  func loadLargeMinuteItems() {
    for minute in 0...990 {
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

  func getTimeIntervalFromPickers(minute: String, second: String) -> Double {

    let minuteInt = Int(minute) ?? 0
    let secondInt  = Int(second) ?? 0

    let durationInt = (minuteInt * 60) + secondInt
    let durationDouble = Double(durationInt)
    return durationDouble

  }

  func getIntervalTemplateForPicker(pickerTag: Int) -> IntervalTemplate {
    var intervalTemplateToReturn = IntervalTemplate(activityType: .none, duration: 0)
    switch pickerTag {
    case 11, 12:
      intervalTemplateToReturn = activityTemplate.warmup
    case 21, 22:
      intervalTemplateToReturn = activityTemplate.work
    case 31, 32:
      intervalTemplateToReturn = activityTemplate.rest
    case 41, 42:
      intervalTemplateToReturn = activityTemplate.cooldown
    default:
      MyFunc.logMessage(.error, "Invalid pickerTag: \(pickerTag)")
    }
    return intervalTemplateToReturn
  }

  func getIntervalTemplateForRow(_ row: Int) -> IntervalTemplate {

    let intervalTemplateToReturn = intervalTemplateArray[row]
    return intervalTemplateToReturn
  }

  func setIntervalTemplateForType(_ intervalTemplate: IntervalTemplate, _ activityTemplate: ActivityTemplate) -> ActivityTemplate {

    var activityTemplateToReturn = activityTemplate
    switch intervalTemplate.intervalType {
    case .warmup:
      activityTemplateToReturn.warmup.duration = intervalTemplate.duration
    case .rest:
      activityTemplateToReturn.rest.duration = intervalTemplate.duration
    case .work:
      activityTemplateToReturn.work.duration = intervalTemplate.duration
    case .cooldown:
      activityTemplateToReturn.cooldown.duration = intervalTemplate.duration
    default:
      MyFunc.logMessage(.error, "Unknown intervalTemplate \(intervalTemplate) for intervalTemplate \(activityTemplate)")
    }
    return activityTemplateToReturn
  }

  func saveIntervals() {

    loadIntervalTemplateArray()
    activityTemplate.intervals.removeAll()
    activityTemplate.intervals = intervalTemplateArray
    MyFunc.saveActivityDefaults(activityTemplate)
    // had added main queue use to attempt to resolve comms issues - removing to see if this affects buffer delay
    //    DispatchQueue.main.async {
      self.updateApplicationContextForActivityTemplate(activityTemplate: self.activityTemplate)
//    }
  }
  func refreshIntervals() {

    UIView.setAnimationsEnabled(false)
    self.intervalTableView.reloadData()
    UIView.setAnimationsEnabled(true)

  }

  func loadIntervalTemplateArray() {

    // decompose ActivityTemplate into flattened array
    switch activityType {
    case .repeat, .tabata:
      intervalTemplateArray.removeAll()
      intervalTemplateArray = MyFunc.createRepeatIntervalSet(activityTemplate)

    case .pyramid:
      activityTemplate.activityPattern = .pyramid
      intervalTemplateArray.removeAll()
      intervalTemplateArray = MyFunc.createCustomIntervalSet(activityTemplate)

    case .custom:
      intervalTemplateArray.removeAll()
      if activityTemplate.intervals.isEmpty || activityTemplate.customIntervals == false {
        intervalTemplateArray = MyFunc.createCustomIntervalSet(activityTemplate)
      } else {
        intervalTemplateArray = activityTemplate.intervals
      }

    case .random:
      intervalTemplateArray.removeAll()
      intervalTemplateArray = MyFunc.createRandomIntervalSet(activityTemplate)

    default:
      MyFunc.logMessage(.debug, "Invalid Activity Type entered")
    }

  }

  func updateWarmupPickers() {
    let warmupMinutesStr = activityTemplate.warmup.duration.toMinutes()
    let warmupMinutesDefault: Int = minuteArray.firstIndex(where: { $0.description == warmupMinutesStr }) ?? 0
    warmupMinutePicker.selectRow(warmupMinutesDefault, inComponent: 0, animated: false)
    let warmupSecondsStr = activityTemplate.warmup.duration.toSeconds(secondStride)
    let warmupSecondsDefault: Int = secondArray.firstIndex(where: { $0.description == warmupSecondsStr }) ?? 0
    warmupSecondPicker.selectRow(warmupSecondsDefault, inComponent: 0, animated: false)
  }

  func updateWorkPickers() {
    let workMinutesStr = activityTemplate.work.duration.toMinutes()
    let workMinutesDefault: Int = minuteArray.firstIndex(where: { $0.description == workMinutesStr }) ?? 0
    workMinutePicker.selectRow(workMinutesDefault, inComponent: 0, animated: false)
    let workSecondsStr = activityTemplate.work.duration.toSeconds(secondStride)
    let workSecondsDefault: Int = secondArray.firstIndex(where: { $0.description == workSecondsStr }) ?? 0
    workSecondPicker.selectRow(workSecondsDefault, inComponent: 0, animated: false)
  }

  func updateRestPickers() {
    let restMinutesStr = activityTemplate.rest.duration.toMinutes()
    let restMinutesDefault: Int = minuteArray.firstIndex(where: { $0.description == restMinutesStr }) ?? 0
    restMinutePicker.selectRow(restMinutesDefault, inComponent: 0, animated: false)
    let restSecondsStr = activityTemplate.rest.duration.toSeconds(secondStride)
    let restSecondsDefault: Int = secondArray.firstIndex(where: { $0.description == restSecondsStr }) ?? 0
    restSecondPicker.selectRow(restSecondsDefault, inComponent: 0, animated: false)

  }
  func updateCooldownPickers() {
    let cooldownMinutesStr = activityTemplate.cooldown.duration.toMinutes()
    let cooldownMinutesDefault: Int = minuteArray.firstIndex(where: { $0.description == cooldownMinutesStr }) ?? 0
    cooldownMinutePicker.selectRow(cooldownMinutesDefault, inComponent: 0, animated: false)
    let cooldownSecondsStr = activityTemplate.cooldown.duration.toSeconds(secondStride)
    let cooldownSecondsDefault: Int = secondArray.firstIndex(where: { $0.description == cooldownSecondsStr }) ?? 0
    cooldownSecondPicker.selectRow(cooldownSecondsDefault, inComponent: 0, animated: false)
  }

  func updateDurationView(intervalType: IntervalType) {
    switch intervalType {
    case .warmup:
      warmupViewWidth.constant = getWidthFromValue(activityTemplate.warmup.duration, warmupContainerView.bounds.width)
    case .work:
      workViewWidth.constant = getWidthFromValue(activityTemplate.work.duration, workContainerView.bounds.width)
    case .rest:
      restViewWidth.constant = getWidthFromValue(activityTemplate.rest.duration, restContainerView.bounds.width)
    case .cooldown:
      cooldownViewWidth.constant = getWidthFromValue(activityTemplate.cooldown.duration, cooldownContainerView.bounds.width)

    default:
      return
    }

  }

  func displayAlert (title: String, message: String) {

    //Alert user that Save has worked
    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
    let okAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: { [self] (_) in
      navigationItem.rightBarButtonItem = nil
      activityTemplate.customIntervals = false
      let customIntervalArray = MyFunc.createCustomIntervalSet(activityTemplate)
      intervalTemplateArray.removeAll()
      intervalTemplateArray = customIntervalArray
      activityTemplate.intervals.removeAll()
      activityTemplate.intervals = intervalTemplateArray
      saveIntervals()
      refreshIntervals()
    })

    let cancelTitle = NSLocalizedString("Cancel", comment: "Cancel")
    let cancelAction = UIAlertAction(title: cancelTitle, style: .cancel)
    alert.addAction(okAction)
    alert.addAction(cancelAction)
    present(alert, animated: true, completion: nil)

  }

}
