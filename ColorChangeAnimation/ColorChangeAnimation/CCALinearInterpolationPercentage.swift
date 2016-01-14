//
//  CCALinearInterpolationPercentage.swift
//  SHTipCalculator
//
//  Created by Sruti Harikumar on 5/1/16.
//  Copyright © 2016 Sruti. All rights reserved.
//

import Foundation
import UIKit

class CCALinearInterpolationPercentage {
    //MARK: Properties
    var numbersArray = [CGFloat]()
    
    
    func initWithNumbersArray(numbersArray: [CGFloat]) {
        self.numbersArray = numbersArray
    }
    
    func interpolateNumWithPixelValue(pixelValue: CGFloat,andScreenHeight screenHeight:CGFloat) -> CGFloat? {
        let perSegmentSize = screenHeight/CGFloat(self.numbersArray.count - 1)
        let segmentNumFloat = floor(pixelValue/perSegmentSize)
        let segmentNumInt = Int(segmentNumFloat)
        let normalizedVal = CGFloat((pixelValue % perSegmentSize) / perSegmentSize)
        if(segmentNumInt > self.numbersArray.count - 1) {
            return nil
        }
        let val1 = self.numbersArray[segmentNumInt]
        let val2 = self.numbersArray[segmentNumInt + 1]
        let finalVal = self.lerp(val1,val2: val2, normalizedVal: normalizedVal)
        return finalVal
    }
    
    
    //MARK: Formula Methods
    func lerp(val1: CGFloat,val2: CGFloat,normalizedVal: CGFloat) -> CGFloat {
        return CGFloat((1 - normalizedVal) * val1 + (normalizedVal * val2))
    }
    
}