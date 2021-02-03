//
//  SettingsViewController.swift
//  Heatmapper
//
//  Created by Richard English on 27/12/2020.
//  Copyright © 2020 Richard English. All rights reserved.
//

import UIKit
import StoreKit
import AudioToolbox

class SettingsViewController: UIViewController, SessionCommands, SKPaymentTransactionObserver {

  let productID = "wimbledonappcompany.com.Heatmapper.RemoveAds2"
  let defaults    = UserDefaults.standard
  let helpImage   = UIImage(systemName: "questionmark.circle")
  let theme     = ColourTheme()

  @IBOutlet weak var locationSegmentedControl: UISegmentedControl!
  @IBOutlet weak var vibrationSegmentedControl: UISegmentedControl!
  @IBOutlet weak var unitSpeedSegmentedControl: UISegmentedControl!
  @IBOutlet weak var removeAdsButton: ThemeButton!
  @IBOutlet weak var restorePurchaseButton: ThemeButton!

  @IBAction func btnRestore(_ sender: Any) {
    SKPaymentQueue.default().restoreCompletedTransactions()
  }

  @IBAction func btnRemoveAds(_ sender: Any) {
    if SKPaymentQueue.canMakePayments() {
      //Can make payments

      let paymentRequest = SKMutablePayment()
      paymentRequest.productIdentifier = productID
      SKPaymentQueue.default().add(paymentRequest)

    } else {
      //Can't make payments
      MyFunc.logMessage(.debug, "User can't make payments")
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    SKPaymentQueue.default().add(self)

    if MyFunc.removeAdsPurchased() {
      removeAds()
    }
    loadUI()
  }

  @IBAction func helpButton() {
    self.performSegue(withIdentifier: "settingsToHelp", sender: .none)
  }

  func loadUI() {
    loadUnitSpeedSegmentedControl()
    loadLocationSegmentedControl()
    loadVibrationSegmentedControl()
    


    self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: helpImage, style: .plain, target: self, action: #selector(self.helpButton))
  }

  func loadUnitSpeedSegmentedControl() {
    // get UnitSpeed default
    let unitSpeedDefault = defaults.object(forKey: "Units") as? String ?? ""
    switch unitSpeedDefault {
    case "km/h":
      unitSpeedSegmentedControl.selectedSegmentIndex = 0
    case "mph":
      unitSpeedSegmentedControl.selectedSegmentIndex = 1
    case "mins/km":
      unitSpeedSegmentedControl.selectedSegmentIndex = 2
    case "mins/mi":
      unitSpeedSegmentedControl.selectedSegmentIndex = 3
    default:
      ()
    }
  }

  func loadVibrationSegmentedControl() {
    // get Vibration default
    let vibrationDefault = defaults.object(forKey: "Vibration") as? String ?? ""

    switch vibrationDefault {
    case "On":
      vibrationSegmentedControl.selectedSegmentIndex = 0
    case "Off":
      vibrationSegmentedControl.selectedSegmentIndex = 1
    default:
      ()
    }

  }


  func resizeSegmentedControlText(view :UIView)  {
          let subviews = view.subviews
          for subview in subviews {
            if subview is UILabel {
              let label: UILabel? = (subview as? UILabel)
              print("label found: \(String(describing: label?.text))")
              label?.adjustsFontSizeToFitWidth = true
              label?.minimumScaleFactor = 0.1
            } else {
              resizeSegmentedControlText(view: subview)
            }
          }
        }


  func loadLocationSegmentedControl() {

    resizeSegmentedControlText(view: locationSegmentedControl)

    let locationDefault = defaults.object(forKey: "Location") as? String ?? ""

    switch locationDefault {
    case "Battery":
      locationSegmentedControl.selectedSegmentIndex = 0
    case "Balanced":
      locationSegmentedControl.selectedSegmentIndex = 1
    case "Accuracy":
      locationSegmentedControl.selectedSegmentIndex = 2
    default:
      ()
    }

  }

  @IBAction func segLocation(_ sender: UISegmentedControl) {
    switch sender.selectedSegmentIndex {
    case 0:
      defaults.set("Battery", forKey: "Location")
      updateApplicationContextForUserDefault(["Location": "On"])
    case 1:
      defaults.set("Balanced", forKey: "Location")
      updateApplicationContextForUserDefault(["Location": "Off"])
    default:
      defaults.set("Accuracy", forKey: "Location")
      updateApplicationContextForUserDefault(["Location": "On"])
    }
    loadLocationSegmentedControl()

  }


  @IBAction func segUnitSpeed(_ sender: UISegmentedControl) {

    switch sender.selectedSegmentIndex {
    case 0:
      defaults.set("km/h", forKey: "Units")
      updateApplicationContextForUserDefault(["Units": "km/h"])
    case 1:
      defaults.set("mph", forKey: "Units")
      updateApplicationContextForUserDefault(["Units": "mph"])
    case 2:
      defaults.set("mins/km", forKey: "Units")
      updateApplicationContextForUserDefault(["Units": "mins/km"])
    case 3:
      defaults.set("mins/mi", forKey: "Units")
      updateApplicationContextForUserDefault(["Units": "mins/mi"])
    default:
      defaults.set("km/h", forKey: "Units")
      updateApplicationContextForUserDefault(["Units": "km/h"])
    }
    loadUnitSpeedSegmentedControl()
  }

  @IBAction func segVibration(_ sender: UISegmentedControl) {

    switch sender.selectedSegmentIndex {
    case 0:
      AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
      defaults.set("On", forKey: "Vibration")
      updateApplicationContextForUserDefault(["Vibration": "On"])
    case 1:
      defaults.set("Off", forKey: "Vibration")
      updateApplicationContextForUserDefault(["Vibration": "Off"])
    default:
      defaults.set("On", forKey: "Vibration")
      updateApplicationContextForUserDefault(["Vibration": "On"])
    }
    loadVibrationSegmentedControl()
  }

  // MARK: - In-App Purchase Methods

  func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {

    for transaction in transactions {
      if transaction.transactionState == .purchased {

        //User payment successful
        MyFunc.logMessage(.debug, "Transaction successful!")

        removeAds()

        SKPaymentQueue.default().finishTransaction(transaction)

      } else if transaction.transactionState == .failed {

        //Payment failed

        if let error = transaction.error {
          let errorDescription = error.localizedDescription
          MyFunc.logMessage(.debug, "Transaction failed due to error: \(errorDescription)")
        }

        SKPaymentQueue.default().finishTransaction(transaction)

      } else if transaction.transactionState == .restored {

        removeAds()

        MyFunc.logMessage(.debug, "Transaction restored")

        navigationItem.setRightBarButton(nil, animated: true)

        SKPaymentQueue.default().finishTransaction(transaction)
      }
    }

  }

  func removeAds() {

    UserDefaults.standard.set(true, forKey: productID)
    removeAdsButton.isHidden = true
    restorePurchaseButton.isHidden = true

  }


}
