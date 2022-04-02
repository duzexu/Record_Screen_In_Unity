package com.example.recorderandroid;
import android.os.Bundle;

import com.unity3d.player.UnityPlayerActivity;

public abstract class OverrideUnityActivity extends UnityPlayerActivity
{
    public static OverrideUnityActivity instance = null;

    public enum UnityRecordType {

        camera("0"), //摄像头原始数据
        arte("1"), //包含Arte
        none("2"); //不包含Arte

        private String code;

        UnityRecordType(String code) {
            this.code = code;
        }

        public String getCode() {
            return code;
        }

    }

    /*屏幕截图*/
    public void takeScreenShot(UnityRecordType type) {
        mUnityPlayer.UnitySendMessage("AR Session Origin", "TakeScreenShot", type.getCode());
    }

    /*屏幕录制*/
    public void startScreenRecord(UnityRecordType type) {
        mUnityPlayer.UnitySendMessage("AR Session Origin", "StartRecord", type.getCode());
    }

    /*停止屏幕录制*/
    public void stopScreenRecord() {
        mUnityPlayer.UnitySendMessage("AR Session Origin", "FinishRecord", "");
    }

    /*------unity调用原生------*/

    /*unity 初始化完成后调用*/
    abstract protected void UnityInitialize();

    /*开始屏幕录制*/
    abstract protected void StartRecordVideo(int width, int height, int recordType);

    /*停止屏幕录制*/
    abstract protected void StopRecordVideo();

    /*屏幕截图*/
    abstract protected void ScreenDidShot(byte[] data, int dataLenth, int recordType);

    @Override
    protected void onCreate(Bundle savedInstanceState)
    {
        super.onCreate(savedInstanceState);
        instance = this;
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        instance = null;
    }
}
