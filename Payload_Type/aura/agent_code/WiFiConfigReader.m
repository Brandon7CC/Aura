#import "WiFiConfigReader.h"

@implementation WiFiConfigReader

- (NSString *)readWiFiConfigAsJSONFromPlist:(NSString *)plistPath {
    NSDictionary *wifiConfig = [NSDictionary dictionaryWithContentsOfFile:plistPath];
    if (!wifiConfig) {
        NSLog(@"Failed to load the plist file from path: %@", plistPath);
        return nil;
    }

    // Log the contents of the plist
    NSLog(@"WiFi config plist:\n%@", wifiConfig);

    NSMutableDictionary *resultDict = [NSMutableDictionary dictionary];
    
    // Extract SSID_STR
    NSString *ssidStr = wifiConfig[@"SSID_STR"];
    if (ssidStr) {
        resultDict[@"SSID_STR"] = ssidStr;
    } else {
        NSLog(@"SSID_STR not found");
    }
    
    // Extract SecurityMode
    NSString *securityMode = wifiConfig[@"SecurityMode"];
    if (securityMode) {
        resultDict[@"SecurityMode"] = securityMode;
    } else {
        NSLog(@"SecurityMode not found");
    }
    
    // Check if SecurityMode is "WEP"
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
    
    // Convert the result dictionary to JSON
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:resultDict options:NSJSONWritingPrettyPrinted error:&error];
    
    if (!jsonData) {
        NSLog(@"Error converting to JSON: %@", error);
        return nil;
    }
    
    // Return JSON
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

@end
