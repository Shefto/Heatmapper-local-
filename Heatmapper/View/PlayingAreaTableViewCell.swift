//
//  PlayingAreaTableViewCell.swift
//  Heatmapper
//
//  Created by Richard English on 11/07/2022.
//  Copyright © 2022 Richard English. All rights reserved.
//

import UIKit

class PlayingAreaTableViewCell: ThemeTableViewCellNoBackground {

  @IBOutlet weak var workoutCountLabel: UILabel!
  @IBOutlet weak var visibilityLabel: UILabel!
  @IBOutlet weak var playingAreaNameLabel: UILabel!
  @IBOutlet weak var venueLabel: UILabel!

  override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
