#import <React/RCTViewManager.h>
#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_MODULE(ReactNativePasskeysViewManager, RCTViewManager)

RCT_EXTERN_METHOD(
  callMethod:(NSNumber)view
  (NSString *)method
  data:(NSDictionary *)data
)

@end
