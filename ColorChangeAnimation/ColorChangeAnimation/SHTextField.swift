//
//  SHTextField.swift
//  SHTipCalculator
//
//  Created by Sruti Harikumar on 6/1/16.
//  Copyright © 2016 Sruti. All rights reserved.
//

import Foundation
import UIKit

class SHTextfield: UITextField {
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        
        let bottomBorder = CALayer()
        bottomBorder.frame = CGRectMake(0.0,self.frame.size.height - 2.0, self.frame.size.width, 0.5)
        bottomBorder.backgroundColor = UIColor.whiteColor().CGColor
        self.layer.addSublayer(bottomBorder)
        
        let leftBorder = CALayer()
        leftBorder.frame = CGRectMake(0.0,self.frame.size.height - 10.0, 0.5, 8.0)
        leftBorder.backgroundColor = UIColor.whiteColor().CGColor
        self.layer.addSublayer(leftBorder)
        
        let rightBorder = CALayer()
        rightBorder.frame = CGRectMake(self.frame.size.width - 0.5,self.frame.size.height - 10.0, 0.5, 8.0)
        rightBorder.backgroundColor = UIColor.whiteColor().CGColor
        self.layer.addSublayer(rightBorder)
    }
    
    override func drawRect(rect: CGRect) {
        super.drawRect(rect)
        
    }

}