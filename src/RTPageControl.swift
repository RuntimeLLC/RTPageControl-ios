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
    func pageControl(sender: RTPageControl, didSelectPageAtIndex index: Int)
}

public class RTPageControl: UIControl {
    
    /// Color of background dots
    var passiveDotColor = UIColor.darkGrayColor() {
        didSet {
            resetDots()
        }
    }
    /// Color of selected dot
    var activeDotColor = UIColor.whiteColor() {
        didSet {
            resetDots()
        }
    }
    /// Size of dots
    var dotSize: CGSize = RTPageControlDefaultDotImageSize {
        didSet {
            resetDots()
        }
    }
    /// Distance between dots
    var padding: CGFloat = RTPageControlDefaultPadding {
        didSet {
            resetDots()
        }
    }
    /// Current page index
    private var innerCurrentPage: Int = 0
    var currentPage: Int {
        get {
            return innerCurrentPage
        }
        set {
            setCurrentPage(newValue, animated: false)
        }
    }
    /// Number of pages
    var numberOfPages: Int = 0 {
        didSet {
            resetDots()
        }
    }
    /// Delegate
    var delegate: RTPageControlDelegate?
    
    /**
     Sets offset over the current page index
     
     - parameter offset: from -1 to 1
     */
    func setOffset(offset: CGFloat) {
        let position = CGFloat(innerCurrentPage) * (dotSize.width + padding) + dotSize.width/2
        let diff = offset * (dotSize.width + padding)
        setCurrentPosition(position + diff, animated: false)
    }
    
    /**
     Selects page at a certain index
     
     - parameter index:
     */
    func setCurrentPage(index: Int, animated: Bool) {
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
    private func setCurrentPosition(xPosition: CGFloat, animated: Bool) {
        if animated {
            CATransaction.begin()
            CATransaction.setAnimationDuration(RTPageControlAnimationDuration)
            activeDot.position = CGPoint(x: xPosition, y: CGRectGetMidY(parent.bounds))
            CATransaction.commit()
        } else {
            CATransaction.begin()
            CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
            activeDot.position = CGPoint(x: xPosition, y: CGRectGetMidY(parent.bounds))
            CATransaction.commit()
        }
    }
    
    private let parent = CALayer()
    private let activeDot = CAShapeLayer()
    private var passiveDots = [CAShapeLayer]()
    private let lock = NSLock()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // add parent layer
        layer.addSublayer(parent)
        // add active dot
        let size = dotSize
        activeDot.bounds = CGRect(origin: CGPointZero, size: size)
        activeDot.path = UIBezierPath(roundedRect: activeDot.bounds, cornerRadius: size.width / 2).CGPath
        activeDot.fillColor = activeDotColor.CGColor
        parent.addSublayer(activeDot)
        // add tap recognizer
        let recognizer = UITapGestureRecognizer()
        recognizer.addTarget(self, action: #selector(RTPageControl.handleTap(_:)))
        self.addGestureRecognizer(recognizer)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // synchronize
        lock.lock()
        defer {
            lock.unlock()
        }
        // update parent position
        parent.position = CGPoint(x: CGRectGetMidX(bounds), y: CGRectGetMidY(bounds))
        // update dots position
        let size = dotSize
        // passive dots
        for index in 0..<passiveDots.count {
            let layer = passiveDots[Int(index)]
            let position = CGPoint(x: CGFloat(index) * (size.width + padding) + size.width/2, y: CGRectGetMidY(parent.bounds))
            layer.position = position
        }
        // active dot
        let x = CGFloat(currentPage) * (size.width + padding) + size.width/2
        activeDot.position = CGPoint(x: x, y: CGRectGetMidY(parent.bounds))
    }
    
    /**
     Resets layers
     */
    private func resetDots() {
        // synchronize
        lock.lock()
        defer {
            lock.unlock()
        }
        // update active dot appearance
        let activeSize = dotSize
        activeDot.bounds = CGRect(origin: CGPointZero, size: activeSize)
        activeDot.path = UIBezierPath(roundedRect: activeDot.bounds, cornerRadius: activeSize.width / 2).CGPath
        // remove previous passive dots
        for layer in passiveDots {
            layer.removeFromSuperlayer()
        }
        passiveDots.removeAll()
        // update parent layer frame
        let size = dotSize
        parent.bounds = CGRect(origin: CGPointZero, size: CGSize(width: ((size.width + padding) * CGFloat(numberOfPages) - padding), height: size.height))
        // add new dots
        for index in 0..<numberOfPages {
            let layer = CAShapeLayer()
            let origin = CGPoint(x: CGFloat(index) * (size.width + padding) + size.width/2, y: CGRectGetMidY(parent.bounds))
            layer.bounds = CGRect(origin: origin, size: size)
            layer.path = UIBezierPath(roundedRect: layer.bounds, cornerRadius: size.width/2).CGPath
            layer.fillColor = passiveDotColor.CGColor
            parent.addSublayer(layer)
            passiveDots.append(layer)
        }
        activeDot.zPosition = CGFloat(passiveDots.count)
    }
    
    // MARK: - actions
    @objc private func handleTap(sender: UITapGestureRecognizer) {
        // check location inside parent layer
        let location = sender.locationInView(self)
        let origin = CGPoint(x: parent.position.x - parent.bounds.size.width * parent.anchorPoint.x, y: parent.position.y - parent.bounds.size.height * parent.anchorPoint.y)
        let frame = CGRect(origin: origin, size: parent.bounds.size)
        guard CGRectContainsPoint(frame, location) else {
            return
        }
        // convert location
        let point = CGPoint(x: location.x - origin.x, y: location.y - origin.y)
        let size = dotSize
        let index = Int(round(point.x / (size.width + padding)))
        delegate?.pageControl(self, didSelectPageAtIndex: index)
    }
}
