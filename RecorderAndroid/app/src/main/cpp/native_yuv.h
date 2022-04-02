//
// Created by xu on 2021/3/9.
//

#include "include/libyuv.h"

#ifdef __cplusplus
extern "C" {
#endif

void I420_TO_RGB24(unsigned char *yuv, unsigned char *rgb24, int width, int height) {

    unsigned char *ybase = yuv;
    unsigned char *ubase = &yuv[width * height];
    unsigned char *vbase = &yuv[width * height * 5 / 4];
    //YUV420P转RGB24
    libyuv::I420ToRGB24(ybase, width, ubase, width / 2, vbase, width / 2,
                        rgb24,
                        width * 3, width, height);

}

void ARGB2NV21(unsigned char *argb, unsigned char *nv21, int width, int height) {

    unsigned char *ybase = nv21;
    unsigned char *uvbase = &nv21[width * height];
    libyuv::ARGBToNV21(argb, width * 4, ybase, width, uvbase, width, width, height);

}

void ARGB2I420(unsigned char *argb, unsigned char *nv21, int width, int height) {
//    unsigned char *tmp_nv21 = (unsigned char *) malloc(width*height*3/2);
//    unsigned char *tmp_ybase = tmp_nv21;
//    unsigned char *tmp_ubase = &tmp_nv21[width * height];
//    unsigned char *tmp_vbase = &tmp_nv21[width * height * 5 / 4];
    unsigned char *ybase = nv21;
    unsigned char *ubase = &nv21[width * height];
    unsigned char *vbase = &nv21[width * height * 5 / 4];
//    libyuv::ARGBToI420(argb,width * 4,tmp_ybase,width,tmp_ubase,(width+1)/2,tmp_vbase,(width+1)/2,width,height);
//    libyuv::I420Rotate(tmp_ybase,width,tmp_ubase,(width+1)/2,tmp_vbase,(width+1)/2,ybase,width,ubase,(width+1)/2,vbase,(width+1)/2,width,height,libyuv::kRotate180);
//    free(tmp_nv21);
    libyuv::ARGBToI420(argb,width * 4,ybase,width,ubase,(width+1)/2,vbase,(width+1)/2,width,height);
}

void NV21ToNV12(unsigned char* pNv21,unsigned char* pNv12,int width,int height)
{
    if(pNv21 == NULL || pNv12 == NULL){
        return;
    }

    int frameSize = width * height;
    if(frameSize <= 0){
        return;
    }

    //拷贝Y分量
    memcpy(pNv12,pNv21,frameSize);

    int i = 0;
    for (i = 0; i < frameSize / 4; i++) {
        pNv12[frameSize + i * 2] = pNv21[frameSize + i * 2 + 1]; //U
        pNv12[frameSize + i * 2 + 1] = pNv21[frameSize + i * 2]; //V
    }
}

//NV21 -> I420
void Nv21ToI420(unsigned char* pNv21,unsigned char* pI420,int width,int height)
{
    if(pNv21 == NULL || pI420 == NULL){
        return;
    }

    int frameSize = width * height;
    if(frameSize <= 0){
        return;
    }

    int i = 0;
    //拷贝Y分量
    memcpy(pI420,pNv21,frameSize);

    for (i = 0; i < frameSize / 2; i += 2) {
        //U分量
        pI420[frameSize + i/2] = pNv21[frameSize + i + 1];
        //V分量
        pI420[frameSize + i/2 + frameSize / 4] = pNv21[frameSize + i];
    }
}

//NV21 -> Yv12
void Nv21ToYv12(unsigned char* pNv21,unsigned char* pYv12,int width,int height)
{
    if(pNv21 == NULL || pYv12 == NULL){
        return;
    }

    int frameSize = width * height;
    if(frameSize <= 0){
        return;
    }

    int i = 0;
    //拷贝Y分量
    memcpy(pYv12,pNv21,frameSize);

    for (i = 0; i < frameSize / 2; i += 2) {
        //V分量
        pYv12[frameSize + i/2] = pNv21[frameSize + i];//pNv21[frameSize + i + 1];
        //U分量
        pYv12[frameSize + i/2 + frameSize / 4] = pNv21[frameSize + i + 1];
    }
}

void Nv21ClockWiseRotate180(unsigned char* pNv21,int srcWidth,int srcHeight, unsigned char* outData,int* outWidth,int* outHeight)
{
    if(pNv21 == NULL || outData == NULL){
        return;
    }

    int i = 0;
    int count = 0;
    for (i = srcWidth * srcHeight - 1; i >= 0; i--) {
        outData[count] = pNv21[i];
        count++;
    }

    i = srcWidth * srcHeight * 3 / 2 - 1;
    for (i = srcWidth * srcHeight * 3 / 2 - 1; i >= srcWidth * srcHeight; i -= 2) {
        outData[count++] = pNv21[i - 1];
        outData[count++] = pNv21[i];
    }

    *outWidth = srcWidth;
    *outHeight = srcHeight;
}

void MirrorYuv(unsigned char *yuv, int w, int h)
{
    int i;
    int index;
    unsigned char temp;
    int a, b;
    //mirror y
    for (i = 0; i < h; i++) {
        a = i * w;
        b = (i + 1) * w - 1;
        while (a < b) {
            temp = yuv[a];
            yuv[a] = yuv[b];
            yuv[b] = temp;
            a++;
            b--;
        }
    }

    // mirror u and v
    index = w * h;
    for (i = 0; i < h / 2; i++) {
        a = i * w;
        b = (i + 1) * w - 2;
        while (a < b) {
            temp = yuv[a + index];
            yuv[a + index] = yuv[b + index];
            yuv[b + index] = temp;

            temp = yuv[a + index + 1];
            yuv[a + index + 1] = yuv[b + index + 1];
            yuv[b + index + 1] = temp;
            a+=2;
            b-=2;
        }
    }
}

#ifdef __cplusplus
}
#endif