//
//  CCALinearInterpolationColors.swift
//  ColorChangeAnimation
//
//  Created by Sruti Harikumar on 3/1/16.
//  Copyright © 2016 Sruti. All rights reserved.
//

import Foundation
import UIKit

class CCALinearInterpolationColors {
    //MARK: Properties
    var colorsArray = [UIColor]()
    
    //MARK: Init Methods
    func initWithColorsArray(colorsArray: [UIColor]) {
        self.colorsArray = colorsArray
    }
    
    
    //MARK: Interpolation Helpers
    func interpolateWithPixelValue(pixelValue: CGFloat,andScreenHeight screenHeight: CGFloat) -> UIColor? {
        let perSegmentSize = screenHeight/CGFloat(self.colorsArray.count - 1)
        let segmentNumFloat = floor(pixelValue/perSegmentSize)
        let segmentNumInt = Int(segmentNumFloat)
        let normalizedVal = CGFloat((pixelValue % perSegmentSize) / perSegmentSize)
        if(segmentNumInt > self.colorsArray.count - 1) {
            return nil
        }
        let colorStart = colorsArray[segmentNumInt]
        let colorEnd = colorsArray[segmentNumInt + 1]
        let interpolatedColor = self.getFinalValue(colorStart, colorEnd: colorEnd,normalizedValue: normalizedVal)
        return interpolatedColor
    }
    
    func getFinalValue(colorStart: UIColor,colorEnd: UIColor,normalizedValue : CGFloat) -> UIColor {
        
        var redStart : CGFloat = 0.0 ,greenStart: CGFloat = 0.0, blueStart: CGFloat = 0.0, alphaStart: CGFloat = 0.0
        var redEnd : CGFloat = 0.0 ,greenEnd: CGFloat = 0.0, blueEnd: CGFloat = 0.0, alphaEnd: CGFloat = 0.0
        
        colorStart.getRed(&redStart, green: &greenStart, blue: &blueStart, alpha: &alphaStart)
        colorEnd.getRed(&redEnd, green: &greenEnd, blue: &blueEnd, alpha: &alphaEnd)
        
        let finalRed = self.lerp(redStart, val2: redEnd, normalizedVal: normalizedValue)
        let finalGreen = self.lerp(greenStart, val2: greenEnd, normalizedVal: normalizedValue)
        let finalBlue = self.lerp(blueStart, val2: blueEnd, normalizedVal: normalizedValue)
        
        let interpolatedColor: UIColor = UIColor(red: finalRed, green: finalGreen, blue: finalBlue, alpha: 1.0)
        
        return interpolatedColor
    }
    
    //MARK: Formula Methods
    func lerp(val1: CGFloat,val2: CGFloat,normalizedVal: CGFloat) -> CGFloat {
        return CGFloat((1 - normalizedVal) * val1 + (normalizedVal * val2))
    }
}
