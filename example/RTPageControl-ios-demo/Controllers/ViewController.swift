//
//  ViewController.swift
//  RTPageControl-ios
//
//  Created by Daniyar Salakhutdinov on 01.09.16.
//  Copyright © 2016 Runtime LLC. All rights reserved.
//

import UIKit
import RTPageControl_ios

class ViewController: UIViewController, UIScrollViewDelegate {
    
    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet private weak var pageControl: RTPageControl!

    override func viewDidLoad() {
        super.viewDidLoad()
        // setup page control
        pageControl.activeDotColor = UIColor.whiteColor()
        pageControl.passiveDotColor = UIColor.blackColor()
        pageControl.numberOfPages = 5
    }
    
    // MARK: - scroll view delegate methods
    func scrollViewDidScroll(scrollView: UIScrollView) {
        // get current page index
        let width = CGRectGetWidth(scrollView.bounds)
        let pageIndex = (scrollView.contentOffset.x) / width
        let index = Int(pageIndex)
        // get float difference value
        let offset = pageIndex - CGFloat(index)
        if pageIndex >= 0 && pageControl.currentPage != index {
            pageControl.currentPage = index
        }
        // set offset
        pageControl.setOffset(offset)
    }
}

