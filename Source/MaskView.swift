//
//  LayerView.swift
//  DemoSwiftyCam
//
//  Created by Hamza Ansari on 1/6/18.
//  Copyright © 2018 Ansaris. All rights reserved.
//

import Foundation
import UIKit
import CoreGraphics

class MaskView: NSObject {
    private var fillLayer = CAShapeLayer()
    private var cameraType = CameraType.profile
    private let fillColor: UIColor = UIColor.black
    private let opacity: Float = 0.75

    var maskRect = CGRect.zero
    
    init(type: CameraType) {
        self.cameraType = type
    }

    /**
     Draw a circle mask on target view
     */
    func draw(in layer: CALayer) {
        let size = layer.bounds
        
        let path = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: size.width, height: size.height), cornerRadius: 0)
        if cameraType == .card {
            let width = size.width * 0.7
            let height = width * 4 / 5
            maskRect = CGRect(x: size.width / 2 - width / 2, y: size.height / 2 - height / 2, width: width, height: height)
            let rectPath = UIBezierPath(roundedRect: maskRect, cornerRadius: 0)
            path.append(rectPath)
        } else {
            let rad = size.width * 0.8
            maskRect = CGRect(x: size.width / 2 - rad / 2, y: size.height / 2 - rad / 2, width: rad, height: rad)
            let circlePath = UIBezierPath(roundedRect: maskRect, cornerRadius: rad)
            path.append(circlePath)
        }
        
        path.usesEvenOddFillRule = true
        
        fillLayer.path = path.cgPath
        fillLayer.fillRule = kCAFillRuleEvenOdd
        fillLayer.fillColor = self.fillColor.cgColor
        fillLayer.opacity = self.opacity
        layer.addSublayer(fillLayer)
    }
    
    func remove() {
        self.fillLayer.removeFromSuperlayer()
    }
}
