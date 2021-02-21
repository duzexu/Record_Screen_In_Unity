
#ifndef TPCircularBuffer_h
#define TPCircularBuffer_h

#include <string.h>
#include <assert.h>
#include <errno.h>
#include <pthread.h>
#include <stdlib.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif
    
typedef struct {
    void             *buffer;
    int32_t           length;
    int32_t           tail;
    int32_t           head;
    volatile int32_t  fillCount;
    pthread_mutex_t   buffer_mutex;
} TPCircularBuffer;


bool TPCircularBufferInit(TPCircularBuffer *buffer, int32_t length){
     assert(length > 0);
     buffer->length = length;
        buffer->buffer = (void*)malloc(length);
        if(buffer->buffer != NULL){
        pthread_mutex_init(&buffer->buffer_mutex,NULL);
            buffer->fillCount = 0;
            buffer->head = buffer->tail = 0;
            return true;
    }
    return false;

}

void TPCircularBufferCleanup(TPCircularBuffer *buffer){
    pthread_mutex_lock(&buffer->buffer_mutex);
    memset(buffer->buffer, 0, buffer->length);
    buffer->fillCount = 0;
    buffer->head = buffer->tail = 0;
    pthread_mutex_unlock(&buffer->buffer_mutex);
}

// Reading (consuming)

void* TPCircularBufferTail(TPCircularBuffer *buffer, int32_t* availableBytes) {
    *availableBytes = buffer->fillCount;
    if ( *availableBytes == 0 ) return NULL;
    return (void*)((char*)buffer->buffer + buffer->tail);
}

void TPCircularBufferConsume(TPCircularBuffer *buffer, int32_t amount) {
    pthread_mutex_lock(&buffer->buffer_mutex);
    buffer->tail = (buffer->tail + amount) % buffer->length;
    buffer->fillCount -= amount;
    assert(buffer->fillCount >= 0);
    pthread_mutex_unlock(&buffer->buffer_mutex);
}


void* TPCircularBufferHead(TPCircularBuffer *buffer, int32_t* availableBytes) {
    *availableBytes = (buffer->length - buffer->fillCount);
    if ( *availableBytes == 0 ) return NULL;
    return (void*)((char*)buffer->buffer + buffer->head);
}

// Writing (producing)   
void TPCircularBufferProduce(TPCircularBuffer *buffer, int32_t amount) {
	pthread_mutex_lock(&buffer->buffer_mutex);
    buffer->head = (buffer->head + amount) % buffer->length;
    buffer->fillCount += amount;
    assert(buffer->fillCount <= buffer->length);
    pthread_mutex_unlock(&buffer->buffer_mutex);
}

/*bool TPCircularBufferProduceBytes(TPCircularBuffer *buffer, const void* src, int32_t len) {
    pthread_mutex_lock(&buffer->buffer_mutex);
    int32_t space;
    void *ptr = TPCircularBufferHead(buffer, &space);
    if ( space < len ){
        pthread_mutex_lock(&buffer->buffer_mutex);
        return false;
    }
    memcpy(ptr, src, len);
    TPCircularBufferProduce(buffer, len);
    pthread_mutex_lock(&buffer->buffer_mutex);
    return true;
}
*/


#ifdef __cplusplus
}
#endif

#endif
