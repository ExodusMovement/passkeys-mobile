#import <React/RCTViewManager.h>
#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_MODULE(PasskeysViewManager, RCTViewManager)

RCT_EXTERN_METHOD(callMethod:(nonnull NSNumber *)reactTag
                  method:(nonnull NSString *)method
                  data:(nonnull NSDictionary *)data
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)

@end
