//
//  ActivityTableViewCell.swift
//  Heatmapper
//
//  Created by Richard English on 30/08/2021.
//  Copyright © 2021 Richard English. All rights reserved.
//

import UIKit

protocol ActivityTableViewCellDelegate: AnyObject {

  func updateSportForActivity(newSport: Sport, indexPathRow: Int)

}

class ActivityTableViewCell: ThemeTableViewCellNoBackground {

  weak var delegate : ActivityTableViewCellDelegate?

  @IBOutlet weak var activityLabel: TableRowNameUILabel!

  @IBOutlet weak var sportLabel: TableRowNameUILabel!


  var sportArray = [String]()

  override func layoutSubviews() {
    super.layoutSubviews()

    contentView.frame = contentView.frame.inset(by: UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 0))
  }



  override func awakeFromNib() {
    super.awakeFromNib()
  }
}
