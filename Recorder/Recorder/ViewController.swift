//
//  ViewController.swift
//  Recorder
//
//  Created by xu on 2020/7/27.
//  Copyright © 2020 SceneConsole. All rights reserved.
//

import UIKit
import AVKit

class ViewController: UIViewController {
    
    @IBOutlet weak var infoLabel: UILabel!
    
    var type: UnityInterface.UnityRecordType = .camera
    
    @IBAction func typeSwitchAction(_ sender: UISegmentedControl) {
        type = sender.selectedSegmentIndex == 0 ? .camera : .screen
    }
    
    @IBAction func snapshotAction(_ sender: UIButton) {
        UnityInterface.shared.takeScreenShot(type: type) { [weak self] (img) in
            let vc = ImageViewController(image: img)
            self?.present(vc, animated: true, completion: nil)
        }
    }
    
    @IBAction func recordAction(_ sender: UIButton) {
        if !sender.isSelected {
            UnityInterface.shared.startScreenRecord(type: type, output: nil) { [weak self] (time) in
                self?.infoLabel.text = "\(time)"
            }
        }else{
            UnityInterface.shared.stopScreenRecord { [weak self] path in
                if let string = path {
                    self?.play(url: string)
                }
            }
        }
        sender.isSelected = !sender.isSelected
    }
    
    func play(url: String) {
        let vc = AVPlayerViewController()
        vc.player = AVPlayer(url: URL(fileURLWithPath: url))
        present(vc, animated: true, completion: nil)
    }
    
}

class ImageViewController: UIViewController {
    
    let image: UIImage?
    
    init(image: UIImage?) {
        self.image = image
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let imageView = UIImageView(frame: UIScreen.main.bounds)
        imageView.image = image
        view.addSubview(imageView)
    }
    
}
