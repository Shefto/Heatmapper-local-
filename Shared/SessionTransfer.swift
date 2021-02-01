//
//  SessionTransfer.swift
//  FIT
//
//  Created by Richard English on 10/07/2020.
//  Copyright © 2020 Richard English. All rights reserved.
//

import Foundation
import WatchConnectivity

// Provide a unified interface for transfers. UI uses this interface to manage transfers.
protocol SessionTransfer {

  var isTransferring: Bool { get }
  func cancel()
  func cancel(notifying command: Command)
}

// Implement the cancel method to cancel the transfer and notify UI.
extension SessionTransfer {
  func cancel(notifying command: Command) {

    cancel()

  }
}
