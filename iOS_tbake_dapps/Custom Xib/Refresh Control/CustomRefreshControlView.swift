//
//  CustomRefreshControlView.swift
//  recommend-customer-ios
//
//  Created by Danial on 22/04/2020.
//  Copyright © 2020 Danial. All rights reserved.
//

import UIKit

class CustomRefreshControlView: UIView {
    
    @IBOutlet weak var firstLbl: UILabel!
    @IBOutlet weak var secondLbl: UILabel!
    @IBOutlet weak var thirdLbl: UILabel!
    @IBOutlet weak var forthLbl: UILabel!
    @IBOutlet weak var fifthLbl: UILabel!
    @IBOutlet weak var sixthLbl: UILabel!
    @IBOutlet weak var seventhLbl: UILabel!
    @IBOutlet weak var eightLbl: UILabel!
    @IBOutlet weak var ninethLbl: UILabel!
    @IBOutlet weak var tenthLbl: UILabel!
    @IBOutlet weak var eleventhLbl: UILabel!
    
    var labelsArray: [UILabel] = []
    var currentColorIndex = 0
    var currentLabelIndex = 0
    var isAnimating = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.labelsArray.append(firstLbl)
        self.labelsArray.append(secondLbl)
        self.labelsArray.append(thirdLbl)
        self.labelsArray.append(forthLbl)
        self.labelsArray.append(fifthLbl)
        self.labelsArray.append(sixthLbl)
        self.labelsArray.append(seventhLbl)
        self.labelsArray.append(eightLbl)
        self.labelsArray.append(ninethLbl)
        self.labelsArray.append(tenthLbl)
        self.labelsArray.append(eleventhLbl)
    }
    
    func startAnimate() {
        if !self.isAnimating {
            self.animateRefreshStep1()
        }
    }
    
    func stopAnimate() {
        self.isAnimating = false
    }
    
    func animateRefreshStep1() {
         self.isAnimating = true
        
        UIView.animate(withDuration: 0.1, delay: 0.0, options: .curveLinear, animations: { () -> Void in
            self.labelsArray[self.currentLabelIndex].transform = CGAffineTransform(rotationAngle: CGFloat(Float.pi/4))
            self.labelsArray[self.currentLabelIndex].textColor = self.getNextColor()
            
            }, completion: { (finished) -> Void in
                
                UIView.animate(withDuration: 0.05, delay: 0.0, options: .curveLinear, animations: { () -> Void in
                    self.labelsArray[self.currentLabelIndex].transform = CGAffineTransform.identity
                    self.labelsArray[self.currentLabelIndex].textColor = UIColor(named: "Label Color")
                    }, completion: { (finished) -> Void in
                        self.currentLabelIndex += 1
                        
                        if self.currentLabelIndex < self.labelsArray.count {
                            DispatchQueue.main.async { self.animateRefreshStep1() }
                        }
                        else {
                            DispatchQueue.main.async { self.animateRefreshStep2() }
                            for i in 0..<self.labelsArray.count {
                                self.labelsArray[i].textColor = UIColor(named: "Label Color")
                                self.labelsArray[i].transform = CGAffineTransform.identity
                            }
                        }
                })
        })
    }
    
    
    func animateRefreshStep2() {
        UIView.animate(withDuration: 0.35, delay: 0.0, options: .curveLinear, animations: { () -> Void in
            self.labelsArray[0].transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
            self.labelsArray[1].transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
            self.labelsArray[2].transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
            self.labelsArray[3].transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
            self.labelsArray[4].transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
            self.labelsArray[5].transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
            self.labelsArray[6].transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
            self.labelsArray[7].transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
            self.labelsArray[8].transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
            self.labelsArray[9].transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
            self.labelsArray[10].transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
            
            }, completion: { (finished) -> Void in
                UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveLinear, animations: { () -> Void in
                    self.labelsArray[0].transform = CGAffineTransform.identity
                    self.labelsArray[1].transform = CGAffineTransform.identity
                    self.labelsArray[2].transform = CGAffineTransform.identity
                    self.labelsArray[3].transform = CGAffineTransform.identity
                    self.labelsArray[4].transform = CGAffineTransform.identity
                    self.labelsArray[5].transform = CGAffineTransform.identity
                    self.labelsArray[6].transform = CGAffineTransform.identity
                    self.labelsArray[7].transform = CGAffineTransform.identity
                    self.labelsArray[8].transform = CGAffineTransform.identity
                    self.labelsArray[9].transform = CGAffineTransform.identity
                    self.labelsArray[10].transform = CGAffineTransform.identity
                    
                    }, completion: { (finished) -> Void in
                        if self.isAnimating {
                            self.currentLabelIndex = 0
                            DispatchQueue.main.async { self.animateRefreshStep1() }
                        }else{
                            self.currentLabelIndex = 0
                        }
                })
        })
    }
    
    
    func getNextColor() -> UIColor {
        let colorsArray: [UIColor] = [UIColor.magenta, UIColor.brown, UIColor.yellow, UIColor.red, UIColor.green, UIColor.blue, UIColor.orange]
        
        if currentColorIndex == colorsArray.count {
            currentColorIndex = 0
        }
        
        let returnColor = colorsArray[currentColorIndex]
        currentColorIndex += 1
        
        return returnColor
    }
}

private var customRefreshControlAssociationKey = 0x1996

extension CustomRefreshControlView: NibLoadable {}

public extension UIView {
    private var customRefreshControl: CustomRefreshControlView? {
        get {
            return objc_getAssociatedObject(self, &customRefreshControlAssociationKey) as? CustomRefreshControlView
        }
        set {
            objc_setAssociatedObject(self, &customRefreshControlAssociationKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    func addRefreshView(){
        let customRefreshView = CustomRefreshControlView.createFromNib()
        customRefreshControl = customRefreshView
        
        safeAddSubView(subView: customRefreshView, viewTag: Int(customRefreshControlAssociationKey))
        
        customRefreshView.translatesAutoresizingMaskIntoConstraints = false
        self.topAnchor.constraint(equalTo: customRefreshView.topAnchor).isActive = true
        self.bottomAnchor.constraint(equalTo: customRefreshView.bottomAnchor).isActive = true
        self.leftAnchor.constraint(equalTo: customRefreshView.leftAnchor).isActive = true
        self.rightAnchor.constraint(equalTo: customRefreshView.rightAnchor).isActive = true
    }
    
    func removeRefreshView(){
        customRefreshControl?.removeFromSuperview()
        customRefreshControl = nil
    }
    
    func showRefreshIndicator() {
        customRefreshControl?.startAnimate()
    }

    func hideRefreshIndicator() {
        customRefreshControl?.stopAnimate()
    }
}
