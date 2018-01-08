//
//  HACameraViewController.swift
//
//
//  Created by Hamza Ansari on 1/6/18.
//  Copyright © 2018 Ansaris. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit
import CoreImage
import ImageIO
import CoreFoundation

public protocol HACameraViewControllerDelegate: class {
    func HACameraView(_ videoView: HACameraViewController, didTake photo: UIImage)
}

public enum CameraType {
    case profile, card
}

public enum HACameraControllerErrors: Error {
    case unsupportedDevice
    case videoNotConfigured
    case undefinedError
    case permissionDenied
}

public enum HACameraControllerNotifications: String {
    case faceDetected = "com.spazer.faceDetectedNotification"
    case notDetected = "com.spazer.noFaceDetectedNotification"
}

public class HACameraViewController: UIViewController {
    
    public weak var cameraDelegate: HACameraViewControllerDelegate?

    var errorBlock: ((_ error: HACameraControllerErrors) -> Void)?
    var componentReadyBlock: (() -> Void)?
    var faceDetected : Bool?
    var previewLayer: AVCaptureVideoPreviewLayer?
    var maskView: MaskView?
    var cameraType: CameraType = .profile
    //Notifications you can subscribe to for reacting to changes in the detected properties.
    let notificationCenter : NotificationCenter = NotificationCenter.default
    let spazerNoFaceDetectedNotification = Notification(name: Notification.Name(rawValue: HACameraControllerNotifications.notDetected.rawValue), object: nil)
    let spazerFaceDetectedNotification = Notification(name: Notification.Name(rawValue: HACameraControllerNotifications.faceDetected.rawValue), object: nil)
    
    private let sessionQueue = DispatchQueue(
        label: HACameraQueuesType.session.rawValue,
        qos: .userInteractive,
        target: nil
    )
    
    private enum HACameraQueuesType: String {
        case session
        case camera
    }

    private let captureSession = AVCaptureSession()
    private var runtimeCaptureErrorObserver: NSObjectProtocol?
    private var photoFileOutput: AVCaptureStillImageOutput?
    private var metadataOutput: AVCaptureMetadataOutput?

    private func deviceWithMediaType(position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        
        if #available(iOS 10.0, *) {
            let avDevice = AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInWideAngleCamera, for: AVMediaType.video, position: position)
            return avDevice
        } else {
            // Fallback on earlier versions
            let avDevice = AVCaptureDevice.devices(for: AVMediaType.video)
            var avDeviceNum = 0
            for device in avDevice {
                print("deviceWithMediaType Position: \(device.position.rawValue)")
                if device.position == position {
                    break
                } else {
                    avDeviceNum += 1
                }
            }
            
            return avDevice[avDeviceNum]
        }
    }
    
    private func setupPreviewView(session: AVCaptureSession) {
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.masksToBounds = true
        previewLayer.videoGravity = .resizeAspectFill
        self.view.layer.addSublayer(previewLayer)
        self.previewLayer = previewLayer
        self.previewLayer?.frame = self.view.frame
    }
    
    func setupMaskView() {
        self.maskView = MaskView(type: self.cameraType)
        maskView?.draw(in: view.layer)
    }

    private func setupCaptureSession(cameraPosition: AVCaptureDevice.Position) throws {
        guard let videoDevice = self.deviceWithMediaType(position: cameraPosition) else {
            return
        }
        
        let captureDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
        
        if self.captureSession.canAddInput(captureDeviceInput) {
            self.captureSession.addInput(captureDeviceInput)
        } else {
            errorBlock?(HACameraControllerErrors.unsupportedDevice)
        }
    }

    func requestVideoAccess() {
        AVCaptureDevice.requestAccess(for: .video, completionHandler: {[weak self] _ in
            DispatchQueue.main.async {
                self?.componentReadyBlock?()
            }
        })
    }
    
    // Sets Up Capturing Devices
    func configureDeviceCapture(cameraPosition: AVCaptureDevice.Position) {

        setupPreviewView(session: captureSession)
        setupMaskView()
        configurePhotoOutput()
        
        do {
            try self.setupCaptureSession(cameraPosition: cameraPosition)
        } catch HACameraControllerErrors.unsupportedDevice {
            errorBlock?(HACameraControllerErrors.unsupportedDevice)
        } catch {
            errorBlock?(HACameraControllerErrors.undefinedError)
        }
    }
    
    public func takePhoto() {
        self.capturePhotoAsyncronously(completionHandler: { (success) in })
    }
    
    private func processPhoto(_ imageData: Data) -> UIImage {
        let dataProvider = CGDataProvider(data: imageData as CFData)
        var cgImageRef = CGImage(jpegDataProviderSource: dataProvider!, decode: nil, shouldInterpolate: true, intent: CGColorRenderingIntent.defaultIntent)

        if let previewLayer = previewLayer, let cropRect = maskView?.maskRect {
            let outputRect = previewLayer.metadataOutputRectConverted(fromLayerRect: cropRect)
            let width = CGFloat(cgImageRef!.width)
            let height = CGFloat(cgImageRef!.height)
            let cropRect = CGRect(x: outputRect.origin.x * width, y: outputRect.origin.y * height, width: outputRect.size.width * width, height: outputRect.size.height * height)
            cgImageRef = cgImageRef?.cropping(to: cropRect)
        }
        let image = UIImage(cgImage: cgImageRef!, scale: 1, orientation: .right)

        return image
    }
    
    private func capturePhotoAsyncronously(completionHandler: @escaping(Bool) -> ()) {
        
        guard captureSession.isRunning else {
            print("Cannot take photo. Capture session is not running")
            return
        }
        
        if let videoConnection = photoFileOutput?.connection(with: AVMediaType.video) {
            photoFileOutput?.captureStillImageAsynchronously(from: videoConnection, completionHandler: {(sampleBuffer, error) in
                if (sampleBuffer != nil) {
                    let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer!)
                    let image = self.processPhoto(imageData!)
                    
                    // Call delegate and return new image
                    DispatchQueue.main.async {
                        self.cameraDelegate?.HACameraView(self, didTake: image)
                    }
                    completionHandler(true)
                } else {
                    completionHandler(false)
                }
            })
        } else {
            completionHandler(false)
        }
    }
}

extension HACameraViewController {
    
    /// Configure Photo Output
    private func configurePhotoOutput() {
        let photoFileOutput = AVCaptureStillImageOutput()
        
        if self.captureSession.canAddOutput(photoFileOutput) {
            if #available(iOS 11, *) {
                photoFileOutput.outputSettings  = [AVVideoCodecKey: AVVideoCodecType.jpeg]
            }else{
                photoFileOutput.outputSettings  = [AVVideoCodecKey: AVVideoCodecJPEG]
            }
            self.captureSession.addOutput(photoFileOutput)
            self.photoFileOutput = photoFileOutput
        }
    }
    
    func startCaptureSesion() {
        self.captureSession.startRunning()
        self.previewLayer?.connection?.automaticallyAdjustsVideoMirroring = false
        self.previewLayer?.connection?.isVideoMirrored = true
        self.runtimeCaptureErrorObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name.AVCaptureSessionRuntimeError,
            object: self.captureSession,
            queue: nil
        ) { [weak self] _ in
            self?.errorBlock?(HACameraControllerErrors.undefinedError)
        }
    }

    func stopCaptureSession() {
        self.captureSession.stopRunning()
        if let observer = self.runtimeCaptureErrorObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    func setupMetaSession() {
        guard self.metadataOutput == nil else {
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        metadataOutput.setMetadataObjectsDelegate(self, queue: self.sessionQueue)

        if self.captureSession.canAddOutput(metadataOutput) {
            self.captureSession.addOutput(metadataOutput)
        }

        if metadataOutput.availableMetadataObjectTypes.contains(where: { (type) -> Bool in return type == .face}) {
            metadataOutput.metadataObjectTypes = [.face]
        } else {
           self.errorBlock?(HACameraControllerErrors.undefinedError)
        }
        
        self.metadataOutput = metadataOutput
    }
}
