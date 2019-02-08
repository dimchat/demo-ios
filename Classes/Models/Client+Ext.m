//
//  Client+Ext.m
//  DIM
//
//  Created by Albert Moky on 2019/1/28.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "Station.h"
#import "Facebook.h"

#import "Client+Ext.h"

@implementation DIMClient (Ext)

- (void)login:(DIMUser *)user {
    self.currentUser = user;
    
    Station *server = (Station *)self.currentStation;
    [server switchUser];
    
    Facebook *facebook = [Facebook sharedInstance];
    [facebook reloadContactsWithUser:user];
    
    NSNotificationCenter *dc = [NSNotificationCenter defaultCenter];
    [dc postNotificationName:@"ContactsUpdated" object:nil];
}

@end

#pragma mark -

NSString *search_number(UInt32 code) {
    NSMutableString *number;
    number = [[NSMutableString alloc] initWithFormat:@"%010u", (unsigned int)code];;
    if ([number length] == 10) {
        [number insertString:@"-" atIndex:6];
        [number insertString:@"-" atIndex:3];
    }
    return number;
}

NSString *account_title(const DIMAccount *account) {
    NSString *name = account.name;
    NSString *number = search_number(account.number);
    return [NSString stringWithFormat:@"%@ (%@)", name, number];
}

NSString *group_title(const DIMGroup *group) {
    NSString *name = group.name;
    NSUInteger count = group.members.count;
    return [NSString stringWithFormat:@"%@ (%lu)", name, (unsigned long)count];
}

#pragma mark -

NSString *document_directory(void) {
    NSArray *paths;
    paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                NSUserDomainMask, YES);
    return paths.firstObject;
}

void make_dirs(NSString *dir) {
    // check base directory exists
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:dir isDirectory:nil]) {
        NSError *error = nil;
        // make sure directory exists
        [fm createDirectoryAtPath:dir withIntermediateDirectories:YES
                       attributes:nil error:&error];
        assert(!error);
    }
}

BOOL file_exists(NSString *path) {
    NSFileManager *fm = [NSFileManager defaultManager];
    return [fm fileExistsAtPath:path];
}
