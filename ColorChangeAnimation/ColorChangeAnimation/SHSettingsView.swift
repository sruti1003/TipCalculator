//
//  SHTextView.swift
//  SHTipCalculator
//
//  Created by Sruti Harikumar on 6/1/16.
//  Copyright © 2016 Sruti. All rights reserved.
//

import Foundation
import UIKit


struct SHSettingsViewUserDefaultKeys {
    static let minTipPercentageKey = "MinimumTipPercentage"
    static let maxTipPercentageKey = "MaximumTipPercentage"
}
class SHSettingsView : UIView, UITextFieldDelegate {

    
    
    @IBOutlet weak var customHeaderImageView: UIImageView!
    @IBOutlet weak var minimumPercentageTextField: SHTextfield!
    @IBOutlet weak var maximumPercentageTextField: SHTextfield!
    
    var minTipPercentage: Int = 10 {
        didSet {
            self.minimumPercentageTextField.text = String(self.minTipPercentage)
        }
    }
    var maxTipPercentage: Int = 50  {
        didSet {
            self.maximumPercentageTextField.text = String(self.maxTipPercentage)
        }
    }
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        //Adding Image
        let headerImageIcon = FAKFontAwesome.ellipsisHIconWithSize(30.0)
        headerImageIcon.addAttribute(NSForegroundColorAttributeName, value: UIColor.whiteColor())
        self.customHeaderImageView.image = headerImageIcon.imageWithSize(CGSizeMake(50, 50))
        if let _ = NSUserDefaults.standardUserDefaults().objectForKey(SHSettingsViewUserDefaultKeys.minTipPercentageKey){
            self.minTipPercentage = NSUserDefaults.standardUserDefaults().integerForKey(SHSettingsViewUserDefaultKeys.minTipPercentageKey)
        }
        else {
            self.minTipPercentage = 10
        }
        if let _ = NSUserDefaults.standardUserDefaults().objectForKey(SHSettingsViewUserDefaultKeys.maxTipPercentageKey){
            self.maxTipPercentage = NSUserDefaults.standardUserDefaults().integerForKey(SHSettingsViewUserDefaultKeys.maxTipPercentageKey)
        }
        else {
            self.maxTipPercentage = 50
        }

        self.minimumPercentageTextField.delegate = self;
        self.maximumPercentageTextField.delegate = self;
    }
    
    func textFieldDidEndEditing(textField: UITextField)
    {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        if textField == self.minimumPercentageTextField {
            if let text = textField.text {
                self.minTipPercentage = Int(text)!
                userDefaults.setInteger(self.minTipPercentage, forKey: SHSettingsViewUserDefaultKeys.minTipPercentageKey);
                NSNotificationCenter.defaultCenter().postNotificationName("MinPercentageChanged", object: nil, userInfo: ["MinPercentage":self.minTipPercentage])
        }
            
        }
        else if textField == self.maximumPercentageTextField {
            if let text = textField.text {
                self.maxTipPercentage = Int(text)!
                userDefaults.setInteger(self.maxTipPercentage, forKey: SHSettingsViewUserDefaultKeys.maxTipPercentageKey);
                NSNotificationCenter.defaultCenter().postNotificationName("MaxPercentageChanged", object: nil, userInfo: ["MaxPercentage":self.maxTipPercentage])

            }
        }
        
    }
    
}