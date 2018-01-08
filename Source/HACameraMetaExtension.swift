//
//  HACameraMetaExtension.swift
//
//  Created by Hamza Ansari on 1/6/18.
//  Copyright © 2018 Ansaris. All rights reserved.
//

import UIKit
import AVFoundation

extension HACameraViewController: AVCaptureMetadataOutputObjectsDelegate {
    func isFaceInSideMaskBound(rect: CGRect, layer: CALayer, faceObjects: [AVMetadataFaceObject]) -> Bool {

        var isInsideRect = false
        for faceObject in faceObjects {
            let faceRect = faceObject.bounds
            isInsideRect = rect.contains(faceRect)
        }
        return isInsideRect
    }

    public func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        var faceObjects = [AVMetadataFaceObject]()
        for metadataObject in metadataObjects {
            if let metaFaceObject = metadataObject as? AVMetadataFaceObject,
                metaFaceObject.type == .face {
                if let object = self.previewLayer?.transformedMetadataObject(
                    for: metaFaceObject) as? AVMetadataFaceObject {
                    faceObjects.append(object)
                }
            }
        }
        
        guard let layer = self.previewLayer, let maskRect = maskView?.maskRect else {
            notificationCenter.post(spazerNoFaceDetectedNotification)
            return
        }
        
        if faceObjects.count > 0 ,isFaceInSideMaskBound(rect: maskRect,layer: layer, faceObjects: faceObjects) {
            notificationCenter.post(spazerFaceDetectedNotification)
        } else {
            notificationCenter.post(spazerNoFaceDetectedNotification)
        }
    }
}
