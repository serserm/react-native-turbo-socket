#import <Foundation/Foundation.h>

extern NSString *const RCTTCPErrorDomain;

enum RCTTCPError {
    RCTTCPNoError = 0,            // Never used
    RCTTCPInvalidInvocationError, // Invalid method invocation
    RCTTCPBadConfigError,         // Invalid configuration
    RCTTCPBadParamError,          // Invalid parameter was passed
    RCTTCPSendTimeoutError,       // A send operation timed out
    RCTTCPSendFailedError,        // A send operation failed
    RCTTCPClosedError,            // The socket was closed
    RCTTCPOtherError,             // Description provided in userInfo
};

typedef enum RCTTCPError RCTTCPError;
