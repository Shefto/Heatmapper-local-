//
//  Interval.swift
//  FIT
//
//  Created by Richard English on 27/06/2020.
//  Copyright © 2020 Richard English. All rights reserved.

import Foundation

// Base Interval structure used to record data
struct Interval {

    var startDate: Date?
    var endDate: Date?
    var duration: DateInterval?
    var distance: NSNumber = 0
    var pace: NSNumber = 0
    var activity: String = ""
    var cadence: NSNumber = 0
    var steps: NSNumber = 0

}
