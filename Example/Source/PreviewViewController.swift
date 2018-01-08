//
//  PreviewViewController.swift
//  iOS Example
//
//  Created by Hamza Ansari on 1/6/18.
//  Copyright © 2018 Ansaris. All rights reserved.
//

import UIKit

class PreviewViewController: UIViewController {
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    private var image: UIImage
    
    init(image: UIImage) {
        self.image = image
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.gray
        let rect = CGRect(x: 0, y: 0, width: 400, height: 400)
        let backgroundImageView = UIImageView(frame: rect)
        backgroundImageView.center = view.center
        backgroundImageView.contentMode = UIViewContentMode.scaleAspectFit
        backgroundImageView.image = image
        view.addSubview(backgroundImageView)
        
        let cancelButton = UIButton(frame: CGRect(x: 10, y: 10, width: 60, height: 30))
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.addTarget(self, action: #selector(cancel), for: .touchUpInside)
        view.addSubview(cancelButton)
    }
    
    @objc func cancel() {
        dismiss(animated: true, completion: nil)
    }
}
