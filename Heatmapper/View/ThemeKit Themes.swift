//
//  ThemeKit Themes.swift
//  Number Ten
//
//  Created by Richard English on 22/04/2020.
//  Copyright © 2020 Richard English. All rights reserved.
//
//   taken from https://basememara.com/protocol-oriented-themes-for-ios-apps/
//  Created by Basem Emara on 2018-09-27.
//  Copyright © 2018 Basem Emara. All rights reserved.
//

import UIKit

struct ColourTheme: Theme {

  var textPrimary: UIColor    = UIColor(named: "textPrimary")!
  var textSecondary: UIColor  = UIColor(named: "textSecondary")!
  var buttonPrimary: UIColor  = UIColor(named: "buttonPrimary")!
  var background: UIColor     = UIColor(named: "background")!
  var navBar: UIColor         = UIColor(named: "navBar")!
  var navBarTitle: UIColor   = UIColor(named: "navBarTitle")!
  var navBarTint: UIColor    = UIColor(named: "navBarTint")!
  var textAlternate: UIColor  = UIColor(named: "textAlternate")!
  var backgroundWithAlpha: UIColor  = UIColor(named: "backgroundWithAlpha")!

  var separatorColor: UIColor = .separator
  var barStyle: UIBarStyle = .default

}
