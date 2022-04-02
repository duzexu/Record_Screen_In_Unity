package com.example.recorderandroid;

/**
 * Created by xxx on 18-1-31.
 */

import android.media.MediaCodec;
import android.media.MediaFormat;
import android.media.MediaMuxer;
import android.util.Log;

import java.nio.ByteBuffer;
import java.util.concurrent.LinkedBlockingQueue;

public class AVmediaMuxer{
    private final static String TAG = "AVmediaMuxer";
    public static final int TRACK_VIDEO = 0;
    public static final int TRACK_AUDIO = 1;
    private final Object lock = new Object();
    private MediaMuxer mediaMuxer;
    //缓冲传输过来的数据
    private LinkedBlockingQueue<MuxerData> muxerDatas = new LinkedBlockingQueue<>();
    private int videoTrackIndex = -1;
    private int audioTrackIndex = -1;
    private boolean isVideoAdd;
    private boolean isAudioAdd;
    private Thread workThread;
    private AVEncoder mAVEncoder;
    private boolean isMediaMuxerStart;
    private volatile boolean loop;

    private AVmediaMuxer() {
    }

    public static AVmediaMuxer newInstance() {
        return new AVmediaMuxer();
    }

    public void initMediaMuxer(String outfile) {
        if (loop) {
            throw new RuntimeException("====MediaMuxer线程已经启动===");
        }
        try {
            Log.d(TAG, "====创建媒体混合器 start...");
            mediaMuxer = new MediaMuxer(outfile, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4);
            Log.d(TAG, "====创建媒体混合器 done...");
        }catch (Exception e){
            e.printStackTrace();
            Log.e(TAG, "====创建媒体混合器 error: "+e.toString());
        }
        mAVEncoder = AVEncoder.newInstance();
        Log.d(TAG, "====设置回调监听===");
        setListener();
        workThread = new Thread("mediaMuxer-thread") {
            @Override
            public void run() {
                //混合器未开启
                synchronized (lock) {
                    try {
                        Log.d(TAG, "====媒体混合器等待开启...");
                        lock.wait();
                    } catch (InterruptedException e) {
                        e.printStackTrace();
                    }
                }
                while (loop && !Thread.interrupted()) {
                    try {
                        MuxerData data = muxerDatas.take();
                        int track = -1;
                        if (data.trackIndex == TRACK_VIDEO) {
                            track = videoTrackIndex;
                        } else if(data.trackIndex == TRACK_AUDIO){
                            track = audioTrackIndex;
                        }
                        Log.d(TAG, "====track: "+track+"    写入混合数据大小 " + data.bufferInfo.size);
                        //添加数据
                        mediaMuxer.writeSampleData(track, data.byteBuf, data.bufferInfo);
                    } catch (InterruptedException e) {
                        Log.e(TAG, "===写入混合数据失败!" + e.toString());
                        e.printStackTrace();
                    }
                }
                muxerDatas.clear();
                stopMediaMuxer();
                Log.d(TAG, "=====媒体混合器退出...");
            }
        };

        loop = true;
        workThread.start();
    }

    /**
     * 初始化视频编码器
     */
    public void initVideoEncoder(int width,int height,int fps){
        mAVEncoder.initVideoEncoder(width,height,fps);
    }

    /**
     * 初始化音频编码器
     */
    public void initAudioEncoder(){
        mAVEncoder.initAudioEncoder(44100,16,2);
    }

    /**
     * 释放
     */
    public void release() {
        loop = false;
        if (workThread != null) {
            workThread.interrupt();
        }
        mAVEncoder = null;
    }

    public void put(byte[] video, byte[] audio) {
        if (audio != null) {
            mAVEncoder.putAudioData(audio);
        }
        if (video != null) {
            mAVEncoder.putVideoData(video);
        }
    }

    private void startMediaMuxer() {
        if (isMediaMuxerStart)
            return;
        synchronized (lock) {
            if (isVideoAdd && isAudioAdd) {
                Log.d(TAG, "====启动媒体混合器=====");
                mediaMuxer.start();
                isMediaMuxerStart = true;
                lock.notify();
            }
        }
    }

    private void stopMediaMuxer() {
        if (!isMediaMuxerStart)
            return;
        mediaMuxer.stop();
        mediaMuxer.release();
        isMediaMuxerStart = false;
        isAudioAdd = false;
        isVideoAdd = false;
        Log.d(TAG, "====停止媒体混合器=====");
    }

    /**
     * 开始编码
     */
    public void startEncoder() {
        mAVEncoder.start();
    }

    /**
     * 停止编码
     */
    public void stopEncoder() {
        mAVEncoder.stop();
    }

    private void setListener() {
        mAVEncoder.setCallback(new AVEncoder.Callback() {
            @Override
            public void outputVideoFrame(final int trackIndex, final ByteBuffer outBuf, final MediaCodec.BufferInfo bufferInfo) {
                try {
                    Log.d(TAG, "====outputVideoFrame=====");
                    muxerDatas.put(new MuxerData(
                            trackIndex, outBuf, bufferInfo));
                } catch (InterruptedException e) {
                    Log.e(TAG, "====outputVideoFrame=====error: " + e.toString());
                    e.printStackTrace();
                }
            }

            @Override
            public void outputAudioFrame(final int trackIndex,final ByteBuffer outBuf,final MediaCodec.BufferInfo bufferInfo) {
                try {
                    Log.d(TAG, "====outputAudioFrame=====");
                    muxerDatas.put(new MuxerData(
                            trackIndex, outBuf, bufferInfo));
                } catch (InterruptedException e) {
                    Log.e(TAG, "====outputAudioFrame=====error: "+e.toString());
                    e.printStackTrace();
                }
            }

            @Override
            public void outMediaFormat(final int trackIndex, MediaFormat mediaFormat) {
                if (trackIndex == TRACK_AUDIO) {
                    Log.d(TAG, "====addAudioMediaFormat======mediaMuxer: " + (mediaMuxer != null));
                    if (mediaMuxer != null) {
                        audioTrackIndex = mediaMuxer.addTrack(mediaFormat);
                        isAudioAdd = true;
                    }
                } else if (trackIndex == TRACK_VIDEO) {
                    Log.d(TAG, "====addVideoMediaFormat=======mediaMuxer: " + (mediaMuxer != null));
                    if (mediaMuxer != null) {
                        videoTrackIndex = mediaMuxer.addTrack(mediaFormat);
                        isVideoAdd = true;
                    }
                }
                startMediaMuxer();
            }
        });
    }

    /**
     * 封装需要传输的数据类型
     */
    public static class MuxerData {
        int trackIndex;
        ByteBuffer byteBuf;
        MediaCodec.BufferInfo bufferInfo;

        public MuxerData(int trackIndex, ByteBuffer byteBuf, MediaCodec.BufferInfo bufferInfo) {
            this.trackIndex = trackIndex;
            this.byteBuf = byteBuf;
            this.bufferInfo = bufferInfo;
        }
    }

}
