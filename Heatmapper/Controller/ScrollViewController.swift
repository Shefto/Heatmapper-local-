//
//  ScrollViewController.swift
//  FIT
//
//  Created by Richard English on 21/01/2021.
//  Copyright © 2021 Richard English. All rights reserved.
//

import UIKit

class ScrollViewController: UIViewController, UIScrollViewDelegate {

  @IBOutlet weak var scrollView: UIScrollView!
  @IBOutlet weak var pageControl: UIPageControl!
  var frame = CGRect(x: 0, y: 0, width: 0, height: 0)

  override func viewDidLoad() {
        super.viewDidLoad()

    let contentWidth = scrollView.bounds.width * 3
    let contentHeight = scrollView.bounds.height
    scrollView.contentSize = CGSize(width: contentWidth, height: contentHeight)

    frame.origin.x = scrollView.frame.size.width
    frame.size = scrollView.frame.size

    //3
    var frame1 = frame
    frame1.origin.x = 0
    let view1 = UIView(frame: frame1)
    view1.backgroundColor = .blue

    var frame2 = frame
    frame2.origin.x = scrollView.frame.size.width
    let view2 = UIView(frame: frame2)
    view2.backgroundColor = .yellow

    var frame3 = frame
    frame3.origin.x = scrollView.frame.size.width * 2

    let view3 = UIView(frame: frame3)
    view3.backgroundColor = .systemGreen

    MyFunc.logMessage(.debug, "view3.frame: \(view3.frame)")
    MyFunc.logMessage(.debug, "view3.bounds: \(view3.bounds)")
    scrollView.addSubview(view1)
    scrollView.addSubview(view2)
    scrollView.addSubview(view3)

    // lay out the view


    //4
    scrollView.contentSize = CGSize(width:self.scrollView.frame.width * 3, height:self.scrollView.frame.height)




    }




}
