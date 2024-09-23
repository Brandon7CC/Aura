#import "WiFiConfigReader.h"

@implementation WiFiConfigReader

- (NSString *)readWiFiConfigAsJSONFromPlist:(NSString *)plistPath {
    NSDictionary *wifiConfig = [NSDictionary dictionaryWithContentsOfFile:plistPath];
    if (!wifiConfig) {
        NSLog(@"Failed to load the WiFi config plist file from path: %@", plistPath);
        return nil;
    }

    /// DEBUGGING -- log the contents of the WiFi config
    NSLog(@"WiFi config plist:\n%@", wifiConfig);

    // High level steps:
    // - Extract SSID_STR
    // - Extract SecurityMode
    // - Extract EAPClientConfiguration and UserName from EnterpriseProfile
    NSMutableDictionary *resultDict = [NSMutableDictionary dictionary];
    NSString *ssidStr = wifiConfig[@"SSID_STR"];
    if (ssidStr) {
        resultDict[@"SSID_STR"] = ssidStr;
    } else {
        NSLog(@"SSID_STR not found");
    }
    
   
    NSString *securityMode = wifiConfig[@"SecurityMode"];
    if (securityMode) {
        resultDict[@"SecurityMode"] = securityMode;
    } else {
        NSLog(@"SecurityMode not found");
    }
    
    // Is this WEP protected?
    if ([securityMode isEqualToString:@"WEP"]) {
        NSLog(@"Security Mode is WEP");
    }
    
    // Extract EAPClientConfiguration and UserName from EnterpriseProfile
    NSDictionary *enterpriseProfile = wifiConfig[@"EnterpriseProfile"];
    if (enterpriseProfile) {
        NSDictionary *eapClientConfig = enterpriseProfile[@"EAPClientConfiguration"];
        if (eapClientConfig) {
            resultDict[@"EAPClientConfiguration"] = eapClientConfig;
        } else {
            NSLog(@"EAPClientConfiguration not found");
        }
        
        NSString *userName = eapClientConfig[@"UserName"];
        if (userName) {
            resultDict[@"UserName"] = userName;
        } else {
            NSLog(@"UserName not found");
        }
    } else {
        NSLog(@"EnterpriseProfile not found");
    }

    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:resultDict options:NSJSONWritingPrettyPrinted error:&error];
    if (!jsonData) {
        NSLog(@"Error converting to JSON: %@", error);
        return nil;
    }
    
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

@end
