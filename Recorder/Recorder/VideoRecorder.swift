//
//  SCVideoRecorder.swift
//  UnitySwiftMix
//
//  Created by xu on 2019/11/28.
//  Copyright © 2019 tech. All rights reserved.
//

import UIKit
import GPUImage

class VideoRecorder: NSObject {
    
    var time: TimeInterval = .zero
    
    private var input: GPUImageRawDataInput?
    private var transform: GPUImageTransformFilter?
    private var filter: GPUImageCropFilter!
    private var output: GPUImageMovieWriter!
    
    private var inputSize: CGSize!
    
    private var timeStamp: TimeInterval = 0
        
    init(path: URL, inSize: CGSize, outRect: CGRect, rawImageData: Bool) {
        super.init()
        inputSize = inSize
        time = .zero
        
        //输出视频宽高必须是16的倍数
        var outSize = outRect.size
        outSize.width = outSize.width.truncating(by: 16)
        outSize.height = outSize.height.truncating(by: 16)
        output = GPUImageMovieWriter(movieURL: path, size: CGSize(width: outSize.width*UIScreen.main.scale, height: outSize.height*UIScreen.main.scale), fileType: AVFileType.mp4.rawValue, outputSettings: nil)
        output.assetWriter.shouldOptimizeForNetworkUse = true
        output.hasAudioTrack = true
        output.encodingLiveVideo = true
        output.assetWriter.movieFragmentInterval = .invalid;
        
        let screenSize = UIScreen.main.bounds.size
        let width = (outSize.width/screenSize.width).trim(decimal: 2)
        
        if rawImageData {
            transform = GPUImageTransformFilter()
            transform?.ignoreAspectRatio = true
            transform?.transform3D = CATransform3DMakeRotation(CGFloat.pi/2, 0, 0, 1)
            let region = CGRect(x: ((1-width)/2).trim(decimal: 3), y: (outRect.origin.y/screenSize.height).trim(decimal: 2), width: width, height: (outSize.height/screenSize.height).trim(decimal: 2))
            filter = GPUImageCropFilter(cropRegion: region)
            transform?.addTarget(filter)
        }else{
            let region = CGRect(x: ((1-width)/2).trim(decimal: 3), y: ((screenSize.height-outRect.origin.y-outRect.size.height)/screenSize.height).trim(decimal: 2), width: width, height: (outSize.height/screenSize.height).trim(decimal: 2))
            filter = GPUImageCropFilter(cropRegion: region)
            output.setInputRotation(kGPUImageFlipVertical, at: 0)
        }
        filter.addTarget(output)
    }
    
    /// 接收音频和视频数据
    /// - Parameters:
    ///   - audioBuffer: 音频数据
    ///   - videoBuffer: 视频数据
    func encode(audioBuffer: CMSampleBuffer?, videoBuffer: UnsafeMutablePointer<UInt8>?) {
        if videoBuffer != nil {
            if input == nil {
                input = GPUImageRawDataInput(bytes: videoBuffer!, size: inputSize, pixelFormat: GPUPixelFormatBGRA)
                if transform != nil {
                    input?.addTarget(transform!)
                }else{
                    input?.addTarget(filter)
                }
                output.startRecording()
                input?.processData(forTimestamp: pts())
            }else{
                input?.updateData(fromBytes: videoBuffer!, size: inputSize)
                input?.processData(forTimestamp: pts())
            }
        }
        if audioBuffer != nil && input != nil {
            if let buffer = modifyAudio(sampleBuffer: audioBuffer!, offset: pts()) {
                output?.processAudioBuffer(buffer)
            }
        }
    }
    
    func finishRecording(completionHandler: @escaping (()-> Void)) {
        output.finishRecording(completionHandler: completionHandler)
        timeStamp = 0
    }
    
    private func pts() -> CMTime {
        if timeStamp == 0 {
            timeStamp = NSDate().timeIntervalSince1970*1000
        }
        let pts = CMTimeMake(value: Int64(NSDate().timeIntervalSince1970*1000-timeStamp), timescale: 1000)
        time = CMTimeGetSeconds(pts)
        return pts
    }
    
    private func modifyAudio(sampleBuffer: CMSampleBuffer, offset: CMTime) -> CMSampleBuffer? {
        var timing = CMSampleTimingInfo(duration: CMTimeMake(value: 1 , timescale: 44100), presentationTimeStamp: offset, decodeTimeStamp: CMTime.invalid)
        var buffer: CMSampleBuffer?;
        CMSampleBufferCreateCopyWithNewTiming(allocator: nil, sampleBuffer: sampleBuffer, sampleTimingEntryCount: 1, sampleTimingArray: &timing, sampleBufferOut: &buffer);
        return buffer;
    }
    
}

extension CGFloat {
    
    // 保留几位小数
    func trim(decimal: Int) -> CGFloat {
        let format = "%.\(decimal)f"
        let str = String(format: format, self)
        return CGFloat(Double(str)!)
    }
    
    // 整除
    func truncating(by: Self) -> Self {
        let divid = (self - self.truncatingRemainder(dividingBy: by))/by
        let ret1 = divid*by
        let ret2 = (divid+1)*by
        return abs(ret1-self) < abs(ret2-self) ? ret1 : ret2
    }
    
    static func random(lower: CGFloat = 0, upper: CGFloat = 1) -> CGFloat {
        return CGFloat(Float(arc4random()) / Float(UInt32.max)) * (upper - lower) + lower
    }

}
