//
//  BufferProvider.h
//  Unity-iPhone
//
//  Created by duzexu on 2017/3/29.
//
//

#ifndef BufferProvider_h
#define BufferProvider_h

#include <stdbool.h>
#include <_types/_uint8_t.h>
#include <MacTypes.h>

void initProvider(int width,int height);
void cleanBuffer(void);

void copyBuffer2Cyc(const uint8_t* src_frame);
Byte* consumeBuffer(void);
void recycleBuffer(void);
bool containBuffer(void);

#endif /* BufferProvider_h */
