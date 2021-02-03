//
//  Audio.swift
//  Heatmapper WatchKit Extension
//
//  Created by Richard English on 07/10/2020.
//  Copyright © 2020 Richard English. All rights reserved.
//

import Foundation
import AVFoundation
import os

class Audio {

  let synthesizer        = AVSpeechSynthesizer()
  var audioPlayer: AVAudioPlayer!
  let logger              = Logger()

  func playSound(filename: String, fileExtension: String) {
    let soundURL = Bundle.main.url(forResource: filename, withExtension: fileExtension)
    do {
      audioPlayer = try AVAudioPlayer(contentsOf: soundURL!)
      audioPlayer.prepareToPlay()
      audioPlayer.play()
    } catch let error as NSError {
      logger.error("Audio: Error playing sound file \(String(describing: soundURL)) \(error)")
    }

  }

  func stopPlayer() {

    guard let player = audioPlayer else {
      logger.error("Audio: No audioPlayer exists")
      return
    }
    player.stop()

  }

  func speak(phrase: String) {
    let utterance = AVSpeechUtterance(string: phrase)
    let languageCode = AVSpeechSynthesisVoice.currentLanguageCode()
    utterance.voice = AVSpeechSynthesisVoice(language: languageCode)
    if languageCode == "en-GB" {
      utterance.rate = AVSpeechUtteranceMaximumSpeechRate * 0.55
    }
    self.synthesizer.speak(utterance)
  }

  func stopSpeaking() {
    synthesizer.stopSpeaking(at: .immediate)
  }

}
