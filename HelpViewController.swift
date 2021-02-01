//
//  HelpViewController.swift
//  FIT
//
//  Created by Richard English on 13/01/2021.
//  Copyright © 2021 Richard English. All rights reserved.
//

import UIKit

class HelpViewController: UIViewController {

  @IBOutlet weak var helpTextView: ThemeTextView!
  var helpTextArray = [NSAttributedString]()
  override func viewDidLoad() {
    super.viewDidLoad()

    let language = Locale.current.languageCode

    switch language {
    case "es-ES":
      let headline = NSAttributedString(string: "Como usar")
      helpTextArray.append(headline)

    default:


      var helpTextArray = [NSAttributedString]()
      let headline = NSAttributedString(string: "How to use\n")
      helpTextArray.append(headline)

      helpTextArray.append(NSAttributedString(string: "To start a workout, click the Start Workout button. The timer will begin recording your activity after a three-second countdown.\n"))
      helpTextArray.append(NSAttributedString(string: "Three types of activity are recorded:\n"))
      helpTextArray.append(NSAttributedString(string: "  •  Running"))
      helpTextArray.append(NSAttributedString(string: "  •  Walking"))
      helpTextArray.append(NSAttributedString(string: "  •  Stationary (i.e. no movement)\n"))
      helpTextArray.append(NSAttributedString(string: "Changes in activity are detected and recorded automatically. You choose for how long you wish to run and for how long you wish to rest. The app will sense when your activity type changes and record intervals accordingly.\n\nNote that there may be a slight delay between you finishing the activity type and it being displayed on screen. This is due to the way the device’s activity monitoring works.\n\nSwipe right to view the completed intervals on the Apple Watch. Swipe left to access the pause, resume and stop resume buttons.\nYou can pause and resume the activity at any time using the pause and resume buttons. When you are finished, click the stop button to save the workout.\n\nThe workout is automatically recorded in your Health data and can be viewed in the Apple Health app. Each individual segment is recorded together with the workout route.\n\nPrivacy Policy : https://www.iubenda.com/privacy-policy/39192677"))
      let newString = helpTextArray.join(withSeparator: NSAttributedString(string: "\n"))
      MyFunc.logMessage(.debug, (String(describing: newString)))
      helpTextView.attributedText = newString

    }

  }



}
