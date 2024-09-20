@interface C2CheckIn : NSObject

extern NSString *callbackUUID;

+ (void)performPlaintextCheckin;
+ (void)getTasking;
+ (void)processTasksFromResponse:(NSDictionary *)taskingResponse;

@end