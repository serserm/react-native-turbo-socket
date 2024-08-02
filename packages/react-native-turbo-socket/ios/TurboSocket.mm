#import <React/RCTLog.h>
#import "TurboSocket.h"
#import "TcpClient.h"
#import "UdpClient.h"

#define TCP @"tcp"
#define UDP @"udp"

#define SERVER @"server"
#define HOST @"host"

#define SERVER_EVENT @"serverEvent"
#define HOST_EVENT @"hostEvent"

@implementation TurboSocket
RCT_EXPORT_MODULE()

- (instancetype)init {
    self = [super init];
    if (self) {
        _tcpServerMap = [NSMutableDictionary dictionary];
        _tcpHostMap = [NSMutableDictionary dictionary];
        _udpServerMap = [NSMutableDictionary dictionary];
        _udpHostMap = [NSMutableDictionary dictionary];
        _hasListeners = NO;
        _counter = 1001;
    }
    return self;
}

- (NSArray<NSString *> *)supportedEvents {
    return @[SERVER_EVENT, HOST_EVENT];
}

- (void)sendEvent:(NSString *)eventName
            body:(id)body {
    if (_hasListeners) {
        [self sendEventWithName:eventName body:body];
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

- (long)getClientID {
    return _counter++;
}

RCT_EXPORT_METHOD(startServer:(NSString *)host port:(double)port type:(NSString *)type) {
    int intPort = port > 0 && port <= 65535 ? (int)port : 0;
//     if (intPort == 0) {
//         intPort = isSecure ? 443 : 80;
//     }
    NSString *hostName = [@"0.0.0.0" isEqualToString:host] ? nil : host;
    NSString *key = [NSString stringWithFormat:@"%@:%d", host, intPort];
    if ([type isEqualToString:TCP]) {
        NSDictionary *options = @{};
        TcpClient *serverObject = [_tcpServerMap objectForKey:key];
        if (serverObject == nil) {
            serverObject = [[TcpClient alloc] init:SERVER clientID:_counter delegate:self];
            [_tcpServerMap setObject:serverObject forKey:key];
        }
        [serverObject startServer:hostName port:intPort options:options];
    } else {
//         UdpClient *serverObject = [_udpServerMap objectForKey:key];
//         if (serverObject == nil) {
//             serverObject = [[UdpClient alloc] init:SERVER clientID:_counter delegate:self];
//             [_udpServerMap setObject:serverObject forKey:key];
//         }
//         [serverObject startServer:hostName port:intPort];
    }
    _counter++;
}

RCT_EXPORT_METHOD(stopServer:(NSString *)host port:(double)port type:(NSString *)type) {
    int intPort = port > 0 && port <= 65535 ? (int)port : 0;
    NSString *key = [NSString stringWithFormat:@"%@:%d", host, intPort];
    if ([type isEqualToString:TCP]) {
        TcpClient *serverObject = [_tcpServerMap objectForKey:key];
        if (serverObject != nil) {
            [serverObject stopServer];
        }
    } else {
//         UdpClient *serverObject = [_udpServerMap objectForKey:key];
//         if (serverObject != nil) {
//             [serverObject stopServer];
//         }
    }
}

RCT_EXPORT_METHOD(connectHost:(NSString *)host port:(double)port type:(NSString *)type) {
    int intPort = port > 0 && port <= 65535 ? (int)port : 0;
    NSString *key = [NSString stringWithFormat:@"%@:%d", host, intPort];
    if ([type isEqualToString:TCP]) {
        NSDictionary *options = @{};
        TcpClient *hostObject = [_tcpHostMap objectForKey:key];
        if (hostObject == nil) {
            hostObject = [[TcpClient alloc] init:HOST clientID:_counter delegate:self];
            [_tcpHostMap setObject:hostObject forKey:key];
        }
        [hostObject connectHost:host port:intPort options:options];
    } else {
//         UdpClient *hostObject = [_udpHostMap objectForKey:key];
//         if (hostObject == nil) {
//             hostObject = [[UdpClient alloc] init:HOST clientID:_counter delegate:self];
//             [_udpHostMap setObject:hostObject forKey:key];
//         }
//         [hostObject connectHost:host port:intPort];
    }
    _counter++;
}

RCT_EXPORT_METHOD(disconnectHost:(NSString *)host port:(double)port type:(NSString *)type) {
    int intPort = port > 0 && port <= 65535 ? (int)port : 0;
    NSString *key = [NSString stringWithFormat:@"%@:%d", host, intPort];
    if ([type isEqualToString:TCP]) {
        TcpClient *hostObject = [_tcpHostMap objectForKey:key];
        if (hostObject != nil) {
            [hostObject disconnectHost];
        }
    } else {
//         UdpClient *hostObject = [_udpHostMap objectForKey:key];
//         if (hostObject != nil) {
//             [hostObject disconnectHost];
//         }
    }
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
