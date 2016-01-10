//
//  ViewController.swift
//  Filadabalsa
//
//  Created by Marcio Klepacz on 24/12/15.
//  Copyright © 2015 Marcio Klepacz. All rights reserved.
//

import UIKit

class AboutViewController: UIViewController {

    @IBOutlet weak var textView: UITextView!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        textView.contentInset = UIEdgeInsetsZero
        self.automaticallyAdjustsScrollViewInsets = false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

