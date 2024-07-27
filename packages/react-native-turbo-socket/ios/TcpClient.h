#import <Foundation/Foundation.h>
#import "CocoaAsyncSocket/GCDAsyncSocket.h"
#import "TurboSocket.h"

@interface TcpClient : NSObject <GCDAsyncSocketDelegate>

@property (nonatomic, assign) BOOL isRunning;
@property (nonatomic, copy) NSString *type;
@property (nonatomic, assign) long clientID;
@property (nonatomic, weak) TurboSocket *pDelegate;
@property (nonatomic, strong) GCDAsyncSocket *socket;
@property (nonatomic, strong) NSMutableDictionary *clientSockets;

- (instancetype)init:(NSString *)type clientID:(long)clientID delegate:(TurboSocket *)delegate;

- (void)startServer:(NSString *)host port:(int)port;

- (void)stopServer;

- (void)connectHost:(NSString *)host port:(int)port;

- (void)disconnectHost;

@end
