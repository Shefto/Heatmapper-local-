//
//  FileTransferObservers.swift
//  FIT
//
//  Created by Richard English on 10/07/2020.
//  Copyright © 2020 Richard English. All rights reserved.
//

import Foundation
import WatchConnectivity

// Manage the observation of file transfers.
class FileTransferObservers {

    // Hold the observations and file transfers.
    // KVO will be removed automatically after observations are released.
    private(set) var fileTransfers = [WCSessionFileTransfer]()
    private var observations = [NSKeyValueObservation]()

    // Invalidate all the observations.
    deinit {
        observations.forEach { observation in
            observation.invalidate()
        }
    }

    // Observe a file transfer, hold the observation.
    func observe(_ fileTransfer: WCSessionFileTransfer, handler: @escaping (Progress) -> Void) {
        let observation = fileTransfer.progress.observe(\.fractionCompleted) { progress, _ in
            handler(progress)
        }
        observations.append(observation)
        fileTransfers.append(fileTransfer)
    }

    // Unobserve a file transfer, invalidate the observation.
    func unobserve(_ fileTransfer: WCSessionFileTransfer) {
        guard let index = fileTransfers.firstIndex(of: fileTransfer) else { return }
        let observation = observations.remove(at: index)
        observation.invalidate()
        fileTransfers.remove(at: index)
    }
}
