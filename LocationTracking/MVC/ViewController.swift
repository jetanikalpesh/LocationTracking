//
//  ViewController.swift
//  LocationTracking
//
//  Created by jetani kalpesh on 08/10/17.
//  Copyright © 2017 sigmacoder. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    @IBAction func switchTrackRouteDidChanged(_ swt: UISwitch) {
        LocationUtility.shared.isTracking = swt.isOn
    }


}

