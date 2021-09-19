//
//  ActivityViewController.swift
//  Heatmapper
//
//  Created by Richard English on 18/09/2021.
//  Copyright © 2021 Richard English. All rights reserved.
//

import UIKit

class ActivityViewController: UIViewController {

  let theme = ColourTheme()
  let defaults = UserDefaults.standard
  var activityToUpdate : Activity?

  @IBOutlet weak var activityNameLabel: UILabel!
  @IBOutlet weak var activityTableView: UITableView!


    override func viewDidLoad() {
      super.viewDidLoad()
      activityTableView.delegate = self
      activityTableView.dataSource = self
      activityTableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: activityTableView.frame.size.width, height: 1))

      MyFunc.logMessage(.debug, "activityToUpdate:\(String(describing: activityToUpdate))")
      activityNameLabel.text = activityToUpdate?.name

    }




}

extension ActivityViewController:  UITableViewDataSource, UITableViewDelegate {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return 1
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "ActivityTitleViewCell", for: indexPath)
    cell.textLabel?.text = activityToUpdate?.name

    activityTableView.reloadData()

    return cell
  }



}
