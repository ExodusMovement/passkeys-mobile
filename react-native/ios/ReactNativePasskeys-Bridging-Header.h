#import <React/RCTViewManager.h>
#import <React/RCTBridgeModule.h>
#import <React/RCTBridge.h>
#import <React/RCTUIManager.h>

@interface RCT_EXTERN_MODULE (ReactNativePasskeysViewManager, RCTViewManager)

RCT_EXTERN_METHOD(
    callMethod : (NSNumber)view(NSString *) method
        data : (NSDictionary *)data)

@end
