#import "SystemInfoHelper.h"
#import <ifaddrs.h>
#import <arpa/inet.h>
#import <sys/types.h>
#import <sys/sysctl.h>
#import <UIKit/UIKit.h>

@implementation SystemInfoHelper

+ (NSString *)getInternalIPAddress {
    NSString *address = @"error";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;

    success = getifaddrs(&interfaces);
    if (success == 0) {
        temp_addr = interfaces;
        while (temp_addr != NULL) {
            if (temp_addr->ifa_addr->sa_family == AF_INET) {
                if ([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"]) {
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                }
            }
            temp_addr = temp_addr->ifa_next;
        }
    }
    freeifaddrs(interfaces);
    return address;
}

+ (NSString *)getExternalIPAddress {
    NSURL *url = [NSURL URLWithString:@"http://ipinfo.io/ip"];
    NSError *error;
    NSString *externalIP = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:&error];
    if (error) {
        NSLog(@"[ERROR] Unable to fetch external IP: %@", error.localizedDescription);
        return @"error";
    }
    return [externalIP stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
}

+ (NSString *)getArchitecture {
    cpu_type_t cpuType;
    cpu_subtype_t cpuSubtype;
    size_t size = sizeof(cpuType);

    // Get the CPU type
    if (sysctlbyname("hw.cputype", &cpuType, &size, NULL, 0) != 0) {
        return @"Error getting CPU type";
    }

    // Get the CPU subtype
    size = sizeof(cpuSubtype);
    if (sysctlbyname("hw.cpusubtype", &cpuSubtype, &size, NULL, 0) != 0) {
        return @"Error getting CPU subtype";
    }

    // Build the architecture string with full CPU type and subtype information
    NSString *architecture = [NSString stringWithFormat:@"%d, %d", cpuType, cpuSubtype];

    return architecture;
}

+ (NSInteger)getPID {
    return [[NSProcessInfo processInfo] processIdentifier];
}

+ (NSString *)getUser {
    return NSUserName();
}

+ (NSString *)getHost {
    return [[NSProcessInfo processInfo] hostName];
}

+ (NSString *)getOS {
    UIDevice *device = [UIDevice currentDevice];
    NSString *systemName = [device systemName]; 
    NSString *systemVersion = [device systemVersion];

    NSString *osDetails = [NSString stringWithFormat:@"%@ %@", systemName, systemVersion];
    return osDetails;
}

+ (NSString *)getDomain {
    return @"local";
}

@end
