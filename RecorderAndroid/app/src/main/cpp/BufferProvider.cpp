#include <limits.h>
//
// Created by MAC on 2/17/21.
//

#include <jni.h>
#include <string.h>
#include <stdlib.h>
#include <android/log.h>
#include <sys/time.h>
#include "buffer.h"
#include "native_yuv.h"
#include <android/log.h>

#define LOG_TAG    "NativeYUV"
#define LOGE(format, ...)  __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, format, ##__VA_ARGS__)
#define LOGI(format, ...)  __android_log_print(ANDROID_LOG_INFO,  LOG_TAG, format, ##__VA_ARGS__)

#define CONVERT_NONE 0
#define CONVERT_NV21 1
#define CONVERT_I420 2
#define CONVERT  CONVERT_NV21

extern "C" {

int wi;
int hi;
int video_len;
int audio_len;

TPCircularBuffer *v_tpc = NULL;
void *v_buffer;
bool needVideoRecycle = false;

TPCircularBuffer *a_tpc = NULL;
void *a_buffer;
bool needAudioRecycle = false;

void initVideoBufferProvider(int width, int height) {
    wi = width;
    hi = height;
    if (CONVERT == CONVERT_NONE) {
        video_len = wi * hi * 4;
    } else {
        video_len = wi * hi * 3 / 2;
    }
    if (v_tpc == NULL) {
        v_tpc = new TPCircularBuffer;
        TPCircularBufferInit(v_tpc, video_len * 3);
    }
}

void initAudioBufferProvider(int length) {
    if (a_tpc == NULL) {
        audio_len = length;
        a_tpc = new TPCircularBuffer;
        TPCircularBufferInit(a_tpc, length * 3);
    }
}

void cleanBufferProvider() {
    if (v_tpc != NULL) {
        TPCircularBufferCleanup(v_tpc);
        v_tpc = NULL;
    }
    if (a_tpc != NULL) {
        TPCircularBufferCleanup(a_tpc);
        a_tpc = NULL;
    }
}

void copyVideoBuffer2Cyc(void *scr, int length) {
    int32_t size = 0;
    void *dst = TPCircularBufferHead(v_tpc, &size);
    if (size >= video_len) {
        if (CONVERT == CONVERT_NV21) {
            ARGB2NV21((unsigned char *)scr,(unsigned char *)dst,wi,hi);
        } else if (CONVERT == CONVERT_I420) {
            ARGB2I420((unsigned char *)scr,(unsigned char *)dst,wi,hi);
        } else {
            memcpy(dst, scr, length);
        }
        TPCircularBufferProduce(v_tpc, video_len);
    }
}

void copyAudioBuffer2Cyc(void *scr, int length) {
    if (a_tpc != NULL) {
        int32_t size = 0;
        void *dst = TPCircularBufferHead(a_tpc, &size);
        if (size >= audio_len) {
            memcpy(dst, scr, length);
            TPCircularBufferProduce(a_tpc, audio_len);
        }
    }
}

bool haveVideoBuffer() {
    int32_t availableBytes = 0;
    TPCircularBufferTail(v_tpc, &availableBytes);
    if (availableBytes >= video_len) {
        return true;
    }
    return false;
}

bool haveAudioBuffer() {
    int32_t availableBytes = 0;
    TPCircularBufferTail(a_tpc, &availableBytes);
    if (availableBytes >= audio_len) {
        return true;
    }
    return false;
}

/* c#用IntPtr接收 */
unsigned char *consumeVideoBuffer() {
    if (v_tpc == NULL) {
        needVideoRecycle = false;
        return NULL;
    }
    int32_t availableBytes = 0;
    v_buffer = TPCircularBufferTail(v_tpc, &availableBytes);
    if (availableBytes >= video_len) {
        needVideoRecycle = true;
        return (unsigned char *)v_buffer;
    } else {
        needVideoRecycle = false;
        return NULL;
    }
}

unsigned char *consumeAudioBuffer() {
    if (a_tpc == NULL) {
        needAudioRecycle = false;
        return NULL;
    }
    int32_t availableBytes = 0;
    a_buffer = TPCircularBufferTail(a_tpc, &availableBytes);
    if (availableBytes >= audio_len) {
        needAudioRecycle = true;
        return (unsigned char *)a_buffer;
    } else {
        needAudioRecycle = false;
        return NULL;
    }
}

int recycleVideoBuffer() {
    if (v_tpc == NULL) {
        return -1;
    }
    if (needVideoRecycle) {
        TPCircularBufferConsume(v_tpc, video_len);
    }
    return 0;
}

int recycleAudioBuffer() {
    if (a_tpc == NULL) {
        return -1;
    }
    if (needAudioRecycle) {
        TPCircularBufferConsume(a_tpc, audio_len);
    }
    return 0;
}

}

extern "C" {

JNIEXPORT jboolean JNICALL
Java_com_example_recorderandroid_MainUnityActivity_haveVideoBuffer(
        JNIEnv *env,
        jobject /* this */) {
    return haveVideoBuffer();
}

JNIEXPORT jboolean JNICALL
Java_com_example_recorderandroid_MainUnityActivity_haveAudioBuffer(
        JNIEnv *env,
        jobject /* this */) {
    return haveAudioBuffer();
}

JNIEXPORT jbyteArray JNICALL
Java_com_example_recorderandroid_MainUnityActivity_consumeVideoBuffer(
        JNIEnv *env,
        jobject /* this */) {
    unsigned char *result = consumeVideoBuffer();
    jbyteArray data =env->NewByteArray(video_len);
    //LOGI("####wi%d hi%d len%d",wi,hi,video_len);
    env->SetByteArrayRegion(data,0,video_len, (jbyte*)result);
    return data;
}

JNIEXPORT jbyteArray JNICALL
Java_com_example_recorderandroid_MainUnityActivity_consumeAudioBuffer(
        JNIEnv *env,
        jobject /* this */) {
    unsigned char *result = consumeAudioBuffer();
    jbyteArray data =env->NewByteArray(audio_len);
    //LOGI("####wi%d hi%d len%d",wi,hi,audio_len);
    env->SetByteArrayRegion(data,0,audio_len, (jbyte*)result);
    return data;
}

JNIEXPORT jint JNICALL
Java_com_example_recorderandroid_MainUnityActivity_recycleVideoBuffer(
        JNIEnv *env,
        jobject /* this */) {
    return recycleVideoBuffer();
}

JNIEXPORT jint JNICALL
Java_com_example_recorderandroid_MainUnityActivity_recycleAudioBuffer(
        JNIEnv *env,
        jobject /* this */) {
    return recycleAudioBuffer();
}

JNIEXPORT __unused  void JNICALL
Java_com_example_recorderandroid_AVEncoder_Nv21ToNv12(
        JNIEnv *env,
        jclass ,
        jbyteArray jNv21Data,
        jbyteArray jNv12Data,
        jint jwidth,
        jint jheight) {
    jbyte* jNv21 = env->GetByteArrayElements(jNv21Data, NULL);
    jbyte* jNv12 = env->GetByteArrayElements(jNv12Data, NULL);

    unsigned char* pNv21 = (unsigned char*)jNv21;
    unsigned char* pNv12 = (unsigned char*)jNv12;

    NV21ToNV12(pNv21,pNv12,(int)jwidth, (int)jheight);
    env->ReleaseByteArrayElements(jNv21Data, jNv21, 0);
    env->ReleaseByteArrayElements(jNv12Data, jNv12, 0);
}

JNIEXPORT __unused  void JNICALL
Java_com_example_recorderandroid_AVEncoder_Nv21ToI420(
        JNIEnv *env,
        jclass,
        jbyteArray jNv21Data,
        jbyteArray jI420Data,
        jint jwidth,
        jint jheight) {
    jbyte* jNv21 = env->GetByteArrayElements(jNv21Data, NULL);
    jbyte* jI420 = env->GetByteArrayElements(jI420Data, NULL);

    unsigned char* pNv21 = (unsigned char*)jNv21;
    unsigned char* pI420 = (unsigned char*)jI420;

    Nv21ToI420(pNv21,pI420,(int)jwidth, (int)jheight);
    env->ReleaseByteArrayElements(jNv21Data, jNv21, 0);
    env->ReleaseByteArrayElements(jI420Data, jI420, 0);
}

JNIEXPORT __unused  void JNICALL
Java_com_example_recorderandroid_AVEncoder_Nv21ToYv12(
        JNIEnv *env,
        jclass,
        jbyteArray jNv21Data,
        jbyteArray jYv12Data,
        jint jwidth,
        jint jheight) {
    jbyte* jNv21 = env->GetByteArrayElements(jNv21Data, NULL);
    jbyte* jYv12 = env->GetByteArrayElements(jYv12Data, NULL);

    unsigned char* pNv21 = (unsigned char*)jNv21;
    unsigned char* pYv12 = (unsigned char*)jYv12;

    Nv21ToI420(pNv21,pYv12,(int)jwidth, (int)jheight);
    env->ReleaseByteArrayElements(jNv21Data, jNv21, 0);
    env->ReleaseByteArrayElements(jYv12Data, jYv12, 0);
}

JNIEXPORT void JNICALL Java_com_example_recorderandroid_AVEncoder_Nv21ClockWiseRotate180
        (JNIEnv *env, jclass jcls __unused, jbyteArray jsrcNv21, jint jsrcWidth, jint jsrcHeight, jbyteArray joutData, jintArray joutWidth, jintArray joutHeight)
{
    jbyte* jsrcNv21Byte = env->GetByteArrayElements(jsrcNv21, NULL);
    jbyte* joutDataByte = env->GetByteArrayElements(joutData, NULL);

    jint* joutWidthInt = env->GetIntArrayElements(joutWidth, NULL);
    jint* joutHeightInt = env->GetIntArrayElements(joutHeight, NULL);

    int* poutWidth = (int*)joutWidthInt;
    int* poutHeight = (int*)joutHeightInt;

    unsigned char* pSrcNv21 = (unsigned char*)jsrcNv21Byte;
    unsigned char* pOutData = (unsigned char*)joutDataByte;

    Nv21ClockWiseRotate180(pSrcNv21,(int)jsrcWidth,(int)jsrcHeight,pOutData,poutWidth, poutHeight);

    env->ReleaseIntArrayElements(joutWidth, joutWidthInt, 0);
    env->ReleaseIntArrayElements(joutHeight, joutHeightInt, 0);
    env->ReleaseByteArrayElements(jsrcNv21, jsrcNv21Byte, 0);
    env->ReleaseByteArrayElements(joutData, joutDataByte, 0);
}

JNIEXPORT __unused  void JNICALL
Java_com_example_recorderandroid_AVEncoder_MirrorYuv(
        JNIEnv *env,
        jclass,
        jbyteArray jYuvData,
        jint jWidth,
        jint jHeight) {
    jbyte* jYuvByte = env->GetByteArrayElements(jYuvData, NULL);
    MirrorYuv((unsigned char*)jYuvByte,jWidth,jHeight);
    env->ReleaseByteArrayElements(jYuvData, jYuvByte, 0);
}

}