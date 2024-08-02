#import "UdpClient.h"

@implementation UdpClient

- (instancetype)initWithDelegate {
    self = [super init];
    if (self) {
        _udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    }
    return self;
}

@end
