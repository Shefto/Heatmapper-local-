//
//  Theme App Classes.swift
//  Number Ten
//
//  Created by Richard English on 22/04/2020.
//  Copyright © 2020 Richard English. All rights reserved.

import UIKit

// UIViews
class ThemeView: UIView {}
class ThemeShadowView : UIView {

  override func layoutSubviews() {
    super.layoutSubviews()
    setupAppearance()
  }

  private func setupAppearance() {

    let roundedPath = UIBezierPath(roundedRect: layer.bounds, cornerRadius: 9)
    layer.shadowPath = roundedPath.cgPath
    layer.shadowColor = UIColor.systemGray.cgColor
    layer.shadowOffset = CGSize(width: 3, height: 3)
    layer.shadowRadius = 1
    layer.shadowOpacity = 1
    layer.cornerRadius = 9
  }

}

// UIButtons
class ThemeButton: UIButton {
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = 6
    }
}
class ThemeActionButton: UIButton {}

// UILabels
class ThemeColumnHeaderUILabel: UILabel {}
class ThemeLargeNumericUILabel: UILabel {}
class ThemeVeryLargeNumericUILabel: UILabel {}
class ThemeMediumNumericUILabel: UILabel {}
class TableRowNameUILabel: UILabel {}
class ThemeSmallTextUILabel: UILabel {}
class ThemeVeryLargeFontUILabel: UILabel {}

// Text View
class ThemeTextView: UITextView {}

class ThemePickerView: UIPickerView {}

// UITableView and related
class ThemeTableViewNoBackground: UITableView {}
class ThemeTableViewCellNoBackground: UITableViewCell {}

// UISegmentedControl
class ThemeSegmentedControl: UISegmentedControl {}
