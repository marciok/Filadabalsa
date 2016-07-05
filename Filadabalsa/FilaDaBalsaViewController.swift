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
    @IBOutlet weak var destinationAndLocationControl: UISegmentedControl!
    @IBOutlet weak var refreshButton: UIButton!
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var countDownView: UIView!
    
    var cameraImages: [UIImageView] = []
    private var lastViewConstraints: NSArray?
    var ferryInfo: JSON = nil
    var progressCircle: CAShapeLayer!
    var countDownSecondTimer: NSTimer!
    var infoBranchKey: String!
    
    var currentPage: Int {    // The index of the current page (readonly)
        get {
            return Int((self.self.scrollView.contentOffset.x / self.self.scrollView.bounds.size.width))
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        countDownSecondTimer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: #selector(FilaDaBalsaViewController.countdownSeconds), userInfo: nil, repeats: true)
        
        NSNotificationCenter.defaultCenter().addObserverForName("kApplicationDidBecomeActive", object: nil, queue: nil) { notification in
            self.refreshInfo()
            
        }
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Sobre", style: .Plain, target: self, action: #selector(FilaDaBalsaViewController.aboutTapped))
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Action, target: self, action: #selector(FilaDaBalsaViewController.shareAppTapped))
    
        progressCircle = CAShapeLayer();
        
        let centerPoint = CGPoint (x: countDownView.bounds.width / 2, y: countDownView.bounds.width / 2);
        let circleRadius : CGFloat = countDownView.bounds.width / 2 * 0.83;
        
        let circlePath = UIBezierPath(arcCenter: centerPoint, radius: circleRadius, startAngle: CGFloat(-0.5 * M_PI), endAngle: CGFloat(1.5 * M_PI), clockwise: true    );
        
        progressCircle = CAShapeLayer();
        progressCircle.path = circlePath.CGPath;
        progressCircle.strokeColor = UIColor.whiteColor().CGColor;
        progressCircle.fillColor = UIColor(red:0.4, green:0.85, blue:0.85, alpha:1).CGColor;
        progressCircle.lineWidth = 2.5;
        progressCircle.strokeStart = 0;
        progressCircle.strokeEnd = 1;
        
        countDownView.layer.addSublayer(progressCircle);

        self.scrollView.delegate = self
        self.scrollView.showsHorizontalScrollIndicator = false
        self.scrollView.showsVerticalScrollIndicator = false
        self.scrollView.pagingEnabled = true
        self.scrollView.backgroundColor = UIColor(red:0.4, green:0.85, blue:0.85, alpha:1)
        
        view.backgroundColor = UIColor(red:0.18, green:0.79, blue:0.78, alpha:1)
        
        navigationController?.navigationBar.tintColor = UIColor(red:0, green:0.72, blue:0.71, alpha:1)
        refreshButton.tintColor = UIColor(red:0, green:0.72, blue:0.71, alpha:1)
        
        UILabel.appearance().font = UIFont(name: "Bangla Sangam MN", size: 15)
        UILabel.appearance().textColor = UIColor.whiteColor()
        
        UITextView.appearance().font = UIFont(name: "Bangla Sangam MN", size: 15)
        UITextView.appearance().textColor = UIColor.whiteColor()
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        self.automaticallyAdjustsScrollViewInsets = false
        infoTextView.contentInset = UIEdgeInsetsZero
        infoTextView.backgroundColor = UIColor(red:0, green:0.72, blue:0.71, alpha:1)
        infoTextView.linkTextAttributes = [NSForegroundColorAttributeName: UIColor.whiteColor(), NSUnderlineStyleAttributeName: 1]
        refreshButton.addTarget(self, action: #selector(FilaDaBalsaViewController.refreshTapped(_:)), forControlEvents: .TouchUpInside)
        refreshButton.backgroundColor = UIColor(red:0.78, green:0.98, blue:0.98, alpha:1)
        activityIndicator.hidesWhenStopped = true

        destinationAndLocationControl.addTarget(self, action: #selector(FilaDaBalsaViewController.switchLocation(_:)), forControlEvents: .ValueChanged)
        
        activityIndicator.startAnimating()
        refreshInfo()
        
        self.view.sendSubviewToBack(scrollView)
    }
    
    func refreshInfo(){
        activityIndicator.startAnimating()
        refreshButton.enabled = false
        
        let serverURL = NSURL(string: "https://dersa.herokuapp.com/ilhabela")!
        let request = NSMutableURLRequest(URL: serverURL)
        request.HTTPMethod = "GET"
        
        let session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
        let getFerryInfo = session.dataTaskWithRequest(request) { (data, response, error) in
            
            guard let r = response as? NSHTTPURLResponse else {
                return
            }
            
            if error != nil || r.statusCode != 200 {
                dispatch_async(dispatch_get_main_queue()) {
                    self.refreshButton.enabled = true
                    self.showNoConnectionAlert()
                }
            }
            
            if let data = data {
                self.ferryInfo = JSON(data: data)
            }
            
            dispatch_async(dispatch_get_main_queue()) {
                self.refreshButton.enabled = true
                self.updateDersaInfo(self.destinationAndLocationControl.selectedSegmentIndex)
            }
        }
        
        getFerryInfo.resume()
    }
    
    func showNoConnectionAlert(title: String = "Não foi possível conectar") {
       let alertController = UIAlertController(title: title, message: "Verifique a conexão com a internet de seu dispositivo", preferredStyle: .Alert)
        let OKAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
        alertController.addAction(OKAction)
        
        presentViewController(alertController, animated: true, completion: nil)
    }
    
    func updateDersaInfo(selectedIndex: Int) {
        
        infoBranchKey = selectedIndex == 0 ? "location" : "destination"
        
        if infoBranchKey == "location" {
            view.backgroundColor = UIColor(red:0.18, green:0.79, blue:0.78, alpha:1)
            scrollView.backgroundColor = UIColor(red:0.4, green:0.85, blue:0.85, alpha:1)
            progressCircle.fillColor = UIColor(red:0.4, green:0.85, blue:0.85, alpha:1).CGColor
            
            infoTextView.backgroundColor = UIColor(red:0, green:0.72, blue:0.71, alpha:1)
            refreshButton.backgroundColor = UIColor(red:0.78, green:0.98, blue:0.98, alpha:1)
            refreshButton.tintColor = UIColor(red:0, green:0.72, blue:0.71, alpha:1)
            
        } else {
            view.backgroundColor = UIColor(red:0.81, green:0.55, blue:0.31, alpha:1)
            
            scrollView.backgroundColor = UIColor(red:0.75, green:0.49, blue:0.27, alpha:1)
            progressCircle.fillColor = UIColor(red:0.75, green:0.49, blue:0.27, alpha:1).CGColor
            
            infoTextView.backgroundColor = UIColor(red:0.75, green:0.49, blue:0.27, alpha:1)
            refreshButton.backgroundColor = UIColor(red:0.83, green:0.65, blue:0.41, alpha:1)
            refreshButton.tintColor = UIColor(red:0.52, green:0.31, blue:0.16, alpha:1)
        }
        
        self.navigationController?.navigationBar.tintColor = refreshButton.tintColor
        
        self.loadAndUnloadLabel.text = "\(self.ferryInfo["waiting_minutes"][infoBranchKey].stringValue) min"
        self.numberOfFerriesLabel.text = self.ferryInfo["number_of_ferries"].stringValue
        self.lastUpdateLabel.text = self.ferryInfo["last_update"].stringValue
        infoTextView.text = self.ferryInfo["information"].stringValue
        
        numberOfFerriesLabel.attributedText = NSAttributedString(string: numberOfFerriesLabel.text!, attributes: [NSFontAttributeName: UIFont.boldSystemFontOfSize(15)])
        loadAndUnloadLabel.attributedText = NSAttributedString(string: loadAndUnloadLabel.text!, attributes: [NSFontAttributeName: UIFont.boldSystemFontOfSize(15)])

        lastUpdateLabel.attributedText = NSAttributedString(string: lastUpdateLabel.text!, attributes: [NSFontAttributeName: UIFont.boldSystemFontOfSize(15)])

        
        for (index, imageJSON):(String, JSON) in self.ferryInfo["images"][infoBranchKey] {
            let isCameraImagesFull = cameraImages.count == self.ferryInfo["images"][infoBranchKey].count
            let imageView = isCameraImagesFull ? cameraImages[Int(index)!] : UIImageView(frame: self.scrollView.frame)
            
            imageView.backgroundColor = infoTextView.backgroundColor
            
            imageView.contentMode = .ScaleAspectFit
            let str = imageJSON.stringValue + "?v=\(NSUUID().UUIDString)"
            
            imageView.loadImageFromURL(NSURL(string: str)!, placeholderImage: nil) {
                (finished, error) in
                
                if finished {
                    self.activityIndicator.stopAnimating()
                }
                
                if error != nil {
                    self.activityIndicator.stopAnimating()
                    self.showNoConnectionAlert("Não possível baixar a imagem")
                }
            }
            
            if !isCameraImagesFull {
                self.addImageToCarrousel(imageView)
            }
        }
        
        pageControl.numberOfPages = cameraImages.count
        pageControl.currentPage = self.currentPage
    }
    
    func switchLocation(segmentedControl: UISegmentedControl) {
        self.activityIndicator.startAnimating()
        updateDersaInfo(segmentedControl.selectedSegmentIndex)
    }
    
    func refreshTapped(button: UIButton) {
        refreshInfo()
    }
    
    func countdownSeconds(){
        progressCircle.strokeStart = progressCircle.strokeStart + 0.016
        
        if progressCircle.strokeStart > 1 {
           progressCircle.strokeStart = 0
           refreshInfo()
        }
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
    
    func shareAppTapped() {
        let string = "Embarque em \(infoBranchKey == "location" ? "Ilhabela" : "São Sebastião") esta com \(self.ferryInfo["waiting_minutes"][infoBranchKey].stringValue) min de espera - Veja a fila da balsa ao vivo pelo app 'Fila da Balsa' "
        let url = NSURL(string:"http://bit.ly/filadabalsa")
        
        let activityViewController = UIActivityViewController(activityItems: [string, url!], applicationActivities: nil)
        presentViewController(activityViewController, animated: true, completion: nil)
    }
    
    func aboutTapped(){
        let aboutViewController = self.storyboard?.instantiateViewControllerWithIdentifier("AboutViewController")
        navigationController?.pushViewController(aboutViewController!, animated: true)
    }
}

//MARK: - UIScrollViewDelegate

extension FilaDaBalsaViewController: UIScrollViewDelegate {
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        pageControl.currentPage = currentPage
        
    }
}
