//
//  EventsViewController.ReferenceDataViewController
//  Heatmapper
//
//  Created by Richard English on 28/08/2021.
//  Copyright © 2021 Richard English. All rights reserved.
//

import UIKit

class ReferenceDataViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

  let theme = ColourTheme()
  let defaults = UserDefaults.standard
  private var eventsArray = [String]()


  var selectedIndexPath : Int? = 0


  @IBOutlet weak var eventTableView: ThemeTableViewNoBackground!


  

  override func viewDidLoad() {
    super.viewDidLoad()

    eventTableView.dataSource = self
    eventTableView.delegate = self
    eventTableView.allowsSelection = true

    //    eventTableView.register(UITableViewCell.self, forCellReuseIdentifier: "eventCell")
    eventTableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: eventTableView.frame.size.width, height: 1))
    eventTableView.tableHeaderView?.backgroundColor = UIColor.clear

    eventsArray = defaults.stringArray(forKey: "Events") ?? []

    eventsArray.append("This is a test")

    MyFunc.logMessage(.debug, "eventsArray: \(eventsArray)")
    eventTableView.reloadData()
  }


  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return eventsArray.count
  }


  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

    let cell = eventTableView.dequeueReusableCell(withIdentifier: "eventCell", for: indexPath)
    cell.textLabel?.text = eventsArray[indexPath.row]
    return cell
  }


  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: false)
    //    eventId = eventsArray?[indexPath.row]
    //    MyFunc.logMessage(.debug, "eventId: \(String(describing: eventId))")
    selectedIndexPath = indexPath.row
    self.eventTableView.reloadData()

  }

  func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {

    selectedIndexPath = nil
    self.eventTableView.reloadData()
  }


  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

    let segueToUse = segue.identifier

    //    if segueToUse == "historyToDTMHeatmap" {
    //      let destinationVC = segue.destination as! DTMHeatmapViewController
    //      destinationVC.heatmapWorkoutId = (sender as! UUID)
    //    }

    navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
  }

}
