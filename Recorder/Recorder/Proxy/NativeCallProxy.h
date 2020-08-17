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
//打开Arte详情
- (void)didClickArte:(NSString *_Nullable)ID;
//打开Arte详情
- (void)openArteDetail:(NSString *_Nullable)ID;
//每当接收到新的（过滤的）位置数据时发出
- (void)onLocationUpdated:(NSString *_Nullable)location;
//当arte预览变化
- (void)onFocusUpdated:(NSString *_Nullable)ID;
@end

__attribute__ ((visibility("default")))
@interface FrameworkLibAPI : NSObject
// call it any time after UnityFrameworkLoad to set object implementing NativeCallsProtocol methods
+ (void)registerAPIforNativeCalls:(id<NativeCallsProtocol>_Nullable)aApi;

@end


