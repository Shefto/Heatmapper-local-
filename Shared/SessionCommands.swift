//
//  SessionCommands.swift
//  FIT
//
//  Created by Richard English on 10/07/2020.
//  Copyright © 2020 Richard English. All rights reserved.
//

import UIKit
import WatchConnectivity

// Define an interface to wrap Watch Connectivity APIs and
// bridge the UI. Shared by the iOS app and watchOS app.
protocol SessionCommands {
  func transferFile(_ file: URL, metadata: [String: Any])
  func updateApplicationContextForActivityTemplate(activityTemplate: ActivityTemplate)
  func updateApplicationContextForUserDefault(_ context: [String: Any])
}

// Implement the commands. Every command handles the communication and notifies clients
// when WCSession status changes or data flows. Shared by the iOS app and watchOS app.
extension SessionCommands {

  // Transfer a file if the session is activated and update UI with the command status.
  // A WCSessionFileTransfer object is returned to monitor the progress or cancel the operation.
  func transferFile(_ file: URL, metadata: [String: Any]) {
    var commandStatus = CommandStatus(command: .transferFile, phrase: .transferring)

    guard WCSession.default.activationState == .activated else {
      return handleSessionUnactivated(with: commandStatus)
    }
    commandStatus.fileTransfer = WCSession.default.transferFile(file, metadata: metadata)
    //        postNotificationOnMainQueueAsync(name: .dataDidFlow, object: commandStatus)
  }

  func updateApplicationContextForActivityTemplate(activityTemplate: ActivityTemplate) {
    // this function sends the Activity Template to the watch / phone using WatchConnectivity
    // the Template must first be connected to a dictionary in order for updateApplicationContext to pass it

    // get the Activity Template in dictionary form
    var templateAsDictionary = activityTemplate.dictionaryRepresentation
    // add a Date key to the payload
    // this ensures uniqueness, otherwise updateApplicationContext will ignore it
    // consider removing this line once syncing confirmed to work
    templateAsDictionary.updateValue(Date(), forKey: "Date")
    // tell the receiver what we're sending
    templateAsDictionary.updateValue("ActivityTemplate", forKey: "Contents")
    var commandStatus = CommandStatus(command: .updateAppContext, phrase: .updated)

    #if os(iOS)
    guard WCSession.default.isPaired == true else {
      MyFunc.logMessage(.error, "Error : Watch and iPhone not paired")
      return
    }
    guard WCSession.default.isWatchAppInstalled == true else {
      MyFunc.logMessage(.error, "Error : Watch app not installed")
      return
    }
    #endif
    guard WCSession.default.activationState == .activated else {
      return handleSessionUnactivated(with: commandStatus)
    }
    do {
      try WCSession.default.updateApplicationContext(templateAsDictionary)
    } catch {
      commandStatus.phrase = .failed
      commandStatus.errorMessage = error.localizedDescription
    }

    postNotificationOnMainQueueAsync(name: .dataDidFlow, object: commandStatus)
  }

  func updateApplicationContextForUserDefault(_ context: [String: Any]) {
    // this function sends a Dictionary to the watch / phone using WatchConnectivity
    var contextToSend = context
    // add a Date key to the payload
    // this ensures uniqueness, otherwise updateApplicationContext will ignore it
    // consider removing this line once syncing confirmed to work
    contextToSend.updateValue(Date(), forKey: "Date")
    // tell the receiver what we're sending
    contextToSend.updateValue("UserDefault", forKey: "Contents")
    var commandStatus = CommandStatus(command: .updateAppContext, phrase: .updated)

    #if os(iOS)
    guard WCSession.default.isPaired == true else {
      MyFunc.logMessage(.error, "Error : Watch and iPhone not paired")
      return
    }
    guard WCSession.default.isWatchAppInstalled == true else {
      MyFunc.logMessage(.error, "Error : Watch app not installed")
      return
    }
    #endif
    guard WCSession.default.activationState == .activated else {
      return handleSessionUnactivated(with: commandStatus)
    }
    do {
      try WCSession.default.updateApplicationContext(contextToSend)
    } catch {
      commandStatus.phrase = .failed
      commandStatus.errorMessage = error.localizedDescription
    }

    postNotificationOnMainQueueAsync(name: .dataDidFlow, object: commandStatus)
  }

  // Post a notification on the main thread asynchronously.
  private func postNotificationOnMainQueueAsync(name: NSNotification.Name, object: CommandStatus) {
    DispatchQueue.main.async {
      NotificationCenter.default.post(name: name, object: object)
    }
  }

  // Handle the session unactivated error. WCSession commands require an activated session.
  private func handleSessionUnactivated(with commandStatus: CommandStatus) {
    var mutableStatus = commandStatus
    mutableStatus.phrase = .failed
    mutableStatus.errorMessage =  "WCSession is not activeted yet"

  }
}
