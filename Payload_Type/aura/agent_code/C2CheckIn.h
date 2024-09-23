@interface C2CheckIn : NSObject

extern NSString *callbackUUID;

+ (void)performPlaintextCheckin;
+ (void)getTasking;
+ (void)processTasksFromResponse:(NSDictionary *)taskingResponse;
+ (void)sendPOSTRequestWithURL:(NSURL *)url
                       payload:(NSDictionary *)payload
                       headers:(NSDictionary *)headers
                    completion:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completion;

@end