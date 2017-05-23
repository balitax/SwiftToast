//
//  SwiftToast.swift
//  SwiftToast
//
//  Created by Daniele Boscolo on 05/04/17.
//  Copyright © 2017 Daniele Boscolo. All rights reserved.
//

import UIKit

public protocol SwiftToastDelegate {
    func swiftToastDidTouchUpInside(_ swiftToast: SwiftToast)
}

public enum SwiftToastStyle {
    case navigationBar
    case statusBar
}

public class SwiftToast {
    public var text: String
    public var textAlignment: NSTextAlignment
    public var image: UIImage?
    public var backgroundColor: UIColor
    public var textColor: UIColor
    public var font: UIFont
    public var duration: Double?
    public var statusBarStyle: UIStatusBarStyle
    public var aboveStatusBar: Bool
    public var isUserInteractionEnabled: Bool
    public var target: SwiftToastDelegate?
    public var style: SwiftToastStyle
    
    public static var defaultValue = SwiftToast()
    
    init() {
        text = ""
        textAlignment = .center
        image = nil
        backgroundColor = .red
        textColor = .white
        font = .systemFont(ofSize: 14.0)
        duration = 2.0
        statusBarStyle = .lightContent
        aboveStatusBar = false
        isUserInteractionEnabled = true
        target = nil
        style = .navigationBar
    }
    
    public init(text: String? = nil,
                textAlignment: NSTextAlignment? = nil,
                image: UIImage? = nil,
                backgroundColor: UIColor? = nil,
                textColor: UIColor? = nil,
                font: UIFont? = nil,
                duration: Double? = 0.0,
                statusBarStyle: UIStatusBarStyle? = nil,
                aboveStatusBar: Bool? = nil,
                isUserInteractionEnabled: Bool? = nil,
                target: SwiftToastDelegate? = nil,
                style: SwiftToastStyle? = nil)
    {
        self.text = text ?? SwiftToast.defaultValue.text
        self.textAlignment = textAlignment ?? SwiftToast.defaultValue.textAlignment
        self.image = image ?? SwiftToast.defaultValue.image
        self.backgroundColor = backgroundColor ?? SwiftToast.defaultValue.backgroundColor
        self.textColor = textColor ?? SwiftToast.defaultValue.textColor
        self.font = font ?? SwiftToast.defaultValue.font
        self.duration = duration == 0 ? SwiftToast.defaultValue.duration : duration
        self.statusBarStyle = statusBarStyle ?? SwiftToast.defaultValue.statusBarStyle
        self.aboveStatusBar = aboveStatusBar ?? SwiftToast.defaultValue.aboveStatusBar
        self.isUserInteractionEnabled = isUserInteractionEnabled ?? SwiftToast.defaultValue.isUserInteractionEnabled
        self.target = target ?? SwiftToast.defaultValue.target
        self.style = style ?? SwiftToast.defaultValue.style
    }
}

class SwiftToastController {

    // MARK:- Private vars
    static var shared = SwiftToastController()
    fileprivate var toastView: SwiftToastView? = SwiftToastView.nib()
    fileprivate var toastViewHeightConstraint: NSLayoutConstraint?
    fileprivate var topConstraint: NSLayoutConstraint?
    fileprivate var hideTimer: Timer = Timer()
    fileprivate var currentToast: SwiftToast = SwiftToast()
    fileprivate var delegate: SwiftToastDelegate?

    private init() {
        self.setup()
    }
    
    // MARK:- Setup
    
    private func setup() {
        if let keyWindow = UIApplication.shared.keyWindow {
            guard let toastView = toastView else {
                return
            }
            toastView.delegate = self
            keyWindow.addSubview(toastView)
            
            // Set constraints
            toastView.translatesAutoresizingMaskIntoConstraints = false
            topConstraint = NSLayoutConstraint(item: toastView, attribute: .top, relatedBy: .equal, toItem: keyWindow, attribute: .top, multiplier: 1, constant: -toastView.frame.size.height)
            let leadingConstraint = NSLayoutConstraint(item: toastView, attribute: .leading, relatedBy: .equal, toItem: keyWindow, attribute: .leading, multiplier: 1, constant: 0)
            let trailingConstraint = NSLayoutConstraint(item: toastView, attribute: .trailing, relatedBy: .equal, toItem: keyWindow, attribute: .trailing, multiplier: 1, constant: 0)
            configureToastStyle()
            keyWindow.addConstraints([topConstraint!, leadingConstraint, trailingConstraint, toastViewHeightConstraint!])
        }
    }
    
    func configureToastStyle() {
        // Remove current constraints
        if let toastViewHeightConstraint = toastViewHeightConstraint, let keyWindow = UIApplication.shared.keyWindow {
            keyWindow.removeConstraint(toastViewHeightConstraint)
        }
        
        switch currentToast.style {
        case .navigationBar:
            toastView?.viewTopConstraint.constant = 25.0
            toastView?.viewBottomConstraint.constant = 16.0
            toastViewHeightConstraint = NSLayoutConstraint(item: toastView, attribute: .height, relatedBy: .greaterThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 64.0)
        case .statusBar:
            toastView?.viewTopConstraint.constant = 0.0
            toastView?.viewBottomConstraint.constant = 0.0
            toastViewHeightConstraint = NSLayoutConstraint(item: toastView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 20.0)
        }
        
        // Add new constraints
        if let toastViewHeightConstraint = toastViewHeightConstraint, let keyWindow = UIApplication.shared.keyWindow {
            keyWindow.addConstraint(toastViewHeightConstraint)
        }
    }
    
    func configureStatusBar(hide: Bool) {
        if hide {
            if currentToast.style == .statusBar || currentToast.aboveStatusBar {
                UIApplication.shared.keyWindow?.windowLevel = UIWindowLevelStatusBar + 1
            } else {
                UIApplication.shared.statusBarStyle = currentToast.statusBarStyle
            }
        } else {
            UIApplication.shared.keyWindow?.windowLevel = UIWindowLevelNormal
            UIApplication.shared.statusBarStyle = applicationStatusBarStyle
        }
    }
    
    // MARK:- Customizations

    // status bar
    var applicationStatusBarStyle: UIStatusBarStyle = UIApplication.shared.statusBarStyle
    
    // MARK:- Public functions
    
    func present(_ toast: SwiftToast, animated: Bool) {
        guard let toastView = toastView else {
            return
        }

        dismiss(animated) {
            // after dismiss if needed, setup toast
            self.currentToast = toast
            self.configureToastStyle()
            self.delegate = toast.target
            
            toastView.configure(with: toast.text,
                                textColor: toast.textColor,
                                font: toast.font,
                                textAlignment: toast.textAlignment,
                                image: toast.image,
                                color: toast.backgroundColor,
                                isUserInteractionEnabled: toast.isUserInteractionEnabled)
            UIApplication.shared.keyWindow?.layoutIfNeeded()

            // present
            UIView.animate(withDuration: animated ? 0.3 : 0.0, delay: 0.0, options: .curveEaseOut, animations: {
                self.topConstraint?.constant = 0.0
                self.configureStatusBar(hide: true)
                UIApplication.shared.keyWindow?.layoutIfNeeded()
                
            }, completion: { (_ finished) in
                if finished, let duration = toast.duration {
                    self.hideTimer = Timer.scheduledTimer(timeInterval: duration, target: self, selector: #selector(self.hideTimerSelector(_:)), userInfo: animated, repeats: false)
                }
            })
        }
    }
    
    // MARK:- Animations
    
    @objc func hideTimerSelector(_ timer: Timer) {
        let animated = (timer.userInfo as? Bool) ?? false
        dismiss(animated, completion: nil)
    }
    
    var dismissForTheFirstTime = true
    func dismiss(_ animated: Bool, completion: (() -> Void)? = nil) {
        guard let toastView = toastView, !dismissForTheFirstTime else {
            dismissForTheFirstTime = false
            completion?()
            return
        }
        
        hideTimer.invalidate()
        
        UIView.animate(withDuration: animated ? 0.3 : 0.0, delay: 0, options: .curveEaseOut, animations: {
            self.topConstraint?.constant = -toastView.frame.size.height
            UIApplication.shared.keyWindow?.layoutIfNeeded()
        }, completion: { (_ finished) in
            if finished {
                self.configureStatusBar(hide: false)
                completion?()
            }
        })
    }
}

extension SwiftToastController: SwiftToastViewDelegate {
    func swiftToastViewDidTouchUpInside(_ swiftToastView: SwiftToastView) {
        dismiss(true, completion: nil)
        delegate?.swiftToastDidTouchUpInside(currentToast)
    }
}
