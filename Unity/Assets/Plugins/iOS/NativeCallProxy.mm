#import <Foundation/Foundation.h>
#import "NativeCallProxy.h"

@implementation FrameworkLibAPI

static id<NativeCallsProtocol> api = NULL;
+ (void)registerAPIforNativeCalls:(id<NativeCallsProtocol>)aApi {
    api = aApi;
}

@end

extern "C" {

void UnityInitialize() {
    return [api unityInitialize];
}

void StartRecordVideo(int width, int height, int recordType) {
    [api startRecordVideo:nil width:width height:height recordType: recordType];
}

void SendVideoData(Byte *data,int dataLenth) {
    [api receiveVideoDataFromUnity:data length:dataLenth];
}

void StopRecordVideo() {
    [api stopRecordVideo];
}

void ScreenDidShot(Byte *data, int dataLenth, int recordType) {
    [api screenDidShot:data length:dataLenth recordType: recordType];
}

}

