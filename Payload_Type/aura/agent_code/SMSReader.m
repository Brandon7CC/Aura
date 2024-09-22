#import "SMSReader.h"
#import <sqlite3.h>

@implementation SMSReader

- (NSString *)fetchMessagesAsJSONFromDatabase:(NSString *)dbPath {
    sqlite3 *db;
    sqlite3_stmt *stmt;
    NSMutableArray *resultArray = [NSMutableArray array];

    if (sqlite3_open([dbPath UTF8String], &db) != SQLITE_OK) {
        NSLog(@"Failed to open the database.");
        return nil;
    }
    
    const char *sqlQuery = "SELECT message.service, message.is_from_me, message.destination_caller_id, message.text, chat.chat_identifier, chat.guid AS chat_guid FROM message JOIN chat_handle_join ON message.handle_id = chat_handle_join.handle_id JOIN chat ON chat_handle_join.chat_id = chat.ROWID WHERE message.ck_record_id IS NOT NULL;";
    
    if (sqlite3_prepare_v2(db, sqlQuery, -1, &stmt, NULL) != SQLITE_OK) {
        NSLog(@"Failed to prepare the statement.");
        sqlite3_close(db);
        return nil;
    }
    
    while (sqlite3_step(stmt) == SQLITE_ROW) {
        NSMutableDictionary *messageDict = [NSMutableDictionary dictionary];
        
        const char *service = (const char *)sqlite3_column_text(stmt, 0);
        int isFromMe = sqlite3_column_int(stmt, 1);
        const char *destinationCallerID = (const char *)sqlite3_column_text(stmt, 2);
        const char *text = (const char *)sqlite3_column_text(stmt, 3);
        const char *chatIdentifier = (const char *)sqlite3_column_text(stmt, 4);
        const char *chatGUID = (const char *)sqlite3_column_text(stmt, 5);
        
        if (service) {
            messageDict[@"service"] = [NSString stringWithUTF8String:service];
        }
        messageDict[@"is_from_me"] = @(isFromMe);
        if (destinationCallerID) {
            messageDict[@"destination_caller_id"] = [NSString stringWithUTF8String:destinationCallerID];
        }
        if (text) {
            messageDict[@"text"] = [NSString stringWithUTF8String:text];
        }
        if (chatIdentifier) {
            messageDict[@"chat_identifier"] = [NSString stringWithUTF8String:chatIdentifier];
        }
        if (chatGUID) {
            messageDict[@"chat_guid"] = [NSString stringWithUTF8String:chatGUID];
        }
        
        [resultArray addObject:messageDict];
    }
    
    sqlite3_finalize(stmt);
    sqlite3_close(db);
    
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:resultArray options:NSJSONWritingPrettyPrinted error:&error];
    
    if (!jsonData) {
        NSLog(@"Failed to convert result to JSON: %@", error);
        return nil;
    }
    
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

@end
