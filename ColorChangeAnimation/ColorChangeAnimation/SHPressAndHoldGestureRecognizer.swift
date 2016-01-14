//
//  SHPressAndHoldGestureRecognizer.swift
//  SHTipCalculator
//
//  Created by Sruti Harikumar on 6/1/16.
//  Copyright © 2016 Sruti. All rights reserved.
//

import Foundation
import UIKit
import UIKit.UIGestureRecognizerSubclass


class SHPressAndHoldGestureRecognizer: UIGestureRecognizer {
    
    override func touchesBegan(touches: Set<UITouch>,withEvent event:UIEvent) {
        super.touchesBegan(touches, withEvent: event)
        if touches.count != 1 {
            state = .Failed
        }
        state = .Began
        //print("Touches Began")
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent) {
        super.touchesMoved(touches, withEvent: event)
        if state == .Failed {
            return
        }
        
        //print("Touches Moved")
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent) {
        super.touchesEnded(touches, withEvent: event)
        
        state = .Ended
        //print("Touches Ended")
    }
    
}
