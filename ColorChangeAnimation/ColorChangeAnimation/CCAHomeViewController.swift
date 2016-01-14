//
//  CCAHomeViewController.swift
//  
//
//  Created by Sruti Harikumar on 2/1/16.
//
//

import Foundation
import UIKit

struct CCAHomeViewControllerColors {
    static let paletteColors: [UIColor] = [UIColor.TCTealColor(),UIColor.TCGreenColor(),UIColor.TCBlueColor(),UIColor.TCPurpleColor(),UIColor.TCRedColor(),UIColor.TCOrangeColor()]
}

struct CCAHomeViewControllerUserDefaultKeys {
    static let priceAmountKey = "SHBillAmount"
    static let currentTipPercentageKey = "SHTipPercentage"
    static let currentIndicatorPositionKey = "SHCurrentIndicatorPosition"
}

class CCAHomeViewController: UIViewController,UIGestureRecognizerDelegate,UITextFieldDelegate {
    
    //MARK:Properties- IBOutlets
    @IBOutlet weak var backgroundView: UIView!
    
    @IBOutlet weak var priceTextField: SHTextfield!
    
    @IBOutlet weak var arrowUpImageView: UIImageView!
    @IBOutlet weak var arrowDownImageView: UIImageView!
    @IBOutlet weak var currentIndicatorImageView: UIImageView!
    @IBOutlet weak var currentPercentageLabel: UILabel!
    @IBOutlet weak var currentIndicatorContainerView: UIView!
    @IBOutlet weak var settingsButton: UIButton!
    @IBOutlet weak var totalImageView: UIImageView!
    @IBOutlet weak var currentIndicatorBackgroundView: UIView!
    @IBOutlet weak var minPercentageLabel: UILabel!
    @IBOutlet weak var maxPercentageLabel: UILabel!
    @IBOutlet weak var totalBillAmountLabel: UILabel!
    @IBOutlet weak var totalTipAmountLabel: UILabel!
    
    //Constraints
 
    //Container
    @IBOutlet weak var currentIndicatorContainerViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var currentIndicatorContainerViewTopConstraint: NSLayoutConstraint!
    
    //Label
    @IBOutlet weak var currentIndicatorPercentageLabelTrailingOrLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var currentIndicatorPercentageLabelWidthConstraint: NSLayoutConstraint!
    //MARK: Properties
    
    
    let linearInterpolatorColor = CCALinearInterpolationColors()
    let linearInterpolatorNumber = CCALinearInterpolationPercentage()
    var tappedOnCurrentIndicatorView = false
    var minLevelY : CGFloat = 0
    var maxLevelY : CGFloat = 0
    var numbers = []
    var animator : UIDynamicAnimator?
    var settingsView: UIView?
    var settingsViewShown = false
    let userDefaults = NSUserDefaults.standardUserDefaults()
    
    
    var minTipPercentage: Int = 10 {
        didSet{
            self.minPercentageLabel.text = String(minTipPercentage)
        }
    }
    var maxTipPercentage: Int = 50 {
        didSet{
            self.maxPercentageLabel.text = String(maxTipPercentage)
        }
    }
    var currentTipPercentage: Int = 0 {
        didSet{
            
            if let price = self.parsePrice(self.priceTextField.text!) {
                
                let multiplicationFactor: Float  = (Float(self.currentTipPercentage)/100.0) + 1.0
                let actualAmount : Float = multiplicationFactor * price
                
                let actualAmountString = String(format: "%.2f", actualAmount)
                self.totalBillAmountLabel.text = "$" + actualAmountString
                let tipAmount = price * (Float(self.currentTipPercentage)/100.0)
                let tipAmountString = String(format: "%.2f",tipAmount)
                self.totalTipAmountLabel.text = "+" + tipAmountString
                
                
            }
        }
    }
    
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    //MARK: View Controller Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Setting Selector for Tap Gesture Recognizer
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: "handleTap:")
        self.view.addGestureRecognizer(tapGestureRecognizer)
        tapGestureRecognizer.delegate = self
        
        
        //Setting Selector for Custom Gesture Recognizer
        self.view.userInteractionEnabled = true
        let pressAndHoldContainerGestureRecognizer = SHPressAndHoldGestureRecognizer(target: self, action: "handleGestureOnContainerView:")
        self.currentIndicatorContainerView.addGestureRecognizer(pressAndHoldContainerGestureRecognizer)
        pressAndHoldContainerGestureRecognizer.delegate = self
        
        
        //Setting delegate for text field
        self.priceTextField.delegate = self
        
        //Setting up UI
        self.setupUI()
        
        //Min and Max Levels for Gesture Recognition
        self.minLevelY = self.minPercentageLabel.frame.origin.y
        self.maxLevelY = self.maxPercentageLabel.frame.origin.y
        //Initializing colors
        self.linearInterpolatorColor.initWithColorsArray(CCAHomeViewControllerColors.paletteColors)
        self.numbers = [self.minTipPercentage,self.maxTipPercentage]
        self.linearInterpolatorNumber.initWithNumbersArray(numbers as! [CGFloat])
        self.animator = UIDynamicAnimator(referenceView: self.view)
        
        //Settings View
        self.settingsView = NSBundle.mainBundle().loadNibNamed("SettingsView", owner: nil, options: nil)[0] as? UIView
        self.settingsView?.frame = CGRectMake(self.view.frame.origin.x, (self.view.frame.origin.y + self.view.frame.size.height),self.view.frame.size.width, (self.view.frame.size.height - 50))
        if let settings = self.settingsView {
            self.view.addSubview(settings)
        }
        
        
        //Adding Gesture Recognizer to Settings View (Swipe Down)
        let swipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: "handleSwipe:")
        swipeGestureRecognizer.direction = .Down
        self.settingsView!.addGestureRecognizer(swipeGestureRecognizer)
        swipeGestureRecognizer.delegate = self
        
        
        //Registering Notifications
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.addObserver(self, selector: "didReceiveMinTipPercentageChangeNotification:" , name: "MinPercentageChanged", object: nil)
        notificationCenter.addObserver(self, selector: "didReceiveMaxTipPercentageChangeNotification:" , name: "MaxPercentageChanged", object: nil)
        notificationCenter.addObserver(self, selector: "didEnterBackground:", name: "EnteredBackground", object: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        var currentIndicatorPosition : Float
        if let _ = NSUserDefaults.standardUserDefaults().objectForKey(CCAHomeViewControllerUserDefaultKeys.priceAmountKey){
            self.priceTextField.text = "$" + String(userDefaults.floatForKey(CCAHomeViewControllerUserDefaultKeys.priceAmountKey))
        }
        else {
            self.priceTextField.text = "$" + String(50)
        }
        if let _ = NSUserDefaults.standardUserDefaults().objectForKey(SHSettingsViewUserDefaultKeys.minTipPercentageKey){
            self.minTipPercentage = userDefaults.integerForKey(SHSettingsViewUserDefaultKeys.minTipPercentageKey)
        }
        else {
            self.minTipPercentage = 10
        }
        
        if let _ = NSUserDefaults.standardUserDefaults().objectForKey(SHSettingsViewUserDefaultKeys.maxTipPercentageKey){
            self.maxTipPercentage = userDefaults.integerForKey(SHSettingsViewUserDefaultKeys.maxTipPercentageKey)
        }
        else {
            self.maxTipPercentage = 50
        }
        
        if let _ = NSUserDefaults.standardUserDefaults().objectForKey(CCAHomeViewControllerUserDefaultKeys.currentTipPercentageKey){
            self.currentTipPercentage = userDefaults.integerForKey(CCAHomeViewControllerUserDefaultKeys.currentTipPercentageKey)
        }
        else {
            self.currentTipPercentage = 15
        }
        if let _ = NSUserDefaults.standardUserDefaults().objectForKey(CCAHomeViewControllerUserDefaultKeys.currentIndicatorPositionKey){
             currentIndicatorPosition = userDefaults.floatForKey(CCAHomeViewControllerUserDefaultKeys.currentIndicatorPositionKey)
        }
        else {
            currentIndicatorPosition = Float(self.currentIndicatorContainerView.frame.origin.y + ( 0.5 * self.currentIndicatorContainerView.frame.height))
        }
        
        self.numbers = [self.minTipPercentage,self.maxTipPercentage]
        self.linearInterpolatorNumber.initWithNumbersArray(numbers as! [CGFloat])
        
        self.gestureChanged(CGFloat(self.currentTipPercentage), locationY: CGFloat(currentIndicatorPosition))
        
    }
    
    override func viewWillDisappear(animated: Bool) {
    
        super.viewWillDisappear(animated)
        
        let currentIndicatorPosition = Float(self.currentIndicatorContainerView.frame.origin.y + ( 0.5 * self.currentIndicatorContainerView.frame.height))
        
        self.userDefaults.setFloat(currentIndicatorPosition, forKey: CCAHomeViewControllerUserDefaultKeys.currentIndicatorPositionKey)
        
        self.userDefaults.setInteger(self.currentTipPercentage, forKey: CCAHomeViewControllerUserDefaultKeys.currentTipPercentageKey)
        
        
    }
    
    //MARK: UI Setup
    func setupUI() {
        self.priceTextField.font = UIFont.TCHeadingLarge()
        let arrowUpIcon = FAKFontAwesome.longArrowUpIconWithSize(20.0)
        arrowUpIcon.addAttribute(NSForegroundColorAttributeName, value: UIColor.whiteColor())
        let arrowDownIcon = FAKFontAwesome.longArrowDownIconWithSize(20.0)
        arrowDownIcon.addAttribute(NSForegroundColorAttributeName, value: UIColor.whiteColor())
        let currentIndicatorIcon = FAKFontAwesome.circleOIconWithSize(20.0)
        currentIndicatorIcon.addAttribute(NSForegroundColorAttributeName, value: UIColor.whiteColor())
        let settingsIcon = FAKFontAwesome.cogIconWithSize(30.0)
        settingsIcon.addAttribute(NSForegroundColorAttributeName,value: UIColor.blackColor())
        let minusIcon = FAKFontAwesome.minusIconWithSize(15)
        minusIcon.addAttribute(NSForegroundColorAttributeName, value: UIColor.whiteColor())
        let minusIconLg = FAKFontAwesome.minusIconWithSize(30)
        minusIconLg.addAttribute(NSForegroundColorAttributeName, value: UIColor.whiteColor())
        let moneyIconLg = FAKFontAwesome.moneyIconWithSize(30)
        moneyIconLg.addAttribute(NSForegroundColorAttributeName, value: UIColor.whiteColor())
        self.arrowUpImageView.image = minusIcon.imageWithSize(CGSizeMake(50,50))
        self.arrowDownImageView.image = minusIcon.imageWithSize(CGSizeMake(50,50))
        self.currentIndicatorImageView.image = minusIconLg.imageWithSize(CGSizeMake(50,50))
        self.totalImageView.image = moneyIconLg.imageWithSize(CGSizeMake(50,50))
        let settingsImage = settingsIcon.imageWithSize(CGSizeMake(50,50))
        self.settingsButton.setImage(settingsImage, forState: .Normal)
        self.minPercentageLabel.text = String(self.minTipPercentage)
        self.maxPercentageLabel.text = String(self.maxTipPercentage)
        
        self.currentIndicatorBackgroundView.hidden = true
    }
    
    
    //MARK: Gesture recognizer Related
    func handleTap(gestureRecognizer: UITapGestureRecognizer) {
        self.view.endEditing(true)
        let tappedView = gestureRecognizer.view
        let location: CGPoint = gestureRecognizer.locationInView(tappedView)
        let subView = view.hitTest(location, withEvent: nil)
        if subView == self.settingsView {
            return;
        }
        if settingsViewShown {
            self.animateSettingsViewDown();
        }
    }
    
    func handleSwipe(gestureRecognizer: UISwipeGestureRecognizer) {
        if settingsViewShown {
            self.animateSettingsViewDown();
        }
    }
    
    func handleGestureOnContainerView(gestureRecognizer: SHPressAndHoldGestureRecognizer) {
        self.view.endEditing(true)
        self.tappedOnCurrentIndicatorView = true
        if gestureRecognizer.state == .Began {
            self.gestureBegan()
        }
        else if gestureRecognizer.state == .Changed {
            let locationY = gestureRecognizer.locationInView(self.view).y
            self.minLevelY = self.minPercentageLabel.frame.origin.y + (2 * self.minPercentageLabel.frame.size.height)
            self.maxLevelY = self.maxPercentageLabel.frame.origin.y - (self.maxPercentageLabel.frame.size.height)
            if(locationY < self.minLevelY || locationY >= self.maxLevelY)
            {
                return
            }
            //print("Location : ", locationY)
            //print("Min Level : ", self.minLevelY)
            //print("Max Level : ",self.maxLevelY)
            let screenHeight = (self.maxLevelY - self.minLevelY)
            let pixelVal = locationY - self.minLevelY
            let interpolatedVal = self.linearInterpolatorNumber.interpolateNumWithPixelValue(pixelVal, andScreenHeight: screenHeight)
            self.backgroundView.backgroundColor = self.linearInterpolatorColor.interpolateWithPixelValue(pixelVal, andScreenHeight: screenHeight)
            let roundedInterpolatedVal = round(interpolatedVal!)
            self.gestureChanged(roundedInterpolatedVal,locationY: locationY)
        }
        else if gestureRecognizer.state == .Ended {
           self.gestureEnded()
        }
    }
    
    
    func gestureBegan() {
        let newHeightConstraint = NSLayoutConstraint(item: self.currentIndicatorContainerView, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1.0, constant: 50.0)
        newHeightConstraint.priority = 999
        let newLeadingConstraintLabel = NSLayoutConstraint(item: self.currentIndicatorContainerView, attribute: NSLayoutAttribute.Leading, relatedBy: .Equal, toItem: self.currentPercentageLabel, attribute: NSLayoutAttribute.Leading, multiplier: 1.0, constant: 0.0)
        newLeadingConstraintLabel.priority = 999
        //let newWidthConstraintLabel = NSLayoutConstraint(item: self.currentPercentageLabel, attribute: .Width, relatedBy: .LessThanOrEqual, toItem: .None, attribute: .NotAnAttribute, multiplier: 1.0, constant: 100.0)
        
        UIView.animateWithDuration(0.4, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: {
            
            if let widthConstraint = self.currentIndicatorPercentageLabelWidthConstraint {
                self.currentPercentageLabel.removeConstraint(widthConstraint)
            }
            
            //self.currentPercentageLabel.addConstraint(newWidthConstraintLabel)
            if let heightConstraint = self.currentIndicatorContainerViewHeightConstraint {
                self.currentIndicatorContainerView.removeConstraint(heightConstraint)
                self.currentIndicatorContainerView.addConstraint(newHeightConstraint)
            }
            
            if let trailingConstraint = self.currentIndicatorPercentageLabelTrailingOrLeadingConstraint {
                self.currentPercentageLabel.removeConstraint(trailingConstraint)
                self.currentIndicatorContainerView.addConstraint(newLeadingConstraintLabel)
            }
            self.currentPercentageLabel.transform = CGAffineTransformScale(self.currentPercentageLabel.transform, 0.8, 0.8);
            
            self.view.layoutIfNeeded()
            
            
            }, completion: nil)
        self.currentIndicatorContainerViewHeightConstraint = newHeightConstraint
        self.currentIndicatorPercentageLabelTrailingOrLeadingConstraint = newLeadingConstraintLabel
        self.currentIndicatorImageView.hidden = true
        self.currentIndicatorBackgroundView.hidden = false

    }
    
    func gestureChanged(interpolatedVal: CGFloat,locationY: CGFloat) {
        let newStartY = locationY - (0.5 * self.currentIndicatorContainerView.frame.height)
        //print("New Start Y ",newStartY)
        let newTopConstraint = NSLayoutConstraint(item: self.currentIndicatorContainerView.superview!, attribute: NSLayoutAttribute.Top, relatedBy: NSLayoutRelation.Equal, toItem: self.currentIndicatorContainerView
            , attribute: NSLayoutAttribute.Top, multiplier: 1.0, constant: newStartY)
        newTopConstraint.priority = 999
        
        UIView.animateWithDuration(0.0, animations: {
            /*if let topConstraint = self.currentIndicatorContainerViewTopConstraint {
                self.currentIndicatorContainerView.removeConstraint(topConstraint)
            }
            self.currentIndicatorContainerView.superview!.addConstraint(newTopConstraint)
            self.view.layoutIfNeeded()*/
            self.currentPercentageLabel.text = String(Int(interpolatedVal)) + " %"
            self.currentTipPercentage = Int(interpolatedVal)
        })
        //self.currentIndicatorContainerViewTopConstraint = newTopConstraintr
        self.currentIndicatorContainerViewTopConstraint.constant = newStartY
        self.view.updateConstraintsIfNeeded()
    }
    
    func gestureEnded() {
        let newHeightConstraint = NSLayoutConstraint(item: self.currentIndicatorContainerView, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1.0, constant: 70.0)
        
        let allConstraints = self.currentIndicatorContainerView.constraints
        var oldLeadingConstraint = NSLayoutConstraint()
        for constraint in allConstraints {
            if constraint.firstItem as! UIView == self.currentIndicatorContainerView && constraint.firstAttribute == NSLayoutAttribute.Leading && constraint.secondItem as! UIView == self.currentPercentageLabel && constraint.constant == 0.0 {
                oldLeadingConstraint = constraint
            }
        }
        
        let newTrailingConstraintLabel = NSLayoutConstraint(item: self.currentPercentageLabel, attribute: NSLayoutAttribute.Trailing, relatedBy: .Equal, toItem: self.currentIndicatorImageView, attribute: NSLayoutAttribute.Leading, multiplier: 1.0, constant: 0.0)
        newTrailingConstraintLabel.priority = 999
        let newWidthConstraintLabel = NSLayoutConstraint(item: self.currentPercentageLabel, attribute: .Width, relatedBy: .LessThanOrEqual, toItem: .None, attribute: .NotAnAttribute, multiplier: 1.0, constant: 100.0)
        newWidthConstraintLabel.priority = 999
        UIView.animateWithDuration(0.4, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: {
            
            
            self.currentPercentageLabel.addConstraint(newWidthConstraintLabel)
            if let heightConstraint = self.currentIndicatorContainerViewHeightConstraint {
                self.currentIndicatorContainerView.removeConstraint(heightConstraint)
                self.currentIndicatorContainerView.addConstraint(newHeightConstraint)
            }
            if let constraint = self.currentIndicatorPercentageLabelTrailingOrLeadingConstraint  {
                self.currentPercentageLabel.removeConstraint(constraint)
                self.currentPercentageLabel.removeConstraint(oldLeadingConstraint)
                self.currentIndicatorContainerView.addConstraint(newTrailingConstraintLabel)
            }
            self.currentPercentageLabel.transform = CGAffineTransformScale(self.currentPercentageLabel.transform, (5/4), (5/4));
            
            self.view.layoutIfNeeded()
            
            
            }, completion: nil)
        
        self.currentIndicatorContainerViewHeightConstraint = newHeightConstraint
        self.currentIndicatorImageView.hidden = false
        self.currentIndicatorBackgroundView.hidden = true
    }
    
    //MARK: Textfield Delegate Methods
    func textFieldDidBeginEditing(textField: UITextField) {
        textField.text = "$"
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        if range.location == 0  && range.length == 1{
            return false
        }
        return true
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        if textField == self.priceTextField {
            if let price = self.parsePrice(self.priceTextField.text!) {
                
                let multiplicationFactor: Float  = (Float(self.currentTipPercentage)/100.0) + 1.0
                let actualAmount : Float = multiplicationFactor * price
                self.userDefaults.setFloat(price, forKey: CCAHomeViewControllerUserDefaultKeys.priceAmountKey)
                let actualAmountString = String(actualAmount)
                self.totalBillAmountLabel.text = "$" + actualAmountString
                let tipAmount = price * (Float(self.currentTipPercentage)/100.0)
                let tipAmountString = String(format: "%.2f",tipAmount)
                self.totalTipAmountLabel.text = "+" + tipAmountString

            }
        }
    }
    
    func animateSettingsViewDown() {
        self.animator?.removeAllBehaviors()
        let gravityDirectionY : CGFloat = 5.0
        let pushMagnitude: CGFloat = -200.0
        let boundaryPointY : CGFloat = (self.view.frame.size.height + (self.settingsView?.frame.size.height)!)
        
        let gravityBehaviour = UIGravityBehavior(items: [self.settingsView!])
        gravityBehaviour.gravityDirection = CGVectorMake(0, gravityDirectionY)
        self.animator?.addBehavior(gravityBehaviour)
        let collisionBehaviour = UICollisionBehavior(items: [self.settingsView!])
        collisionBehaviour.addBoundaryWithIdentifier("menuBoundary", fromPoint: CGPointMake(0, boundaryPointY), toPoint: CGPointMake(self.view.frame.size.width, boundaryPointY))
        self.animator?.addBehavior(collisionBehaviour)
        let pushBehaviour = UIPushBehavior(items: [self.settingsView!], mode: .Instantaneous)
        pushBehaviour.magnitude = pushMagnitude
        self.animator?.addBehavior(pushBehaviour)
        pushBehaviour.pushDirection = CGVectorMake(0, gravityDirectionY)
        
        let settingsViewBehaviour = UIDynamicItemBehavior(items: [self.settingsView!])
        settingsViewBehaviour.elasticity = 0.4
        self.animator?.addBehavior(settingsViewBehaviour)
        settingsViewShown = false;

    }
    
    
    
    //MARK: IBActions
    @IBAction func didTapSettingsButton(sender: AnyObject) {
        
        self.animator?.removeAllBehaviors()
        let gravityDirectionY : CGFloat = 5.0
        let pushMagnitude: CGFloat = 200.0
        let boundaryPointY : CGFloat = self.view.frame.size.height - (self.settingsView?.frame.size.height)!
        
        let gravityBehaviour = UIGravityBehavior(items: [self.settingsView!])
        gravityBehaviour.gravityDirection = CGVectorMake(0, -gravityDirectionY)
        self.animator?.addBehavior(gravityBehaviour)
        let collisionBehaviour = UICollisionBehavior(items: [self.settingsView!])
        collisionBehaviour.addBoundaryWithIdentifier("menuBoundary", fromPoint: CGPointMake(0, boundaryPointY), toPoint: CGPointMake(self.view.frame.size.width, boundaryPointY))
        self.animator?.addBehavior(collisionBehaviour)
        let pushBehaviour = UIPushBehavior(items: [self.settingsView!], mode: .Instantaneous)
        pushBehaviour.magnitude = pushMagnitude
        self.animator?.addBehavior(pushBehaviour)
        pushBehaviour.pushDirection = CGVectorMake(0, -gravityDirectionY)
        
        let settingsViewBehaviour = UIDynamicItemBehavior(items: [self.settingsView!])
        settingsViewBehaviour.elasticity = 0.4
        self.animator?.addBehavior(settingsViewBehaviour)
        settingsViewShown = true
    }
    
    
    //MARK: Notification Handlers
    func didReceiveMinTipPercentageChangeNotification(notification: NSNotification) {
        let userInfo = notification.userInfo;
        if userInfo != nil {
            if let newVal = userInfo!["MinPercentage"] {
                self.minTipPercentage = newVal as! Int
                self.minPercentageLabel.text = String(self.minTipPercentage)
                self.numbers = [self.minTipPercentage,self.maxTipPercentage]
                self.linearInterpolatorNumber.initWithNumbersArray(numbers as! [CGFloat])
                self.adjustCurrentIndicatorVal();
                
            }
        }
    }
    
    func didReceiveMaxTipPercentageChangeNotification(notification: NSNotification) {
        let userInfo = notification.userInfo;
        if userInfo != nil {
            if let newVal = userInfo!["MaxPercentage"] {
                self.maxTipPercentage = newVal as! Int
                self.maxPercentageLabel.text = String(self.maxTipPercentage)
                self.numbers = [self.minTipPercentage,self.maxTipPercentage]
                self.linearInterpolatorNumber.initWithNumbersArray(numbers as! [CGFloat])
                self.adjustCurrentIndicatorVal()
            }
        }
    }
    
    func didEnterBackground(notification: NSNotification) {
        
        let currentIndicatorPosition = Float(self.currentIndicatorContainerView.frame.origin.y + ( 0.5 * self.currentIndicatorContainerView.frame.height))
        self.userDefaults.setFloat(currentIndicatorPosition, forKey: CCAHomeViewControllerUserDefaultKeys.currentIndicatorPositionKey)
        self.userDefaults.setInteger(self.currentTipPercentage, forKey: CCAHomeViewControllerUserDefaultKeys.currentTipPercentageKey)
    }
    
    
    
    //MARK: Helper / Utility Methods
    func adjustCurrentIndicatorVal() {
        let locationY = self.currentIndicatorContainerView.frame.origin.y
        let screenHeight = (self.maxLevelY - self.minLevelY)
        let pixelVal = locationY - self.minLevelY
        let interpolatedVal = self.linearInterpolatorNumber.interpolateNumWithPixelValue(pixelVal, andScreenHeight: screenHeight)
        self.backgroundView.backgroundColor = self.linearInterpolatorColor.interpolateWithPixelValue(pixelVal, andScreenHeight: screenHeight)
        let roundedInterpolatedVal = round(interpolatedVal!)
        self.currentPercentageLabel.text = String(Int(roundedInterpolatedVal)) + " %"
        self.currentTipPercentage = Int(roundedInterpolatedVal)

    }
    
    func parsePrice(priceFieldText: String) -> Float?{
        let priceString = String(priceFieldText.characters.dropFirst())
        return Float(priceString)
    }
    
    
    
    
    
}