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

@implementation DIMUser (Config)

+ (instancetype)userWithConfigFile:(NSString *)config {
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
    
    DIMUser *user = MKMUserWithID(ID);
    
    // profile
    DIMProfile *profile = MKMProfileForID(ID);
    if (profile.name) {
        user.name = profile.name;
    } else {
        profile = [dict objectForKey:@"profile"];
        profile = [DIMProfile profileWithProfile:profile];
        if (profile) {
            user.name = profile.name;
            // copy profile from config to local storage
            if (!profile.ID) {
                [profile setObject:ID forKey:@"ID"];
            }
            [[Facebook sharedInstance] saveProfile:profile forID:ID];
        }
    }
    
    return user;
}

@end
