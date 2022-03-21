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
    
    func encode(audioBuffer: UnsafeMutablePointer<UInt8>?, length: Int, channel: UInt32) {
        if audioBuffer != nil {
            if let buffer = sampleBuffer(data: audioBuffer!, length: length, channel: channel) {
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
    
    private func sampleBuffer(data: UnsafeMutablePointer<UInt8>, length: Int, channel: UInt32) -> CMSampleBuffer? {
        var asbd: AudioStreamBasicDescription = AudioStreamBasicDescription(mSampleRate: 44100, mFormatID: kAudioFormatLinearPCM, mFormatFlags: kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked, mBytesPerPacket: 2*channel, mFramesPerPacket: 1, mBytesPerFrame: 2*channel, mChannelsPerFrame: channel, mBitsPerChannel: 8 * 2, mReserved: 0)
        var format: CMAudioFormatDescription!
        var error: OSStatus = CMAudioFormatDescriptionCreate(allocator: nil, asbd: &asbd, layoutSize: 0, layout: nil, magicCookieSize: 0, magicCookie: nil, extensions: nil, formatDescriptionOut: &format)
        if error != 0 {
            print("Error in CMAudioFormatDescriptionCreater \(error)")
        }else{
            var timing = CMSampleTimingInfo(duration: CMTimeMake(value: 1 , timescale: 44100), presentationTimeStamp: pts(), decodeTimeStamp: CMTime.invalid)
            let numberOfFrames = length/(2*Int(channel))
            var buffer: CMSampleBuffer?
            error = CMSampleBufferCreate(allocator: nil, dataBuffer: nil, dataReady: false, makeDataReadyCallback: nil, refcon: nil, formatDescription: format, sampleCount: numberOfFrames, sampleTimingEntryCount: 1, sampleTimingArray: &timing, sampleSizeEntryCount: 0, sampleSizeArray: nil, sampleBufferOut: &buffer)
            if error != 0 {
                print("Error in CMSampleBufferCreate \(error)")
            }else{
                var audioList: AudioBufferList = AudioBufferList()
                audioList.mNumberBuffers = 1
                audioList.mBuffers.mData = UnsafeMutableRawPointer(data)
                audioList.mBuffers.mNumberChannels = channel
                audioList.mBuffers.mDataByteSize = UInt32(length)
                error = CMSampleBufferSetDataBufferFromAudioBufferList(buffer!, blockBufferAllocator: nil, blockBufferMemoryAllocator: nil, flags: 0, bufferList: &audioList)
                if (error != 0) {
                    print("Error in CMSampleBufferSetDataBufferFromAudioBufferList \(error)")
                }else{
                    return buffer
                }
            }
        }
        return nil
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
