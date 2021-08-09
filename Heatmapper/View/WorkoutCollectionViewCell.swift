//
//  WorkoutCollectionViewCell.swift
//  Heatmapper
//
//  Created by Richard English on 03/08/2021.
//  Copyright © 2021 Richard English. All rights reserved.
//

import UIKit

class WorkoutCollectionViewCell: UICollectionViewCell {

  @IBOutlet weak var heatmapImageView: UIImageView!
  @IBOutlet weak var workoutDateLabel: ThemeSmallTextUILabel!
  @IBOutlet weak var workoutTypeLabel: ThemeSmallTextUILabel!




  override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

}
