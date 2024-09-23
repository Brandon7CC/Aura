#import <Foundation/Foundation.h>

@interface WiFiConfigReader : NSObject

- (NSString *)readWiFiConfigAsJSONFromPlist:(NSString *)plistPath;

@end
