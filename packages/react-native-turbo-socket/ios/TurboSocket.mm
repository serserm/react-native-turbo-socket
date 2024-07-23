#import "TurboSocket.h"

@implementation TurboSocket
RCT_EXPORT_MODULE()

- (instancetype)init {
    self = [super init];
    if (self) {
        _hasListeners = NO;
    }
    return self;
}

- (NSArray<NSString *> *)supportedEvents {
    return @[@"sensorsEvent"];
}

- (void)sendEvent:(id)body {
    if (_hasListeners) {
        [self sendEventWithName:@"sensorsEvent" body:body];
    }
}

// Will be called when this module's first listener is added.
- (void)startObserving {
    // Set up any upstream listeners or background tasks as necessary
    _hasListeners = YES;
}

// Will be called when this module's last listener is removed, or on dealloc.
- (void)stopObserving {
    // Remove upstream listeners, stop unnecessary background tasks
    // If we no longer have listeners registered we should also probably also stop the sensor since the sensor events are essentially being dropped.
    _hasListeners = NO;
}

// Don't compile this code when we build for the old architecture.
#ifdef RCT_NEW_ARCH_ENABLED
- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:
    (const facebook::react::ObjCTurboModule::InitParams &)params
{
    return std::make_shared<facebook::react::NativeTurboSocketSpecJSI>(params);
}
#endif

@end
