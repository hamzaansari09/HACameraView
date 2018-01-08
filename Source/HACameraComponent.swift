//
//  HACameraComponent.swift
//  FaceDetection
//
//  Created by Hamza Ansari on 1/6/18.
//  Copyright © 2018 Ansaris. All rights reserved.
//

import UIKit
import AVFoundation

public class HACameraComponent {
    private(set) public var videoController: HACameraViewController = HACameraViewController()
    
    enum HACameraComponentState {
        case ready
        case unknown
        case error
        case denied
    }
    
    enum HACameraComponentAction {
        case livePreview
        case unknown
    }
    private var action: HACameraComponentAction = .unknown
    private var cameraPosition: AVCaptureDevice.Position
    private var cameraType: CameraType
    
    private var state: HACameraComponentState = .unknown {
        didSet {
            switch state {
            case .ready:
                if action != .unknown {
                    self.startLivePreview()
                }
            case .unknown, .error, .denied:
                print("Unknown State")
            }
        }
    }
    
    public init(
        atViewController viewController: UIViewController,
        cameraPosition: AVCaptureDevice.Position,
        type: CameraType) {
        self.cameraPosition = cameraPosition
        self.cameraType = type

        viewController.addChildViewController(self.videoController)
        viewController.view.addSubview(self.videoController.view)
        self.videoController.didMove(toParentViewController: viewController)
        self.videoController.cameraType = type
        
        self.videoController.errorBlock = { [weak self] error in
            
            self?.state = error == .permissionDenied ? .denied : .error
            self?.showAlert(error: error)
        }
        self.videoController.componentReadyBlock = { [weak self] in
            self?.state = .ready
        }
        self.videoController.requestVideoAccess()
        self.videoController.configureDeviceCapture(cameraPosition: self.cameraPosition)
    }
    
    func showAlert(error: HACameraControllerErrors) {
        let title = state == .denied ? "Permission Denied" : "Error"
        let alert = UIAlertController(title: title, message: error.localizedDescription, preferredStyle: .alert)
        if state == .denied {
            let settingsAction = UIAlertAction(title: "Settings", style: .default) { (alertAction) in
                
                if let appSettings = URL(string: UIApplicationOpenSettingsURLString) {
                    
                    if #available(iOS 10.0, *) {
                        UIApplication.shared.open(appSettings, options: [:], completionHandler: nil)
                    } else {
                        UIApplication.shared.openURL(appSettings)
                    }
                }
            }
            alert.addAction(settingsAction)
        }
        
        alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
            let controller = UIApplication.shared.keyWindow?.rootViewController
            controller?.present(alert, animated: true, completion: nil)
        }
    }
    
    public func startLivePreview() {
        self.videoController.startCaptureSesion()
        if cameraType == .profile {
            self.videoController.setupMetaSession()
        }
    }
    
    public func stopLivePreview() {
        self.videoController.stopCaptureSession()
    }
}
