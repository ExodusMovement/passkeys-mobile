#import <React/RCTViewManager.h>
#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_MODULE(PasskeysViewManager, RCTViewManager)

RCT_EXTERN_METHOD(callMethod:(nonnull NSNumber *)reactTag
                  method:(nonnull NSString *)method
                  data:(nonnull NSDictionary *)data
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)

RCT_EXPORT_VIEW_PROPERTY(appId, NSString)
RCT_EXPORT_VIEW_PROPERTY(url, NSString)

@end
