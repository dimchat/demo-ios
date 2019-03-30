//
//  User.m
//  DIMClient
//
//  Created by Albert Moky on 2019/2/4.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "Facebook+Register.h"

#import "User.h"

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

NSString *readable_name(const DIMID *ID) {
    DIMProfile *profile = DIMProfileForID(ID);
    NSString *nickname = profile.name;
    NSString *username = ID.name;
    if (nickname) {
        if (username && MKMNetwork_IsCommunicator(ID.type)) {
            return [NSString stringWithFormat:@"%@(%@)", nickname, username];
        }
        return nickname;
    } else if (username) {
        return username;
    } else {
        // BTC Address
        return (NSString *)ID.address;
    }
}

BOOL check_username(const NSString *username) {
    NSString *pattern = @"^[A-Za-z0-9._-]+$";
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", pattern];
    return [pred evaluateWithObject:username];
}

@implementation DIMUser (Config)

+ (nullable instancetype)userWithConfigFile:(NSString *)config {
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:config];
    
    if (!dict) {
        NSLog(@"failed to load: %@", config);
        return nil;
    }
    
    DIMID *ID = [DIMID IDWithID:[dict objectForKey:@"ID"]];
    DIMMeta *meta = [DIMMeta metaWithMeta:[dict objectForKey:@"meta"]];
    [[DIMBarrack sharedInstance] saveMeta:meta forEntityID:ID];
    
    DIMPrivateKey *SK = [DIMPrivateKey keyWithKey:[dict objectForKey:@"privateKey"]];
    [SK saveKeyWithIdentifier:ID.address];
    
    DIMUser *user = DIMUserWithID(ID);
    
    // profile
    DIMProfile *profile = [dict objectForKey:@"profile"];
    if (profile) {
        profile = [DIMProfile profileWithProfile:profile];
        // copy profile from config to local storage
        if (!profile.ID) {
            [profile setObject:ID forKey:@"ID"];
        }
        [[Facebook sharedInstance] saveProfile:profile forEntityID:ID];
    }
    
    return user;
}

@end
