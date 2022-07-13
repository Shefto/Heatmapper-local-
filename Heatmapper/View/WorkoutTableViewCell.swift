//
//  WorkoutTableViewCell.swift
//  
//
//  Created by Richard English on 12/07/2022.
//

import UIKit

class WorkoutTableViewCell: ThemeTableViewCellNoBackground {

  @IBOutlet weak var activity: UILabel!

  @IBOutlet weak var Date: UILabel!


  @IBOutlet weak var heartRate: UILabel!
  @IBOutlet weak var speed: UILabel!
  @IBOutlet weak var calories: UILabel!
  @IBOutlet weak var distance: UILabel!

}
