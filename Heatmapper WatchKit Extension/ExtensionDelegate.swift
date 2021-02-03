//
//  ExtensionDelegate.swift
//  Heatmapper WatchKit Extension
//
//  Created by Richard English on 22/06/2020.
//  Copyright © 2020 Richard English. All rights reserved.
//

import WatchKit
import WatchConnectivity

class ExtensionDelegate: NSObject, WKExtensionDelegate {

    private lazy var sessionDelegator: SessionDelegator = {
        return SessionDelegator()
    }()

    // Hold the KVO observers as we want to keep oberving in the extension life time.
    //
    private var activationStateObservation: NSKeyValueObservation?
    private var hasContentPendingObservation: NSKeyValueObservation?

    // An array to keep the background tasks.
    //
    private var wcBackgroundTasks = [WKWatchConnectivityRefreshBackgroundTask]()

    override init() {
        super.init()
      let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
      let documentsDirectory = paths[0]
      let documentsDirectoryStr = String(describing: documentsDirectory)
      let indexStartOfText = documentsDirectoryStr.index(documentsDirectoryStr.startIndex, offsetBy: 7)
      let documentsDirectorySubstr = documentsDirectoryStr[indexStartOfText...]
      print("documentsDirectory: \(documentsDirectorySubstr)")

        assert(WCSession.isSupported(), "This sample requires a platform supporting Watch Connectivity!")

        if WatchSettings.sharedContainerID.isEmpty {
          MyFunc.logMessage(.error, "Specify a shared container ID for WatchSettings.sharedContainerID to use watch settings!")
        }

        // WKWatchConnectivityRefreshBackgroundTask should be completed – Otherwise they will keep consuming
        // the background executing time and eventually causes an app crash.
        // The timing to complete the tasks is when the current WCSession turns to not .activated or
        // hasContentPending flipped to false (see completeBackgroundTasks), so KVO is set up here to observe
        // the changes if the two properties.
        //
        activationStateObservation = WCSession.default.observe(\.activationState) { _, _ in
            DispatchQueue.main.async {
                self.completeBackgroundTasks()
            }
        }
        hasContentPendingObservation = WCSession.default.observe(\.hasContentPending) { _, _ in
            DispatchQueue.main.async {
                self.completeBackgroundTasks()
            }
        }

        // Activate the session asynchronously as early as possible.
        // In the case of being background launched with a task, this may save some background runtime budget.
        //
        WCSession.default.delegate = sessionDelegator
        WCSession.default.activate()

    }

    // Compelete the background tasks, and schedule a snapshot refresh.
    //
    func completeBackgroundTasks() {
        guard !wcBackgroundTasks.isEmpty else { return }

        guard WCSession.default.activationState == .activated,
            WCSession.default.hasContentPending == false else { return }

        wcBackgroundTasks.forEach { $0.setTaskCompletedWithSnapshot(false) }

        // Schedule a snapshot refresh if the UI is updated by background tasks.
        //
        let date = Date(timeIntervalSinceNow: 1)
        WKExtension.shared().scheduleSnapshotRefresh(withPreferredDate: date, userInfo: nil) { error in

            if let error = error {
              MyFunc.logMessage(.error, "scheduleSnapshotRefresh error: \(error)!")
            }
        }
        wcBackgroundTasks.removeAll()
    }

  // Be sure to complete all the tasks - otherwise they will keep consuming the background executing
  // time until the time is out of budget and the app is killed.
  //
  // WKWatchConnectivityRefreshBackgroundTask should be completed after the pending data is received
  // so retain the tasks first. The retained tasks will be completed at the following cases:
  // 1. hasContentPending flips to false, meaning all the pending data is received. Pending data means
  //    the data received by the device prior to the WCSession getting activated.
  //    More data might arrive, but it isn't pending when the session activated.
  // 2. The end of the handle method.
  //    This happens when hasContentPending can flip to false before the tasks are retained.
  //
  // If the tasks are completed before the WCSessionDelegate methods are called, the data will be delivered
  // the app is running next time, so no data lost.
  //
  func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
    for task in backgroundTasks {

      // Use Logger to log the tasks for debug purpose. A real app may remove the log
      // to save the precious background time.
      //
      if let wcTask = task as? WKWatchConnectivityRefreshBackgroundTask {
        wcBackgroundTasks.append(wcTask)
        MyFunc.logMessage(.debug, "\(#function):\(wcTask.description) was appended!")
      } else {
        task.setTaskCompletedWithSnapshot(false)
        MyFunc.logMessage(.debug, "\(#function):\(task.description) was completed!")
      }
    }
    completeBackgroundTasks()
  }

}
