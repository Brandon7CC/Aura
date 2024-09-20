#import <Foundation/Foundation.h>

@interface SystemInfoHelper : NSObject

+ (NSString *)getInternalIPAddress;
+ (NSString *)getExternalIPAddress;
+ (NSString *)getArchitecture;
+ (NSInteger)getPID;
+ (NSString *)getUser;
+ (NSString *)getHost;
+ (NSString *)getOS;
+ (NSString *)getDomain;

@end
