//
//  SessionDelegator.swift
//  Heatmapper
//
//  Created by Richard English on 10/07/2020.
//  Copyright © 2020 Richard English. All rights reserved.
//

import Foundation
import WatchConnectivity
import os

#if os(watchOS)
import ClockKit
#endif

// Custom notifications.
// Posted when Watch Connectivity activation status is changed,
// or when data is received or sent. Clients observe these notifications to update the UI.
extension Notification.Name {
  static let dataDidFlow = Notification.Name("DataDidFlow")
  static let activationDidComplete = Notification.Name("ActivationDidComplete")
  static let reachabilityDidChange = Notification.Name("ReachabilityDidChange")
}

// Implement WCSessionDelegate methods to receive Watch Connectivity data and notify clients.
// WCsession status changes are also handled here.
class SessionDelegator: NSObject, WCSessionDelegate {

  let logger = Logger()

  // Called when WCSession activation state is changed.
  func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    postNotificationOnMainQueueAsync(name: .activationDidComplete)
  }

  // Called when WCSession reachability is changed
  func sessionReachabilityDidChange(_ session: WCSession) {
    postNotificationOnMainQueueAsync(name: .reachabilityDidChange)
  }

  // Called when a file is received
  func session(_ session: WCSession, didReceive file: WCSessionFile) {
    var commandStatus = CommandStatus(command: .transferFile, phrase: .received)
    commandStatus.file = file
  }

  // Called when an app context is received
  func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
    MyFunc.logMessage(.debug, "didReceiveApplicationContext!")
    MyFunc.logMessage(.debug, String(describing: applicationContext))

    // perform action depending upon what has been passed over
    let contents = applicationContext["Contents"] as! String
    var dictionaryFromContext = applicationContext
    dictionaryFromContext.removeValue(forKey: "Date")
    dictionaryFromContext.removeValue(forKey: "Contents")

    switch contents {
    case "ActivityTemplate":

      guard let templateReceived = ActivityTemplate.init(dictionary: dictionaryFromContext) else {
        MyFunc.logMessage(.error, "Failed to create ActivityTemplate from dictionary: \(dictionaryFromContext)")
        return
      }
      MyFunc.saveActivityDefaults(templateReceived)

    case "UserDefault":
      guard let defaultForUpdate = dictionaryFromContext.first else {
        MyFunc.logMessage(.error, "Failed to create default from dictionary: \(dictionaryFromContext)")
        return
      }
      let defaults = UserDefaults.standard
      defaults.setValue(defaultForUpdate.value, forKey: defaultForUpdate.key)
      MyFunc.logMessage(.debug, "Default Updated!")
      MyFunc.logMessage(.debug, String(describing: defaultForUpdate))

    default:
      MyFunc.logMessage(.error, "Unknown context received: \(contents)")
    }

    let commandStatus = CommandStatus(command: .updateAppContext, phrase: .received)
    self.postNotificationOnMainQueueAsync(name: .dataDidFlow, object: commandStatus)

  }

  // Called when a file transfer is done.
  func session(_ session: WCSession, didFinish fileTransfer: WCSessionFileTransfer, error: Error?) {
    var commandStatus = CommandStatus(command: .transferFile, phrase: .finished)

    if let error = error {
      commandStatus.errorMessage = error.localizedDescription
      return
    }
    commandStatus.fileTransfer = fileTransfer

    #if os(watchOS)
    if WatchSettings.sharedContainerID.isEmpty == false {
      let defaults = UserDefaults(suiteName: WatchSettings.sharedContainerID)
      if let enabled = defaults?.bool(forKey: WatchSettings.clearLogsAfterTransferred), enabled {
        CustomLogger.shared.clearLogs()
      }
    }
    #endif
  }

  // WCSessionDelegate methods for iOS only.

  #if os(iOS)
  // required protocol stub
  func sessionDidBecomeInactive(_ session: WCSession) {
    logger.info("\(#function): activationState = \(session.activationState.rawValue)")
  }

  func sessionDidDeactivate(_ session: WCSession) {
    // Activate the new session after having switched to a new watch.
    session.activate()
  }

  func sessionWatchStateDidChange(_ session: WCSession) {
    logger.info("\(#function): activationState = \(session.activationState.rawValue)")
  }
  #endif

  // Post a notification on the main thread asynchronously.
  private func postNotificationOnMainQueueAsync(name: NSNotification.Name, object: CommandStatus? = nil) {
    DispatchQueue.main.async {
      NotificationCenter.default.post(name: name, object: object)
    }
  }
}
