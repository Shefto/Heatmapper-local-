//
//  Theme.swift
//  Number Ten
//
//  Created by Richard English on 22/04/2020.
//  Copyright © 2020 Richard English. All rights reserved.
//
// This code declares the Theme protocol and defines the appearance of each UI element
//

import UIKit

protocol Theme {

  var textPrimary: UIColor { get }
  var textSecondary: UIColor { get }
  var buttonPrimary: UIColor { get }
  var navBar: UIColor { get }
  var background: UIColor { get }
  var navBarTitle: UIColor { get }
  var navBarTint: UIColor { get }
  var separatorColor: UIColor { get }
  var barStyle: UIBarStyle { get }
  var textAlternate: UIColor { get }
  func apply(for application: UIApplication)

}

extension Theme {

  func apply(for application: UIApplication) {


    // ********************************************************************************
    // UILabels
    // ********************************************************************************

    ThemeVeryLargeFontUILabel.appearance().with {
      let themeFont = UIFont.systemFont(ofSize: 48.0, weight: .regular)
      $0.font = themeFont
      $0.textColor = textAlternate
    }

    ThemeVeryLargeNumericUILabel.appearance().with {
      let themeFont = UIFont.monospacedDigitSystemFont(ofSize: 48.0, weight: .regular)
      $0.font = themeFont
      $0.textColor = textPrimary
    }

    ThemeLargeFontUILabel.appearance().with {
      let themeFont = UIFont.systemFont(ofSize: 24.0, weight: .regular)
      $0.font = themeFont
      $0.textColor = textAlternate
    }

    ThemeLargeNumericUILabel.appearance().with {
      let themeFont = UIFont.monospacedDigitSystemFont(ofSize: 24.0, weight: .regular)
      $0.font = themeFont
      $0.textColor = textPrimary
    }

    ThemeMediumFontUILabel.appearance().with {
      let themeFont = UIFont.systemFont(ofSize: 22.0, weight: .regular)
      $0.font = themeFont
      $0.textColor = textAlternate
    }

    ThemeMediumNumericUILabel.appearance().with {
      let themeFont = UIFont.monospacedDigitSystemFont(ofSize: 22.0, weight: .regular)
      $0.font = themeFont
      $0.textColor = textPrimary
    }

    ThemeColumnHeaderUILabel.appearance().with {
      $0.font = UIFont.preferredFont(forTextStyle: .title2)
      $0.textColor = textAlternate
    }

    ThemeSmallTextUILabel.appearance().with {
      let themeFont = UIFont.systemFont(ofSize: 12.0, weight: .regular)
      $0.font = themeFont
    }


    TableRowNameUILabel.appearance().with {
      $0.font = UIFont.preferredFont(forTextStyle: .title2)
      $0.textColor = textAlternate
    }


    // UITextField
   ThemeTextField.appearance().with {
      $0.backgroundColor = background
      $0.textColor = textPrimary
    let themeFont = UIFont.systemFont(ofSize: 24.0, weight: .regular)
    $0.font = themeFont
    $0.textColor = textAlternate
    }

    // ********************************************************************************
    // UIViews
    // ********************************************************************************
    ThemePickerView.appearance().with {
      $0.tintColor = textPrimary
    }

    ThemeTextView.appearance().with {
      $0.textColor = textAlternate
      $0.backgroundColor = background
    }

    ThemeView.appearance().backgroundColor = background
    ThemeShadowView.appearance().backgroundColor = background

    // ********************************************************************************
    // UIButtons
    // ********************************************************************************
    ThemeButton.appearance().with {
      $0.setTitleColor(navBarTint, for: .normal)
      $0.setTitleColor(navBarTint.withAlphaComponent(0.3), for: .disabled)
      $0.backgroundColor = buttonPrimary
    }

    ThemeActionButton.appearance().with {
      $0.tintColor = buttonPrimary
    }

    // ********************************************************************************
    // UINavigationBar
    // ********************************************************************************
    let navBarAppearance = UINavigationBarAppearance()
    let navBarFont = UIFont.preferredFont(forTextStyle: .title2)
    navBarAppearance.with {
      $0.configureWithOpaqueBackground()

      $0.backgroundColor = navBar
      $0.titleTextAttributes = [.font: navBarFont, .foregroundColor: navBarTitle as Any]

      if #available(iOS 11.0, *) {
        $0.largeTitleTextAttributes = [.font: navBarFont as Any, .foregroundColor: navBarTitle as Any]
      }
    }

    UINavigationBar.appearance(whenContainedInInstancesOf: [UINavigationController.self]).with {
      $0.standardAppearance = navBarAppearance
      $0.tintColor = navBarTint
    }

    // UISegmentedControl
    let segFont = UIFont.preferredFont(forTextStyle: .title1)
    ThemeSegmentedControl.appearance().with {
      $0.setTitleTextAttributes([.font: segFont], for: .normal)

    }

    ThemeTableViewNoBackground.appearance().with {
      $0.backgroundColor = background
    }
    ThemeTableViewCellNoBackground.appearance().with {
      $0.backgroundColor = background
    }

    // ensure existing views render with new theme
    application.windows.reload()
  }

}
