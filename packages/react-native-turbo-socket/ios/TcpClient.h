#import <Foundation/Foundation.h>
#import "CocoaAsyncSocket/GCDAsyncSocket.h"
#import "TurboSocket.h"

@interface TcpClient : NSObject <GCDAsyncSocketDelegate>

@property (nonatomic, copy) NSString *type;
@property (nonatomic, assign) long clientID;
@property (nonatomic, assign) BOOL tls;
@property (nonatomic, assign) BOOL checkValidity;
@property (nonatomic, strong) NSMutableDictionary *tlsSettings;
@property (nonatomic, copy) NSString *certPath;
@property (nonatomic, copy) NSString *host;
@property (nonatomic, assign) int port;
@property (nonatomic, weak) TurboSocket *pDelegate;
@property (nonatomic, strong) GCDAsyncSocket *socket;
@property (nonatomic, strong) NSMutableDictionary *clientSockets;

- (instancetype)init:(NSString *)type clientID:(long)clientID delegate:(TurboSocket *)delegate;

- (void)startServer:(NSString *)host port:(int)port options:(NSDictionary *)options;

- (void)stopServer;

- (void)connectHost:(NSString *)host port:(int)port options:(NSDictionary *)options;

- (void)disconnectHost;

- (BOOL)isConnected;

@end
