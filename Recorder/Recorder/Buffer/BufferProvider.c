//
//  BufferProvider.cpp
//  Unity-iPhone
//
//  Created by duzexu on 2017/3/29.
//
//

#include "BufferProvider.h"
#include "buffer.h"
#include <stdio.h>

TPCircularBuffer *localBuffer = NULL;
int wi;
int hi;

void initProvider(int width,int height) {
    if (localBuffer == NULL) {
        wi = width;
        hi = height;
        localBuffer = malloc(sizeof(TPCircularBuffer));
        TPCircularBufferInit(localBuffer, width*height*4*3);
    }
}

void cleanBuffer() {
    if (localBuffer != NULL) {
        TPCircularBufferCleanup(localBuffer);
    }
}

void copyBuffer2Cyc(const uint8_t* src_frame) {
    int32_t size  = 0;
    void *dst_frame = TPCircularBufferHead(localBuffer, &size);
    if (size >= wi*hi*4) {
        memcpy(dst_frame, src_frame, wi*hi*4);
        TPCircularBufferProduce(localBuffer,wi*hi*4);
    }
}

Byte* consumeBuffer() {
    int32_t availableBytes = 0;
    void* buffer = TPCircularBufferTail(localBuffer,&availableBytes);
    if (availableBytes >= wi*hi*4) {
        return (Byte*)buffer;
    }
    return NULL;
}

void recycleBuffer() {
    TPCircularBufferConsume(localBuffer,wi*hi*4);
}

bool containBuffer() {
    int32_t availableBytes = 0;
    TPCircularBufferTail(localBuffer,&availableBytes);
    if (availableBytes >= wi*hi*4) {
        return true;
    }
    return false;
}
