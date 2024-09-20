#import <Foundation/Foundation.h>

@interface C2Task : NSObject

@property (nonatomic, strong) NSString *taskID;
@property (nonatomic, strong) NSString *command;
@property (nonatomic, strong) NSString *parameters;
@property (nonatomic, assign) NSTimeInterval timestamp;

- (instancetype)initWithDictionary:(NSDictionary *)dict;

// Execute the task asynchronously
- (void)executeTask;

// Submit the task response
- (void)submitTaskResponseWithOutput:(NSString *)output status:(NSString *)status completed:(BOOL)completed;

@end
