using System.Collections;
using System.Collections.Generic;
using System.Runtime.InteropServices;

using UnityEngine;

public class NativeInterface : MonoBehaviour
{
#if UNITY_IOS
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
#endif
}
