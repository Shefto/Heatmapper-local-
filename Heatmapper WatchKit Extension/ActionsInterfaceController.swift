//
//  ActionsInterfaceController.swift
//  Heatmapper WatchKit Extension
//
//  Created by Richard English on 05/10/2020.
//  Copyright © 2020 Richard English. All rights reserved.
//

import WatchKit
import AVFoundation

class ActionsInterfaceController: WKInterfaceController {

//  let audio = Audio()

  static let synthesizer        = AVSpeechSynthesizer()
  var audioPlayer               = AVAudioPlayer()

  var buttonJustPressed : Bool = false

  @IBOutlet weak var resumeButton: WKInterfaceButton!
  @IBOutlet weak var pauseButton: WKInterfaceButton!
  @IBOutlet weak var endButton: WKInterfaceButton!

  @IBAction func btnLock() {

    stopSpeaking()
    let lockPhraseLocalized = NSLocalizedString("Screen lock enabled", comment: "")
    speak(phrase: lockPhraseLocalized)

    DispatchQueue.main.async {
      NotificationCenter.default.post(name: Notification.Name("Lock"), object: self)
    }
  }

  @IBAction func btnEnd() {

    pauseButton.setEnabled(false)
    resumeButton.setEnabled(false)
    endButton.setEnabled(false)
    stopSpeaking()
    let finishPhraseLocalized = NSLocalizedString("Finishing workout", comment: "")
    speak(phrase: finishPhraseLocalized)

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

    stopSpeaking()

    DispatchQueue.main.async {
      NotificationCenter.default.post(name: Notification.Name("Resume"), object: self)
    }
  }

  @IBAction func btnPause() {
    preventMultiplePresses()
    endButton.setEnabled(true)
    pauseButton.setEnabled(false)
    resumeButton.setEnabled(true)

    stopSpeaking()

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

  func playSound(filename: String, fileExtension: String) {

    //    let soundURL = Bundle.main.path(forResource: filename, ofType: fileExtension)
    let soundURL = Bundle.main.url(forResource: filename, withExtension: fileExtension)
    MyFunc.logMessage(.debug, "soundURL: \(String(describing: soundURL))")
    do {
      audioPlayer = try AVAudioPlayer(contentsOf: soundURL!)
      audioPlayer.prepareToPlay()
      audioPlayer.play()
    } catch let error as NSError {
      MyFunc.logMessage(.error,"Audio: Error playing sound file \(String(describing: soundURL)) \(error)")
    }

  }


  func speak(phrase: String) {
    let utterance = AVSpeechUtterance(string: phrase)
    let languageCode = AVSpeechSynthesisVoice.currentLanguageCode()
    utterance.voice = AVSpeechSynthesisVoice(language: languageCode)
    if languageCode == "en-GB" {
      utterance.rate = AVSpeechUtteranceMaximumSpeechRate * 0.55
    }
    ActionsInterfaceController.synthesizer.speak(utterance)
  }

  func stopSpeaking() {
    ActionsInterfaceController.synthesizer.stopSpeaking(at: .immediate)
  }


}
