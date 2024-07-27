#import "TcpClient.h"
#import <React/RCTLog.h>

#define WELCOME_MSG  0
#define ECHO_MSG     1
#define WARNING_MSG  2

#define TIMEOUT_NONE -1

#define SERVER @"server"
#define HOST @"host"

#define SERVER_EVENT @"serverEvent"
#define HOST_EVENT @"hostEvent"

@implementation TcpClient

- (instancetype)init:(NSString *)type
            clientID:(long)clientID
            delegate:(TurboSocket *)delegate {
    self = [super init];
    if (self) {
        _isRunning = NO;
        _type = type;
        _clientID = clientID;
        _pDelegate = delegate;
        _socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
        _clientSockets = [NSMutableDictionary dictionary];
        [_socket setUserData:@(clientID)];
    }
    return self;
}

- (void)startServer:(NSString *)host
            port:(int)port {
    NSError *error = nil;
    if (!_isRunning && [_socket acceptOnInterface:host port:port error:&error]) {
        [_pDelegate sendEvent:SERVER_EVENT
                body:@{
                    @"id": [NSNumber numberWithLong:_clientID],
                    @"host": host,
                    @"port": @(port),
                    @"type": @"onStarted"
                }];
        _isRunning = YES;
    } else {
        NSString *message = _isRunning ? @"Error starting server: is already started"
                : [NSString stringWithFormat:@"Error starting server: %@", error];
        [_pDelegate sendEvent:SERVER_EVENT
                body:@{
                    @"errorCode": @0,
                    @"errorMessage": message,
                    @"id": [NSNumber numberWithLong:_clientID],
                    @"host": host,
                    @"port": @(port),
                    @"type": @"onError"
                }];
    }
}

- (void)stopServer {
    [_socket disconnect];
    @synchronized(_clientSockets) {
        for (NSString *key in _clientSockets) {
            GCDAsyncSocket clientObject = [_clientSockets objectForKey:key];
            [socket disconnect];
        }
    }
    _isRunning = NO;
}

- (void)connectHost:(NSString *)host
            port:(int)port {
    NSError *error = nil;
    if (!_isRunning && [_socket connectToHost:host onPort:port error:&error]) {
        _isRunning = YES;
    } else {
        NSString *message = _isRunning ? @"Error connecting to server: is already connecting"
                : [NSString stringWithFormat:@"Error connecting to server: %@", error];
        [_pDelegate sendEvent:HOST_EVENT
                body:@{
                    @"errorCode": @0,
                    @"errorMessage": message,
                    @"id": [NSNumber numberWithLong:_clientID],
                    @"host": host,
                    @"port": @(port),
                    @"type": @"onError"
                }];
    }
}

- (void)disconnectHost {
}

// GCDAsyncSocketDelegate methods
- (void)socket:(GCDAsyncSocket *)sock
            didAcceptNewSocket:(GCDAsyncSocket *)newSocket {
    NSString *host = [newSocket connectedHost];
    UInt16 port = [newSocket connectedPort];
    long cID = [_pDelegate getClientID];
    NSString *key = [NSString stringWithFormat:@"%ld", cID];
    [newSocket setUserData:@(cID)];
    @synchronized(_clientSockets) {
        [_clientSockets setObject:newSocket forKey:key];
    }
    [_pDelegate sendEvent:SERVER_EVENT
            body:@{
                @"id": [NSNumber numberWithLong:cID],
                @"host": host,
                @"port": @((int)port),
                @"type": @"onConnected"
            }];
//     NSMutableDictionary *settings = [NSMutableDictionary dictionary];
//     if (_tls) {
//         [newSocket startTLS:settings];
//     } else {
//         [_clientDelegate onConnection:inComing toClient:_id];
//     }
    [newSocket readDataWithTimeout:TIMEOUT_NONE tag:cID];
}

- (void)socket:(GCDAsyncSocket *)sock
            didConnectToHost:(NSString *)host
            port:(UInt16)port {
    [_pDelegate sendEvent:HOST_EVENT
            body:@{
                @"id": [NSNumber numberWithLong:_clientID],
                @"host": host,
                @"port": @((int)port),
                @"type": @"onConnected"
            }];
//     if (!_tls) {
//         [_clientDelegate onConnect:self];
//     }
    [sock readDataWithTimeout:-1 tag:_clientID];
}

- (void)socketDidSecure:(GCDAsyncSocket *)sock {
//     if (_serverId != nil) {
//         [_clientDelegate onSecureConnection:self toClient:_serverId];
//     } else if (_connecting) {
//         [_clientDelegate onConnect:self];
//         _connecting = false;
//     }
//     _tls = true;
}

- (void)socketDidCloseReadStream:(GCDAsyncSocket *)sock {
    [sock disconnectAfterReadingAndWriting];
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock
            withError:(NSError *)err {
    NSString *host = [sock connectedHost];
    UInt16 port = [sock connectedPort];
    if ([_type isEqualToString:SERVER]) {
        NSString *key = [NSString stringWithFormat:@"%ld", cID];
        @synchronized(_clientSockets) {
            GCDAsyncSocket *clientObject = [_clientSockets objectForKey:key];
            if (clientObject != nil) {
                [_clientSockets removeObjectForKey:key];
                RCTLogInfo(@"Client disconnected: %@", sock);
            }
        }
    } else {
        RCTLogInfo(@"Client disconnected: %@", sock);
    }
}

- (void)socket:(GCDAsyncSocket *)sock
            didReadData:(NSData *)data
            withTag:(long)tag {
    NSString *message = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    RCTLogInfo(@"Received message: %@", message);
    if ([_type isEqualToString:SERVER]) {
        // TODO
    }
    [sock readDataWithTimeout:TIMEOUT_NONE tag:tag];
}

- (void)socket:(GCDAsyncSocket *)sock
            didWriteDataWithTag:(long)tag {
// TODO
}

@end
