//
//  FilaDaBalsaViewController.swift
//  Filadabalsa
//
//  Created by Marcio Klepacz on 24/12/15.
//  Copyright © 2015 Marcio Klepacz. All rights reserved.
//

import UIKit
import KFSwiftImageLoader
import SwiftyJSON

class FilaDaBalsaViewController: UIViewController {
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var numberOfFerriesLabel: UILabel!
    @IBOutlet weak var lastUpdateLabel: UILabel!
    @IBOutlet weak var loadAndUnloadLabel: UILabel!
    @IBOutlet weak var infoTextView: UITextView!
    var cameraImages: [UIImageView] = []
    private var lastViewConstraints: NSArray?
    var ferryInfo: JSON = nil
    @IBOutlet weak var destinationAndLocationControl: UISegmentedControl!
    @IBOutlet weak var refreshButton: UIButton!
    @IBOutlet weak var pageControl: UIPageControl!
    
    var currentPage: Int {    // The index of the current page (readonly)
        get {
            let page = Int((self.self.scrollView.contentOffset.x / self.self.scrollView.bounds.size.width))
            
            return page
        }
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.scrollView.delegate = self
        self.scrollView.showsHorizontalScrollIndicator = false
        self.scrollView.showsVerticalScrollIndicator = false
        self.scrollView.pagingEnabled = true
        self.scrollView.backgroundColor = UIColor(red:0.4, green:0.85, blue:0.85, alpha:1)
        view.backgroundColor = UIColor(red:0.18, green:0.79, blue:0.78, alpha:1)
        UILabel.appearance().font = UIFont(name: "Bangla Sangam MN", size: 15)
        UILabel.appearance().textColor = UIColor.whiteColor()
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        self.automaticallyAdjustsScrollViewInsets = false
        infoTextView.contentInset = UIEdgeInsetsZero
        refreshButton.addTarget(self, action: "refreshTapped:", forControlEvents: .TouchUpInside)
        refreshButton.backgroundColor = UIColor(red:0.78, green:0.98, blue:0.98, alpha:1)
        
        destinationAndLocationControl.addTarget(self, action: "switchLocation:", forControlEvents: .ValueChanged)
        refreshInfo()
    }
    
    func refreshInfo(){
        let serverURL = NSURL(string: "http://dersa.herokuapp.com/ilhabela")!
        let request = NSMutableURLRequest(URL: serverURL)
        request.HTTPMethod = "GET"
        
        let session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
        let getFerryInfo = session.dataTaskWithRequest(request) { (data, response, error) in
            
            if error != nil {
                self.showNoConnectionAlert()
                
                return
            }
            
            self.ferryInfo = JSON(data: data!)
            
            dispatch_async(dispatch_get_main_queue()) {
                self.updateDersaInfo(self.destinationAndLocationControl.selectedSegmentIndex)
            }
        }
        
        getFerryInfo.resume()
    }
    
    func showNoConnectionAlert() {
       let alertController = UIAlertController(title: "Não foi possível conectar", message: "Verifique se o dispositivo esta conectado com a internet", preferredStyle: .Alert)
        let OKAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
        alertController.addAction(OKAction)
        
        presentViewController(alertController, animated: true, completion: nil)
    }
    
    func updateDersaInfo(selectedIndex: Int) {
        
        let infoBranchKey = selectedIndex == 0 ? "location" : "destination"
        
        self.loadAndUnloadLabel.text = "\(self.ferryInfo["waiting_minutes"][infoBranchKey].stringValue) min"
        self.numberOfFerriesLabel.text = self.ferryInfo["number_of_ferries"].stringValue
        self.lastUpdateLabel.text = self.ferryInfo["last_update"].stringValue
        
        for (index, imageJSON):(String, JSON) in self.ferryInfo["images"][infoBranchKey] {
            let isCameraImagesFull = cameraImages.count == self.ferryInfo["images"][infoBranchKey].count
            let imageView = isCameraImagesFull ? cameraImages[Int(index)!] : UIImageView(frame: self.scrollView.frame)
            imageView.backgroundColor = UIColor(red:0, green:0.72, blue:0.71, alpha:1)
            imageView.contentMode = .ScaleAspectFit
            let str = imageJSON.stringValue + "?v=\(NSUUID().UUIDString)"
            
            imageView.loadImageFromURL(NSURL(string: str)!)
            
            if !isCameraImagesFull {
                self.addImageToCarrousel(imageView)
            }
        }
        
        pageControl.numberOfPages = cameraImages.count
        pageControl.currentPage = self.currentPage
    }
    
    func switchLocation(segmentedControl: UISegmentedControl) {
        updateDersaInfo(segmentedControl.selectedSegmentIndex)
    }
    
    func refreshTapped(button: UIButton) {
       refreshInfo()
    }
    
    func addImageToCarrousel(imageView: UIImageView) {
        imageView.translatesAutoresizingMaskIntoConstraints = false
        cameraImages.append(imageView)

        scrollView.addSubview(imageView)
        
        let metric = ["w":CGRectGetWidth(imageView.bounds), "h":CGRectGetHeight(imageView.frame)]

        imageView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:[view(h)]", options:[], metrics: metric, views: ["view":imageView]))
        imageView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:[view(w)]", options:[], metrics: metric, views: ["view":imageView]))

        
        scrollView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-0-[view]-0-|", options:[], metrics: nil, views: ["view":imageView,]))

        
        if cameraImages.count == 1 {
            scrollView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-0-[view]", options:[], metrics: nil, views: ["view": imageView,]))
            
        } else {
            let previousImageView = cameraImages[cameraImages.count - 2]
            
            scrollView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:[previousView]-0-[view]", options:[], metrics: nil, views: ["previousView":previousImageView,"view":imageView]))
            
            if let lastViewConstraints = self.lastViewConstraints {
                let lastViewConstraints2: [NSLayoutConstraint]? = lastViewConstraints as? [NSLayoutConstraint]
                scrollView.removeConstraints(lastViewConstraints2!)
            }
            
            self.lastViewConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:[view]-0-|", options:[], metrics: nil, views: ["view":imageView])
            let lastViewConstraints2: [NSLayoutConstraint]? = self.lastViewConstraints as? [NSLayoutConstraint]
            scrollView.addConstraints(lastViewConstraints2!)
        }
        
        scrollView.contentSize.width = scrollView.contentSize.width + CGRectGetWidth(imageView.frame)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
    }
}

//MARK: - UIScrollViewDelegate

extension FilaDaBalsaViewController: UIScrollViewDelegate {
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        pageControl.currentPage = currentPage
        
    }
//
//    internal func scrollViewDidScroll(scrollView: UIScrollView) {
//        
//        for index in 0..<cameraImages.count {
//            
//            if let imageView = cameraImages[index] as? UIImageView {
//                
//                let mx = ((self.scrollView.contentOffset.x + self.view.bounds.size.width) - (view.bounds.size.width * CGFloat(index))) / self.view.bounds.size.width
//                
//                // While sliding to the "next" slide (from right to left), the "current" slide changes its offset from 1.0 to 2.0 while the "next" slide changes it from 0.0 to 1.0
//                // While sliding to the "previous" slide (left to right), the current slide changes its offset from 1.0 to 0.0 while the "previous" slide changes it from 2.0 to 1.0
//                // The other pages update their offsets whith values like 2.0, 3.0, -2.0... depending on their positions and on the status of the walkthrough
//                // This value can be used on the previous, current and next page to perform custom animations on page's subviews.
//                
//                // print the mx value to get more info.
//                // println("\(index):\(mx)")
//                
//                
//                // We animate only the previous, current and next page
////                if(mx < 2 && mx > -2.0){
////                    imageView.introDidScroll?(self.scrollView.contentOffset.x, offset: mx, scrollCompleted: (mx == 1.0))
////                }
//            }
//            
//        }
//        
//    }
//    
}
