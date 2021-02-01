//
//  ActionsInterfaceController.swift
//  FIT WatchKit Extension
//
//  Created by Richard English on 05/10/2020.
//  Copyright © 2020 Richard English. All rights reserved.
//

import WatchKit

class ActionsInterfaceController: WKInterfaceController {

  let audio = Audio()

  var buttonJustPressed : Bool = false

  @IBOutlet weak var resumeButton: WKInterfaceButton!
  @IBOutlet weak var pauseButton: WKInterfaceButton!
  @IBOutlet weak var endButton: WKInterfaceButton!

  @IBAction func btnLock() {

    audio.stopSpeaking()
    let lockPhraseLocalized = NSLocalizedString("Screen lock enabled", comment: "")
    audio.speak(phrase: lockPhraseLocalized)

    DispatchQueue.main.async {
      NotificationCenter.default.post(name: Notification.Name("Lock"), object: self)
    }
  }

  @IBAction func btnEnd() {

    pauseButton.setEnabled(false)
    resumeButton.setEnabled(false)
    endButton.setEnabled(false)
    audio.stopSpeaking()
    let finishPhraseLocalized = NSLocalizedString("Finishing workout", comment: "")
    audio.speak(phrase: finishPhraseLocalized)

    // return to FartlekInterfaceController to finish processing workout
    DispatchQueue.main.async {
      NotificationCenter.default.post(name: Notification.Name("End"), object: self)
    }

  }

  @IBAction func btnResume() {
    preventMultiplePresses()
    endButton.setEnabled(true)
    pauseButton.setEnabled(true)
    resumeButton.setEnabled(false)

    audio.stopSpeaking()

    DispatchQueue.main.async {
      NotificationCenter.default.post(name: Notification.Name("Resume"), object: self)
    }
  }

  @IBAction func btnPause() {
    preventMultiplePresses()
    endButton.setEnabled(true)
    pauseButton.setEnabled(false)
    resumeButton.setEnabled(true)

    audio.stopSpeaking()

    DispatchQueue.main.async {
      NotificationCenter.default.post(name: Notification.Name("Pause"), object: self)
    }
  }

  override func awake(withContext context: Any?) {
    super.awake(withContext: context)
    endButton.setEnabled(true)
    pauseButton.setEnabled(true)
    resumeButton.setEnabled(false)

  }

  func preventMultiplePresses() {

    if buttonJustPressed == true {
      MyFunc.logMessage(.debug, "buttonJustPressed prevented multiple clicks")
      return
    }
    // after 3 seconds, activate it again
    DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
      self.buttonJustPressed = false
    }
  }

}
