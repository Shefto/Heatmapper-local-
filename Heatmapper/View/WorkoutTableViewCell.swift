//
//  WorkoutTableViewCell.swift
//  Heatmapper
//
//  Created by Richard English on 15/05/2021.
//  Copyright © 2021 Richard English. All rights reserved.
//

import UIKit

class WorkoutTableViewCell: ThemeTableViewCellNoBackground {

  @IBOutlet weak var activityType: UILabel!
  @IBOutlet weak var activityDate: UILabel!

  @IBOutlet weak var heartRateLabel: UILabel!
  @IBOutlet weak var caloriesLabel: UILabel!
  
  @IBOutlet weak var speedLabel: UILabel!
  @IBOutlet weak var distanceLabel: UILabel!

  @IBOutlet weak var heartImageView: UIImageView!
  @IBOutlet weak var caloriesImageView: UIImageView!
  @IBOutlet weak var speedometerImageView: UIImageView!
  @IBOutlet weak var distanceImageView: UIImageView!
  
//  override func awakeFromNib() {
//    super.awakeFromNib()
//
//    heartImage.tintColor = UIColor.red
//  }

}
