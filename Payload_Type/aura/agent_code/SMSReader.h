#import <Foundation/Foundation.h>

@interface SMSReader : NSObject

- (NSString *)fetchMessagesAsJSONFromDatabase:(NSString *)dbPath;

@end
