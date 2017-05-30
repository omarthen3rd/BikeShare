//
//  PopViewController.swift
//  Bike Share
//
//  Created by Omar Abbasi on 2017-05-25.
//  Copyright © 2017 Omar Abbasi. All rights reserved.
//

import UIKit
import LNPopupController

class PopViewController: LNPopupCustomBarViewController {

    @IBOutlet var numberOfBikes: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        preferredContentSize = CGSize(width: -1, height: 80)
        wantsDefaultPanGestureRecognizer = false
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func popupItemDidUpdate() {
        numberOfBikes.text = containingPopupBar.popupItem?.title
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
