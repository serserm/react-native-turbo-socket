#import "TcpClient.h"
#import <React/RCTLog.h>

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
        _type = type;
        _clientID = clientID;
        _tls = NO;
        _checkValidity = YES;
        _tlsSettings = [NSMutableDictionary dictionary];
        _certPath = nil;
        _host = nil;
        _port = 0;
        _pDelegate = delegate;
        _socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
        _clientSockets = [NSMutableDictionary dictionary];
        [_socket setUserData:@(clientID)];
    }
    return self;
}

- (void)startServer:(NSString *)host
            port:(int)port
            options:(NSDictionary *)options {
    NSError *error = nil;
    BOOL isDisconnected = [_socket isDisconnected];
//     result = [_tcpSocket connectToHost:host
//             onPort:port
//             viaInterface:[interface componentsJoinedByString:@":"]
//             withTimeout:TIMEOUT_NONE
//             error:error];
    if (isDisconnected && [_socket acceptOnInterface:host port:port error:&error]) {
        _host = host;
        _port = port;
        NSDictionary *tlsOptions = options[@"tls"];
        BOOL success = tlsOptions ? [self setSecureContext:tlsOptions] : YES;
        if (!success) {
            [_pDelegate sendEvent:SERVER_EVENT
                    body:@{
                        @"errorCode": @0,
                        @"errorMessage": @"Error to add certificate",
                        @"id": [NSNumber numberWithLong:_clientID],
                        @"host": host,
                        @"port": @(port),
                        @"type": @"onError"
                    }];
        }
        [_pDelegate sendEvent:SERVER_EVENT
                body:@{
                    @"id": [NSNumber numberWithLong:_clientID],
                    @"host": host,
                    @"port": @(port),
                    @"type": @"onStarted"
                }];
    } else {
        NSString *message = !isDisconnected ? @"Error starting server: is already started"
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
            GCDAsyncSocket *clientObject = [_clientSockets objectForKey:key];
            [clientObject disconnect];
        }
    }
}

- (void)connectHost:(NSString *)host
            port:(int)port
            options:(NSDictionary *)options {
    NSError *error = nil;
    BOOL isDisconnected = [_socket isDisconnected];
    if (isDisconnected && [_socket connectToHost:host onPort:port error:&error]) {
//         if (isSecure) {
//             [self startTLS:tlsOptions];
//         }
    } else {
        NSString *message = !isDisconnected ? @"Error connecting to server: is already connecting"
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
    [_socket disconnect];
}

- (BOOL)isConnected {
    return ![_socket isDisconnected];
}

- (void)startTLS:(NSDictionary *)tlsOptions {
    if (_tls) {
        return;
    }
    NSMutableDictionary *settings = [NSMutableDictionary dictionary];
    NSString *certResourcePath = tlsOptions[@"ca"];
    BOOL checkValidity = (tlsOptions[@"rejectUnauthorized"]
                              ? [tlsOptions[@"rejectUnauthorized"] boolValue]
                              : YES);
    if (!checkValidity) {
        // Do not validate
        _checkValidity = NO;
        [settings setObject:[NSNumber numberWithBool:YES]
                     forKey:GCDAsyncSocketManuallyEvaluateTrust];
    } else if (certResourcePath != nil) {
        // Self-signed certificate
        _certPath = certResourcePath;
        [settings setObject:[NSNumber numberWithBool:YES]
                     forKey:GCDAsyncSocketManuallyEvaluateTrust];
    }
    [settings setObject:_host forKey:(NSString *)kCFStreamSSLPeerName];
    [_socket startTLS:settings];
    _tls = YES;
}

- (BOOL)setSecureContext:(NSDictionary *)tlsOptions {
    NSString *keystoreResourcePath = tlsOptions[@"keystore"];
    NSURL *keystoreUrl = [NSURL URLWithString:keystoreResourcePath];
    NSData *pkcs12data = [NSData dataWithContentsOfURL:keystoreUrl];

    if (!pkcs12data) {
        return NO;
    }

    CFDataRef inPCKS12Data = (CFDataRef)CFBridgingRetain(pkcs12data);
    CFStringRef password = CFSTR("");
    const void *keys[] = {kSecImportExportPassphrase};
    const void *values[] = {password};
    CFDictionaryRef options = CFDictionaryCreate(NULL, keys, values, 1, NULL, NULL);
    CFArrayRef items = NULL;
    OSStatus securityError = SecPKCS12Import(inPCKS12Data, options, &items);
    CFRelease(options);
    CFRelease(password);
    CFRelease(inPCKS12Data);

    if (securityError != errSecSuccess || !items) {
        if (items) {
            CFRelease(items);
        }
        return NO;
    }

    CFDictionaryRef identityDict = (CFDictionaryRef)CFArrayGetValueAtIndex(items, 0);
    SecIdentityRef myIdent = (SecIdentityRef)CFDictionaryGetValue(identityDict, kSecImportItemIdentity);

    const void *certArray[1] = {myIdent};
    CFArrayRef myCerts = CFArrayCreate(NULL, certArray, 1, NULL);
    CFRelease(items);

    [_tlsSettings setObject:@YES forKey:(NSString *)kCFStreamSSLIsServer];
    [_tlsSettings setObject:@(2) forKey:GCDAsyncSocketSSLProtocolVersionMin];
    [_tlsSettings setObject:@(8) forKey:GCDAsyncSocketSSLProtocolVersionMax];
    [_tlsSettings setObject:CFBridgingRelease(myCerts) forKey:(NSString *)kCFStreamSSLCertificates];

    _tls = YES;
    return YES;
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
//     if (_tls) {
//         [newSocket startTLS:_tlsSettings];
//     } else {
//         RCTLogInfo(@"onConnected: %@", sock);
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
    [sock readDataWithTimeout:TIMEOUT_NONE tag:_clientID];
}

- (void)socketDidSecure:(GCDAsyncSocket *)sock {
//     _tls = true;
//     RCTLogInfo(@"Received message: %@", message);
}

- (void)socketDidCloseReadStream:(GCDAsyncSocket *)sock {
    [sock disconnectAfterReadingAndWriting];
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock
            withError:(NSError *)err {
    NSString *host = [sock connectedHost];
    UInt16 port = [sock connectedPort];
    NSNumber *cID = [sock userData];
    if (_clientID == [cID longValue]) {
        [_pDelegate sendEvent:([_type isEqualToString:SERVER] ? SERVER_EVENT : HOST_EVENT)
                body:@{
                    @"id": [NSNumber numberWithLong:_clientID],
                    @"host": host,
                    @"port": @((int)port),
                    @"type": @"onDisconnected"
                }];
    } else {
        NSString *key = [NSString stringWithFormat:@"%ld", [cID longValue]];
        @synchronized(_clientSockets) {
            GCDAsyncSocket *clientObject = [_clientSockets objectForKey:key];
            if (clientObject != nil) {
                [_clientSockets removeObjectForKey:key];
                RCTLogInfo(@"Client disconnected: %@", sock);
            }
        }
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

- (void)socket:(GCDAsyncSocket *)sock
      didReceiveTrust:(SecTrustRef)trust
    completionHandler:(void (^)(BOOL shouldTrustPeer))completionHandler {
    // Check if we should check the validity
    if (!_checkValidity) {
        completionHandler(YES);
        return;
    }

    // Server certificate
    SecCertificateRef serverCertificate =
        SecTrustGetCertificateAtIndex(trust, 0);
    CFDataRef serverCertificateData = SecCertificateCopyData(serverCertificate);
    const UInt8 *const serverData = CFDataGetBytePtr(serverCertificateData);
    const CFIndex serverDataSize = CFDataGetLength(serverCertificateData);
    NSData *cert1 = [NSData dataWithBytes:serverData
                                   length:(NSUInteger)serverDataSize];

    // Local certificate
    NSURL *certUrl = [[NSURL alloc] initWithString:_certPath];
    NSString *pem = [[NSString alloc] initWithContentsOfURL:certUrl
                                                   encoding:NSUTF8StringEncoding
                                                      error:nil];

    // Strip PEM header and footers. We don't support multi-certificate PEM.
    NSMutableString *pemMutable =
        [pem stringByTrimmingCharactersInSet:
                 NSCharacterSet.whitespaceAndNewlineCharacterSet]
            .mutableCopy;

    // Strip PEM header and footer
    [pemMutable
        replaceOccurrencesOfString:@"-----BEGIN CERTIFICATE-----"
                        withString:@""
                           options:(NSStringCompareOptions)(NSAnchoredSearch |
                                                            NSLiteralSearch)
                             range:NSMakeRange(0, pemMutable.length)];

    [pemMutable
        replaceOccurrencesOfString:@"-----END CERTIFICATE-----"
                        withString:@""
                           options:(NSStringCompareOptions)(NSAnchoredSearch |
                                                            NSBackwardsSearch |
                                                            NSLiteralSearch)
                             range:NSMakeRange(0, pemMutable.length)];

    NSData *pemData = [[NSData alloc]
        initWithBase64EncodedString:pemMutable
                            options:
                                NSDataBase64DecodingIgnoreUnknownCharacters];
    SecCertificateRef localCertificate =
        SecCertificateCreateWithData(NULL, (CFDataRef)pemData);
    if (!localCertificate) {
        [NSException raise:@"Configuration invalid"
                    format:@"Failed to parse PEM certificate"];
    }

    CFDataRef myCertData = SecCertificateCopyData(localCertificate);
    const UInt8 *const localData = CFDataGetBytePtr(myCertData);
    const CFIndex localDataSize = CFDataGetLength(myCertData);
    NSData *cert2 = [NSData dataWithBytes:localData
                                   length:(NSUInteger)localDataSize];

    if (cert1 == nil || cert2 == nil) {
        RCTLogWarn(@"BAD SSL CERTIFICATE");
        completionHandler(NO);
        return;
    }
    if ([cert1 isEqualToData:cert2]) {
        completionHandler(YES);
    } else {
        completionHandler(NO);
    }
}

@end
