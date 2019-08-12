//
//  User.m
//  DIMClient
//
//  Created by Albert Moky on 2019/2/4.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "Facebook+Profile.h"

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

NSString *user_title(DIMUser *user) {
    NSString *name = user.name;
    NSString *number = search_number(user.number);
    return [NSString stringWithFormat:@"%@ (%@)", name, number];
}

NSString *group_title(DIMGroup *group) {
    NSString *name = group.name;
    NSUInteger count = group.members.count;
    return [NSString stringWithFormat:@"%@ (%lu)", name, (unsigned long)count];
}

NSString *readable_name(DIMID *ID) {
    DIMProfile *profile = DIMProfileForID(ID);
    NSString *nickname = profile.name;
    NSString *username = ID.name;
    if (nickname) {
        if (username && MKMNetwork_IsUser(ID.type)) {
            return [NSString stringWithFormat:@"%@ (%@)", nickname, username];
        }
        return nickname;
    } else if (username) {
        return username;
    } else {
        // BTC Address
        return (NSString *)ID.address;
    }
}

BOOL check_username(NSString *username) {
    NSString *pattern = @"^[A-Za-z0-9._-]+$";
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", pattern];
    return [pred evaluateWithObject:username];
}

@implementation DIMLocalUser (Config)

+ (nullable instancetype)userWithConfigFile:(NSString *)config {
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:config];
    
    if (!dict) {
        NSLog(@"failed to load: %@", config);
        return nil;
    }
    
    DIMID *ID = DIMIDWithString([dict objectForKey:@"ID"]);
    DIMMeta *meta = MKMMetaFromDictionary([dict objectForKey:@"meta"]);
    
    DIMFacebook *facebook = [DIMFacebook sharedInstance];
    [facebook saveMeta:meta forID:ID];
    
    DIMPrivateKey *SK = MKMPrivateKeyFromDictionary([dict objectForKey:@"privateKey"]);
    [SK saveKeyWithIdentifier:ID.address];
    
    DIMLocalUser *user = DIMUserWithID(ID);
    
    // profile
    DIMProfile *profile = [dict objectForKey:@"profile"];
    if (profile) {
        // copy profile from config to local storage
        if (![profile objectForKey:@"ID"]) {
            [profile setObject:ID forKey:@"ID"];
        }
        profile = MKMProfileFromDictionary(profile);
        [[Facebook sharedInstance] saveProfile:profile];
    }
    
    return user;
}

@end
