#import <React/RCTEventEmitter.h>

#ifdef RCT_NEW_ARCH_ENABLED
#import "RNTurboSocketSpec.h"

@interface TurboSocket : RCTEventEmitter <NativeTurboSocketSpec>
#else
#import <React/RCTBridgeModule.h>

@interface TurboSocket : RCTEventEmitter <RCTBridgeModule>
#endif

@property (nonatomic, strong) NSMutableDictionary *tcpServerMap;
@property (nonatomic, strong) NSMutableDictionary *tcpHostMap;
@property (nonatomic, strong) NSMutableDictionary *udpServerMap;
@property (nonatomic, strong) NSMutableDictionary *udpHostMap;
@property (nonatomic, assign) BOOL hasListeners;
@property (nonatomic, assign) long counter;

- (void)sendEvent:(NSString *)eventName body:(id)body;

- (long)getClientID;

@end
