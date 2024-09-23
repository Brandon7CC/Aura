#import <Foundation/Foundation.h>
#import <sqlite3.h>

@interface SMSReader : NSObject

- (NSString *)fetchMessagesAsJSONFromDatabase:(NSString *)dbPath;

@end
