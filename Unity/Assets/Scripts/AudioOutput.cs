using System;
using System.Collections;
using System.Collections.Generic;

using UnityEngine;

using static NativeInterface;

public class AudioOutput : MonoBehaviour
{
    [HideInInspector]
    public bool isRecording = true;

    private void OnAudioFilterRead(float[] data, int channels)
    {
        if (isRecording)
        {
            Int16[] intData = new Int16[data.Length];
            //converting in 2 steps : float[] to Int16[], //then Int16[] to Byte[]

            Byte[] bytesData = new Byte[data.Length * 2];
            //bytesData array is twice the size of
            //dataSource array because a float converted in Int16 is 2 bytes.

            float rescaleFactor = 32767 / 2; //to convert float to Int16

            for (int i = 0; i < data.Length; i++)
            {
                intData[i] = (short)(data[i] * rescaleFactor);
                Byte[] byteArr = new Byte[2];
                byteArr = BitConverter.GetBytes(intData[i]);
                byteArr.CopyTo(bytesData, i * 2);
            }

#if !UNITY_ANDROID
            NativeAPI.SendAudioData(bytesData, bytesData.Length, channels);
#endif
        }
    }
}