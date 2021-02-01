//
//  CommandStatus.swift
//  FIT
//
//  Created by Richard English on 10/07/2020.
//  Copyright © 2020 Richard English. All rights reserved.
//  Abstract:
//  CommandStatus struct wraps the command status. Used on both iOS and watchOS.

import UIKit
import WatchConnectivity

// Constants to identify the Watch Connectivity methods, also used as user-visible strings in UI.

enum Command: String {
    case transferFile = "TransferFile"
    case updateDefaults = "UpdateDefaults"
    case updateAppContext = "UpdateAppContext"
}

// Constants to identify the phrases of a Watch Connectivity communication.
enum Phrase: String {
    case updated = "Updated"
    case sent = "Sent"
    case received = "Received"
    case replied = "Replied"
    case transferring = "Transferring"
    case canceled = "Cancelled"
    case finished = "Finished"
    case failed = "Failed"
}

// Wrap the command status to bridge the commands status and UI.
struct CommandStatus {
    var command: Command
    var phrase: Phrase
    var fileTransfer: WCSessionFileTransfer?
    var file: WCSessionFile?
    var errorMessage: String?
    var userInfoTranser: WCSessionUserInfoTransfer?

    init(command: Command, phrase: Phrase) {
        self.command = command
        self.phrase = phrase
    }
}
