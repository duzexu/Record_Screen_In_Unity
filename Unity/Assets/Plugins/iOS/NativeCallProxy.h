// [!] important set UnityFramework in Target Membership for this file
// [!]           and set Public header visibility

#import <Foundation/Foundation.h>

// NativeCallsProtocol defines protocol with methods you want to be called from managed
@protocol NativeCallsProtocol
@required
//初始化完成
- (void)unityInitialize;
//视频录制
- (void)startRecordVideo:(NSString *_Nullable)name width:(NSInteger)width height:(NSInteger)height recordType:(NSInteger)type;
- (void)receiveVideoDataFromUnity:(Byte *_Nullable)data length:(NSInteger)length;
- (void)stopRecordVideo;
//屏幕截图
- (void)screenDidShot:(Byte *_Nullable)data length:(NSInteger)length recordType:(NSInteger)type;
@end

__attribute__ ((visibility("default")))
@interface FrameworkLibAPI : NSObject
// call it any time after UnityFrameworkLoad to set object implementing NativeCallsProtocol methods
+ (void)registerAPIforNativeCalls:(id<NativeCallsProtocol>_Nullable)aApi;

@end


