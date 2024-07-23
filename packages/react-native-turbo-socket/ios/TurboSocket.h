#import <React/RCTEventEmitter.h>

#ifdef RCT_NEW_ARCH_ENABLED
#import "RNTurboSocketSpec.h"

@interface TurboSocket : RCTEventEmitter <NativeTurboSocketSpec>

@property (nonatomic, assign) BOOL hasListeners;

#else
#import <React/RCTBridgeModule.h>

@interface TurboSocket : RCTEventEmitter <RCTBridgeModule>

@property (nonatomic, assign) BOOL hasListeners;

#endif

@end
