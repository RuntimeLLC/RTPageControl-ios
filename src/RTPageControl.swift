//
//  WWPageControl.swift
//  WiseWallet
//
//  Created by Daniyar Salakhutdinov on 13.04.16.
//

import UIKit

private let RTPageControlDefaultDotImageSize = CGSize(width: 12, height: 12)
private let RTPageControlDefaultPadding = CGFloat(8)
private let RTPageControlAnimationDuration = 0.3

public protocol RTPageControlDelegate : NSObjectProtocol {
    func pageControl(_ sender: RTPageControl, didSelectPageAtIndex index: Int)
}

open class RTPageControl: UIControl {
    
    /// Color of background dots
    open var passiveDotColor = UIColor.darkGray {
        didSet {
            resetDots()
        }
    }
    /// Color of selected dot
    open var activeDotColor = UIColor.white {
        didSet {
            resetDots()
        }
    }
    /// Size of dots
    open var dotSize: CGSize = RTPageControlDefaultDotImageSize {
        didSet {
            resetDots()
        }
    }
    /// Distance between dots
    open var padding: CGFloat = RTPageControlDefaultPadding {
        didSet {
            resetDots()
        }
    }
    /// Current page index
    fileprivate var innerCurrentPage: Int = 0
    open var currentPage: Int {
        get {
            return innerCurrentPage
        }
        set {
            setCurrentPage(newValue, animated: false)
        }
    }
    /// Number of pages
    open var numberOfPages: Int = 0 {
        didSet {
            resetDots()
        }
    }
    /// Delegate
    open var delegate: RTPageControlDelegate?
    
    /**
     Sets offset over the current page index
     
     - parameter offset: from -1 to 1
     */
    open func setOffset(_ offset: CGFloat) {
        let position = CGFloat(innerCurrentPage) * (dotSize.width + padding) + dotSize.width/2
        let diff = offset * (dotSize.width + padding)
        setCurrentPosition(position + diff, animated: false)
    }
    
    /**
     Selects page at a certain index
     
     - parameter index:
     */
    open func setCurrentPage(_ index: Int, animated: Bool) {
        guard index != innerCurrentPage else {
            return
        }
        innerCurrentPage = index
        // move active dot
        let size = dotSize
        let x = CGFloat(innerCurrentPage) * (size.width + padding) + size.width/2
        setCurrentPosition(x, animated: animated)
    }
    
    /**
     Sets selected dot position
     
     - parameter xPosition: coordinate
     - parameter animated:  flag
     */
    fileprivate func setCurrentPosition(_ xPosition: CGFloat, animated: Bool) {
        if animated {
            CATransaction.begin()
            CATransaction.setAnimationDuration(RTPageControlAnimationDuration)
            activeDot.position = CGPoint(x: xPosition, y: parent.bounds.midY)
            CATransaction.commit()
        } else {
            CATransaction.begin()
            CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
            activeDot.position = CGPoint(x: xPosition, y: parent.bounds.midY)
            CATransaction.commit()
        }
    }
    
    fileprivate let parent = CALayer()
    fileprivate let activeDot = CAShapeLayer()
    fileprivate var passiveDots = [CAShapeLayer]()
    fileprivate let lock = NSLock()
    
    override open func awakeFromNib() {
        super.awakeFromNib()
        // add parent layer
        layer.addSublayer(parent)
        // add active dot
        let size = dotSize
        activeDot.bounds = CGRect(origin: CGPoint.zero, size: size)
        activeDot.path = UIBezierPath(roundedRect: activeDot.bounds, cornerRadius: size.width / 2).cgPath
        activeDot.fillColor = activeDotColor.cgColor
        parent.addSublayer(activeDot)
        // add tap recognizer
        let recognizer = UITapGestureRecognizer()
        recognizer.addTarget(self, action: #selector(RTPageControl.handleTap(_:)))
        self.addGestureRecognizer(recognizer)
    }
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        // synchronize
        lock.lock()
        defer {
            lock.unlock()
        }
        // update parent position
        parent.position = CGPoint(x: bounds.midX, y: bounds.midY)
        // update dots position
        let size = dotSize
        // passive dots
        for index in 0..<passiveDots.count {
            let layer = passiveDots[Int(index)]
            let position = CGPoint(x: CGFloat(index) * (size.width + padding) + size.width/2, y: parent.bounds.midY)
            layer.position = position
        }
        // active dot
        let x = CGFloat(currentPage) * (size.width + padding) + size.width/2
        activeDot.position = CGPoint(x: x, y: parent.bounds.midY)
    }
    
    /**
     Resets layers
     */
    fileprivate func resetDots() {
        // synchronize
        lock.lock()
        defer {
            lock.unlock()
        }
        // update active dot appearance
        let activeSize = dotSize
        activeDot.bounds = CGRect(origin: CGPoint.zero, size: activeSize)
        activeDot.path = UIBezierPath(roundedRect: activeDot.bounds, cornerRadius: activeSize.width / 2).cgPath
        // remove previous passive dots
        for layer in passiveDots {
            layer.removeFromSuperlayer()
        }
        passiveDots.removeAll()
        // update parent layer frame
        let size = dotSize
        parent.bounds = CGRect(origin: CGPoint.zero, size: CGSize(width: ((size.width + padding) * CGFloat(numberOfPages) - padding), height: size.height))
        // add new dots
        for index in 0..<numberOfPages {
            let layer = CAShapeLayer()
            let origin = CGPoint(x: CGFloat(index) * (size.width + padding) + size.width/2, y: parent.bounds.midY)
            layer.bounds = CGRect(origin: origin, size: size)
            layer.path = UIBezierPath(roundedRect: layer.bounds, cornerRadius: size.width/2).cgPath
            layer.fillColor = passiveDotColor.cgColor
            parent.addSublayer(layer)
            passiveDots.append(layer)
        }
        activeDot.zPosition = CGFloat(passiveDots.count)
    }
    
    // MARK: - actions
    @objc fileprivate func handleTap(_ sender: UITapGestureRecognizer) {
        // check location inside parent layer
        let location = sender.location(in: self)
        let origin = CGPoint(x: parent.position.x - parent.bounds.size.width * parent.anchorPoint.x, y: parent.position.y - parent.bounds.size.height * parent.anchorPoint.y)
        let frame = CGRect(origin: origin, size: parent.bounds.size)
        guard frame.contains(location) else {
            return
        }
        // convert location
        let point = CGPoint(x: location.x - origin.x, y: location.y - origin.y)
        let size = dotSize
        let index = Int(round(point.x / (size.width + padding)))
        delegate?.pageControl(self, didSelectPageAtIndex: index)
    }
}
