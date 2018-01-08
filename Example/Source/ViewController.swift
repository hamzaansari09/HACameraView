//
//  ViewController.swift
//  iOS Example
//
//  Created by Hamza Ansari on 1/6/18.
//  Copyright © 2018 Ansaris. All rights reserved.
//

import UIKit
import AVFoundation
import HACameraView

class ViewController: UIViewController {

    private var videoComponent: HACameraComponent?
    
    @IBOutlet weak var countLabel: UILabel!
    @IBOutlet weak var captureImage: UIButton!
    
    var isPhotoTaken = false
    fileprivate var timer: Timer?
    
    func startTimer(){
        if timer != nil || isPhotoTaken {
            return
        }
        countLabel.text = "4"
        var count = 0
        let seconds = 4
        timer = Timer.every(1) { [weak self](timer) in
            count += 1
            self?.countLabel.text = "\(seconds-count)"
            if count==seconds{
                self?.videoComponent?.videoController.takePhoto()
                self?.stopTimer()
                self?.isPhotoTaken = true
            }
        }
    }
    
    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.videoComponent = HACameraComponent(
            atViewController: self,
            cameraPosition: .front,
            type: .profile)
        videoComponent?.videoController.cameraDelegate = self
        
        captureImage.isHidden = true
        countLabel.isHidden = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.videoComponent?.startLivePreview()
        self.view.bringSubview(toFront: captureImage)
        self.view.bringSubview(toFront: countLabel)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        stopTimer()
        addFaceDetectionNotificationObserver()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.videoComponent?.stopLivePreview()
    }
    
    func addFaceDetectionNotificationObserver() {
        isPhotoTaken = false
        
        NotificationCenter.default.addObserver(forName: Notification.Name(rawValue: HACameraControllerNotifications.faceDetected.rawValue), object: nil, queue: OperationQueue.main, using: { [weak self] notification in
            self?.captureImage.isHidden = false
            self?.countLabel.isHidden = false
            self?.startTimer()
        })
        
        //The same thing for the opposite, when no face is detected things are reset.
        NotificationCenter.default.addObserver(forName: Notification.Name(rawValue: HACameraControllerNotifications.notDetected.rawValue), object: nil, queue: OperationQueue.main, using: { [weak self] notification in
            self?.captureImage.isHidden = true
            self?.countLabel.isHidden = true
            self?.stopTimer()
        })
    }
    
    @IBAction func captureImageTapped(_ sender: Any) {
        videoComponent?.videoController.takePhoto()
    }
}

extension ViewController: HACameraViewControllerDelegate {
    func HACameraView(_ cameraView: HACameraViewController, didTake photo: UIImage) {
        let newVC = PreviewViewController(image: photo)
        NotificationCenter.default.removeObserver(self)
        self.present(newVC, animated: true, completion: nil)
    }
}

fileprivate extension Timer {
    
    // MARK: Schedule timers
    @nonobjc @discardableResult
    class func every(_ interval: TimeInterval, _ block: @escaping (Timer) -> Void) -> Timer {
        let timer = Timer.new(every: interval, block)
        timer.start()
        return timer
    }
    
    @nonobjc class func new(every interval: TimeInterval, _ block: @escaping (Timer) -> Void) -> Timer {
        var timer: Timer!
        timer = CFRunLoopTimerCreateWithHandler(kCFAllocatorDefault, CFAbsoluteTimeGetCurrent() + interval, interval, 0, 0) { _ in
            block(timer)
        }
        return timer
    }
    
    func start(runLoop: RunLoop = .current, modes: RunLoopMode...) {
        let modes = modes.isEmpty ? [.defaultRunLoopMode] : modes
        
        for mode in modes {
            runLoop.add(self, forMode: mode)
        }
    }
}
