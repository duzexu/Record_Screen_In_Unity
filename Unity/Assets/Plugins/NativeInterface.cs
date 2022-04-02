using System;
using System.Collections;
using System.Collections.Generic;
using System.Runtime.InteropServices;

using UnityEngine;

public class NativeInterface : MonoBehaviour
{
#if UNITY_EDITOR
    public static class NativeAPI
    {
        public static void UnityInitialize() { }

        public static void StartRecordVideo(int width, int height, int recordType) { }

        public static void SendVideoData(byte[] data, int dataLenth) { }

        public static void SendAudioData(byte[] data, int dataLenth, int channel) { }

        public static void StopRecordVideo() { }

        public static void ScreenDidShot(byte[] data, int dataLenth, int recordType) { }
    }
#elif UNITY_IOS
    public static class NativeAPI
    {
        [DllImport("__Internal")]
        public static extern void UnityInitialize();

        [DllImport("__Internal")]
        public static extern void StartRecordVideo(int width, int height, int recordType);

        [DllImport("__Internal")]
        public static extern void SendVideoData(byte[] data, int dataLenth);

        [DllImport("__Internal")]
        public static extern void SendAudioData(byte[] data, int dataLenth, int channel);

        [DllImport("__Internal")]
        public static extern void StopRecordVideo();

        [DllImport("__Internal")]
        public static extern void ScreenDidShot(byte[] data, int dataLenth, int recordType);
    }
#elif UNITY_ANDROID
    public static class NativeAPI
    {
        [DllImport("RecordSDK")]
        public static extern void initVideoBufferProvider(int width, int height);

        [DllImport("RecordSDK")]
        public static extern void initAudioBufferProvider(int length);

        [DllImport("RecordSDK")]
        public static extern void cleanBufferProvider();

        [DllImport("RecordSDK")]
        public static extern void copyVideoBuffer2Cyc(byte[] buffer, int len);

        [DllImport("RecordSDK")]
        public static extern void copyAudioBuffer2Cyc(byte[] buffer, int len);

        private static AndroidJavaObject javaActivity;

        public static void UnityInitialize()
        {
            InitActivity();
            try
            {
                javaActivity.Call("UnityInitialize");
            }
            catch (Exception ex)
            {
                Debug.Log(ex.Message);
            }
        }

        public static void StartRecordVideo(int width, int height, int recordType)
        {
            InitActivity();
            initVideoBufferProvider(width, height);
            initAudioBufferProvider(4096);
            try
            {
                javaActivity.Call("StartRecordVideo", width, height, recordType);
            }
            catch (Exception ex)
            {
                Debug.Log(ex.Message);
            }
        }

        public static void SendVideoData(byte[] data, int dataLenth)
        {
            copyVideoBuffer2Cyc(data, dataLenth);
        }

        public static void SendAudioData(byte[] data, int dataLenth, int channel)
        {
            copyAudioBuffer2Cyc(data, dataLenth);
        }

        public static void StopRecordVideo()
        {
            InitActivity();
            try
            {
                javaActivity.Call("StopRecordVideo");
            }
            catch (Exception ex)
            {
                Debug.Log(ex.Message);
            }
            cleanBufferProvider();
        }

        public static void ScreenDidShot(byte[] data, int dataLenth, int recordType)
        {
            InitActivity();
            javaActivity.Call("ScreenDidShot", data, dataLenth, recordType);
        }

        private static void InitActivity()
        {
            if (javaActivity == null)
            {
                try
                {
                    AndroidJavaClass jc = new AndroidJavaClass("com.example.recorderandroid.OverrideUnityActivity");
                    javaActivity = jc.GetStatic<AndroidJavaObject>("instance");
                }
                catch (Exception ex)
                {
                    Debug.Log(ex.Message);
                }
            }
        }
    }
#endif
}
