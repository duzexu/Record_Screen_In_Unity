using System;
using System.Collections;
using System.Collections.Generic;

using Unity.Collections.LowLevel.Unsafe;

using UnityEngine;
using UnityEngine.XR.ARFoundation;
using UnityEngine.XR.ARSubsystems;

using static NativeInterface;

public class ScreenRecorder : MonoBehaviour
{
    /// <summary>
    /// 摄像机
    /// </summary>
    public ARCameraManager cameraManager;

    #region Private Var

    private Texture2D renderTexture;
    private XRCameraImageConversionParams conversionParams;
    private IntPtr intPtr;

    private bool isRecording;
    private float captureTime;

    private bool isScreenShot;

    private int recordType;
    private bool rawImageData; //是否是摄像头原始数据

    #endregion

    public void SwitchFocusMode(string value)
    {
        var arg = bool.Parse(value);
        if (arg)
        {
            cameraManager.focusMode = CameraFocusMode.Auto;
        }
        else
        {
            cameraManager.focusMode = CameraFocusMode.Fixed;
        }
    }

    public void StartRecord(string value)
    {
        if (!isRecording)
        {
            recordType = int.Parse(value);
            rawImageData = recordType == 0;
            isRecording = true;
        }
    }

    public void FinishRecord()
    {
        if (isRecording)
        {
            isRecording = false;
            renderTexture = null;
            NativeAPI.StopRecordVideo();
        }
    }

    public void TakeScreenShot(string value)
    {
        if (!isScreenShot)
        {
            recordType = int.Parse(value);
            rawImageData = recordType == 0;
            isScreenShot = true;
        }
    }

    private void Awake()
    {
        NativeAPI.UnityInitialize();
    }

    private void Update()
    {
        if (isRecording)
        {
            float time = Time.time;
            if (time < captureTime)
            {
                return;
            }
            else
            {
                captureTime = time + 0.033f;
            }

            if (!rawImageData)
            {
                StartCoroutine(ScreenRecordRenderImage());
            }
            else
            {
                ScreenRecordRawImage();
            }
        }
        if (isScreenShot)
        {
            isScreenShot = false;
            if (!rawImageData)
            {
                StartCoroutine(ScreenShotRenderImage());
            }
            else
            {
                ScreenShotRawImage();
            }
        }
    }

    /// <summary>
    /// 获取摄像头原始数据
    /// </summary>
    private unsafe void ScreenShotRawImage()
    {
        if (!cameraManager.TryGetLatestImage(out XRCameraImage image))
        {
            return;
        }

        if (renderTexture == null)
        {
            renderTexture = new Texture2D(image.width, image.height, TextureFormat.BGRA32, false);
            conversionParams = new XRCameraImageConversionParams(image, TextureFormat.BGRA32, CameraImageTransformation.None);
            intPtr = new IntPtr(renderTexture.GetRawTextureData<byte>().GetUnsafePtr());
        }

        var rawTextureData = renderTexture.GetRawTextureData<byte>();
        try
        {
            image.Convert(conversionParams, intPtr, rawTextureData.Length);
        }
        finally
        {
            image.Dispose();
        }

        renderTexture.Apply();

        byte[] rawData = renderTexture.EncodeToPNG();
        NativeAPI.ScreenDidShot(rawData, rawData.Length, recordType);

        renderTexture = null;
    }

    /// <summary>
    /// 获取屏幕渲染结果
    /// </summary>
    /// <returns></returns>
    private IEnumerator ScreenShotRenderImage()
    {
        // Wait for screen rendering to complete
        yield return new WaitForEndOfFrame();

        if (renderTexture == null)
        {
            renderTexture = new Texture2D(Screen.width, Screen.height, TextureFormat.BGRA32, false);
        }

        renderTexture.ReadPixels(new Rect(0, 0, Screen.width, Screen.height), 0, 0);
        renderTexture.Apply();

        byte[] rawData = renderTexture.EncodeToJPG();
        NativeAPI.ScreenDidShot(rawData, rawData.Length, recordType);

        renderTexture = null;
    }

    /// <summary>
    /// 获取摄像头原始数据
    /// </summary>
    private unsafe void ScreenRecordRawImage()
    {
        if (!cameraManager.TryGetLatestImage(out XRCameraImage image))
        {
            return;
        }

        if (isRecording)
        {
            if (renderTexture == null)
            {
                renderTexture = new Texture2D(image.width, image.height, TextureFormat.BGRA32, false);
                conversionParams = new XRCameraImageConversionParams(image, TextureFormat.BGRA32, CameraImageTransformation.None);
                intPtr = new IntPtr(renderTexture.GetRawTextureData<byte>().GetUnsafePtr());
                NativeAPI.StartRecordVideo(image.width, image.height, recordType);
            }

            var rawTextureData = renderTexture.GetRawTextureData<byte>();
            try
            {
                image.Convert(conversionParams, intPtr, rawTextureData.Length);
            }
            finally
            {
                image.Dispose();
            }

            renderTexture.Apply();

            NativeAPI.SendVideoData(renderTexture.GetRawTextureData(), rawTextureData.Length);
        }
    }

    /// <summary>
    /// 获取屏幕渲染结果
    /// </summary>
    /// <returns></returns>
    private IEnumerator ScreenRecordRenderImage()
    {
        // Wait for screen rendering to complete
        yield return new WaitForEndOfFrame();

        if (isRecording)
        {
            if (renderTexture == null)
            {
                renderTexture = new Texture2D(Screen.width, Screen.height, TextureFormat.BGRA32, false);
                NativeAPI.StartRecordVideo(Screen.width, Screen.height, recordType);
            }

            renderTexture.ReadPixels(new Rect(0, 0, Screen.width, Screen.height), 0, 0);
            renderTexture.Apply();

            byte[] rawData = renderTexture.GetRawTextureData();
            NativeAPI.SendVideoData(rawData, rawData.Length);
        }
    }
}