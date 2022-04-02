package com.example.recorderandroid

import android.os.Bundle
import android.os.Environment.getExternalStorageDirectory
import android.util.Log
import android.widget.Button
import android.widget.FrameLayout
import androidx.lifecycle.lifecycleScope
import kotlinx.coroutines.*
import java.io.File

class MainUnityActivity : OverrideUnityActivity() {
    private val TAG = "MainUnityActivity"

    companion object {
        /**
         * A native method that is implemented by the 'native-lib' native library,
         * which is packaged with this application.
         */
        init {
            System.loadLibrary("RecordSDK")
        }
    }

    private external fun haveVideoBuffer(): Boolean
    private external fun haveAudioBuffer(): Boolean
    private external fun consumeVideoBuffer(): ByteArray
    private external fun consumeAudioBuffer(): ByteArray
    private external fun recycleVideoBuffer(): Int
    private external fun recycleAudioBuffer(): Int

    override fun UnityInitialize() {
        print("UnityInitialize")
    }

    private var mVideoMuxer: AVmediaMuxer? = null
    private var recordJob: Job? = null

    override fun StartRecordVideo(width: Int, height: Int, recordType: Int) {
        Log.e(TAG, "===StartRecordVideo");
        mVideoMuxer = AVmediaMuxer.newInstance()
        var path = getExternalStorageDirectory().getAbsolutePath() + File.separator + "Download" + File.separator
        mVideoMuxer?.initMediaMuxer(path + "${System.currentTimeMillis()}.mp4")
        mVideoMuxer?.initAudioEncoder()
        mVideoMuxer?.initVideoEncoder(width, height, 30)
        mVideoMuxer?.startEncoder()
        recordJob = lifecycleScope.launch {
            try {
                withContext(Dispatchers.IO) {
                    while (true) {
                        if (haveVideoBuffer()) {
                            var buffer = consumeVideoBuffer()
                            mVideoMuxer?.put(buffer, null)
                            recycleVideoBuffer()
                        }else if (haveAudioBuffer()) {
                            var buffer = consumeAudioBuffer()
                            mVideoMuxer?.put(null, buffer)
                            recycleAudioBuffer()
                        }
                        delay(10)
                    }
                }
            }catch (e: Exception) {
                e.message?.let { Log.e(TAG, it) }
            }
        }
    }

    override fun StopRecordVideo() {
        Log.e(TAG, "===StopRecordVideo");
    }

    override fun ScreenDidShot(data: ByteArray, dataLenth: Int, recordType: Int) {
        Log.e(TAG, "===ScreenDidShot"+dataLenth.toString());
    }

    // Setup activity layout
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        addControlsToUnityFrame()
    }

    private fun addControlsToUnityFrame() {
        val layout: FrameLayout = mUnityPlayer
        run {
            val myButton = Button(this)
            myButton.text = "开始录制"
            myButton.x = 10f
            myButton.y = 500f
            myButton.setOnClickListener {
                startScreenRecord(UnityRecordType.none)
            }
            layout.addView(myButton, 300, 200)
        }
        run {
            val myButton = Button(this)
            myButton.text = "结束录制"
            myButton.x = 320f
            myButton.y = 500f
            myButton.setOnClickListener {
                recordJob?.cancel()
                mVideoMuxer?.stopEncoder()
                mVideoMuxer?.release()
                stopScreenRecord()
            }
            layout.addView(myButton, 300, 200)
        }
        run {
            val myButton = Button(this)
            myButton.text = "屏幕截图"
            myButton.x = 630f
            myButton.y = 500f
            myButton.setOnClickListener {
                takeScreenShot(UnityRecordType.none)
            }
            layout.addView(myButton, 300, 200)
        }
    }
}