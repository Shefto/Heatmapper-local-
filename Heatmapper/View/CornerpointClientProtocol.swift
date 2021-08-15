//
//  CornerpointClientProtocol.swift
//  Heatmapper
//
//  Created by Richard English on 15/08/2021.
//  Copyright © 2021 Richard English. All rights reserved.
//

import Foundation

@objc protocol CornerpointClientProtocol
{
  func cornerHasChanged(_: CornerpointView)
}

