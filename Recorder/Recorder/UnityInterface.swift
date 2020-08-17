//
//  UnityInterfac.swift
//  Recorder
//
//  Created by xu on 2020/7/27.
//  Copyright © 2020 SceneConsole. All rights reserved.
//

import Foundation
import UIKit

extension FileManager {
    
    static let videoRootPath = NSSearchPathForDirectoriesInDomains(.documentationDirectory, .userDomainMask, true).first!.appending("/RecordVideos")

}

extension UIImage {
    
    func rectFitWithContentMode(_ rect: CGRect, size: CGSize, mode: UIView.ContentMode) -> CGRect {
        let stdRect = rect.standardized
        let center = CGPoint(x: stdRect.midX, y: stdRect.midY)
        var ret: CGRect = .zero
        switch mode {
        case .scaleAspectFit,.scaleAspectFill:
            var scale: CGFloat = 0
            if mode == .scaleAspectFit {
                if (size.width / size.height < stdRect.size.width / stdRect.size.height) {
                    scale = stdRect.size.height / size.height;
                } else {
                    scale = stdRect.size.width / size.width;
                }
            }else{
                if (size.width / size.height < stdRect.size.width / stdRect.size.height) {
                    scale = stdRect.size.width / size.width;
                } else {
                    scale = stdRect.size.height / size.height;
                }
                ret.size = CGSize(width: size.width * scale, height: size.height * scale)
                ret.origin = CGPoint(x: center.x - ret.size.width * 0.5, y: center.y - ret.size.height * 0.5)
            }
        case .center:
            ret.size = size
            ret.origin = CGPoint(x: center.x - size.width * 0.5, y: center.y - size.height * 0.5)
        case .top:
            ret.size = size
            ret.origin.x = center.x - size.width * 0.5
        case .bottom:
            ret.size = size
            ret.origin = CGPoint(x: center.x - size.width * 0.5, y: rect.size.height - size.height)
        case .left:
            ret.size = size
            ret.origin.y = center.y - size.height * 0.5
        case .right:
            ret.size = size
            ret.origin = CGPoint(x: rect.size.width - size.width, y: center.y - size.height * 0.5)
        case .scaleToFill,.redraw:
            ret = stdRect
        default:
            ret = stdRect
        }
        return ret
    }
    
    func screentShotConverter(rawData: Bool) -> UIImage? {
        let image = rawData ? UIImage(cgImage: self.cgImage!, scale: UIScreen.main.scale, orientation: .leftMirrored) : UIImage(cgImage: self.cgImage!, scale: UIScreen.main.scale, orientation: .up)
        let rect = UIScreen.main.bounds
        UIGraphicsBeginImageContextWithOptions(rect.size, false, UIScreen.main.scale)
        let fitRect = rectFitWithContentMode(rect, size: image.size, mode: .scaleAspectFill)
        image.draw(in: fitRect)
        let ret = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return ret
    }
    
    func crop(rect: CGRect) -> UIImage? {
        let scale = UIScreen.main.scale
        let crop = CGRect(x: rect.minX*scale, y: rect.minY*scale, width: rect.width*scale, height: rect.height*scale)
        if let ref = self.cgImage?.cropping(to: crop) {
            return UIImage(cgImage: ref, scale: scale, orientation: .up)
        }else{
            return nil
        }
    }
    
}

class UnityInterface: NativeCallsProtocol {
    
    enum UnityRecordType: Int {
        case screen = 1 //屏幕
        case camera = 0 //摄像头原始数据
    }
    
    static let shared = UnityInterface()
    
    let fileManager = FileManager.default
    
    // MARK: - 屏幕截图
    var screenShotCompletion: ((UIImage?) -> Void)?
    
    // MARK: - 视频录制
    var videoRecorder: VideoRecorder?
    var isRecordStart: Bool = false
    
    var videoPath: String?
    
    var outputRect: CGRect?
    var screenRecordProgress: ((TimeInterval) -> Void)?
    var screenRecordCompletion: ((String?) -> Void)?
    
    func unityInitialize() {
        if !fileManager.fileExists(atPath: FileManager.videoRootPath) {
            try? fileManager.createDirectory(atPath: FileManager.videoRootPath, withIntermediateDirectories: true, attributes: nil)
        }
        let vc = ViewController()
        vc.view.frame = UIScreen.main.bounds
        let unity = Unity.unityViewController()
        unity?.view.addSubview(vc.view)
        unity?.addChild(vc)
    }
    
    func takeScreenShot(type: UnityRecordType, completion: ((UIImage?) -> Void)?) {
        screenShotCompletion = completion
        Unity.sendUnityMessage(("AR Session Origin", "TakeScreenShot", "\(type.rawValue)"))
    }
    
    func startScreenRecord(type: UnityRecordType, output: CGRect?, progress: ((TimeInterval) -> Void)?) {
        outputRect = output
        screenRecordProgress = progress
        Unity.sendUnityMessage(("AR Session Origin", "StartRecord", "\(type.rawValue)"))
    }
    
    func stopScreenRecord(_ completion: ((String?) -> Void)?) {
        screenRecordCompletion = completion
        Unity.sendUnityMessage(("AR Session Origin", "FinishRecord", ""))
    }
    
}

// MARK: - 视频录制
extension UnityInterface {
    
    func screenDidShot(_ data: UnsafeMutablePointer<UInt8>?, length: Int, recordType type: Int) {
        if let raw = data {
            let imgData = Data(bytes: raw, count: length)
            let image = UIImage(data: imgData)
            screenShotCompletion?(image?.screentShotConverter(rawData: type == 0))
        }
    }
    
    func startRecordVideo(_ name: String?, width: Int, height: Int, recordType type: Int) {
        if !isRecordStart {
            isRecordStart = true
            
            var videoName = name
            if videoName == nil {
                videoName = String(Int(NSDate().timeIntervalSince1970))
            }
            videoPath = FileManager.videoRootPath.appendingFormat("/%@.mp4", videoName!)
            if fileManager.fileExists(atPath: videoPath!) {
                try? fileManager.removeItem(atPath: videoPath!)
            }
            
            videoRecorder = VideoRecorder(path: URL(fileURLWithPath: videoPath!), inSize: CGSize(width: width, height: height), outRect: outputRect ?? UIScreen.main.bounds, rawImageData: type == 0)
            
            screenRecordProgress?(0)
        }
    }
    
    func receiveVideoData(fromUnity data: UnsafeMutablePointer<UInt8>?, length: Int) {
        if isRecordStart, let byteData = data {
            videoRecorder?.encode(audioBuffer: nil, videoBuffer: byteData)
            screenRecordProgress?(videoRecorder?.time ?? 0)
        }
    }
    
    func stopRecordVideo() {
        if isRecordStart {
            isRecordStart = false
            videoRecorder?.finishRecording(completionHandler: { [weak self] in
                DispatchQueue.main.async {
                    self?.videoRecorder = nil
                    self?.screenRecordCompletion?(self!.videoPath)
                }
            })
        }
    }
    
}
