#import <Foundation/Foundation.h>
#import "CocoaAsyncSocket/GCDAsyncUdpSocket.h"

@interface UdpClient : NSObject <GCDAsyncUdpSocketDelegate>

@property (nonatomic, strong) GCDAsyncUdpSocket *udpSocket;

- (instancetype)initWithDelegate;

@end
