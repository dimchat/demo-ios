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

NSString *user_title(DIMID *ID) {
    DIMUser *user = DIMUserWithID(ID);
    NSString *name = !user ? ID.name : user.name;
    NSString *number = search_number(ID.number);
    return [NSString stringWithFormat:@"%@ (%@)", name, number];
}

NSString *group_title(DIMID *ID) {
    DIMGroup *group = DIMGroupWithID(ID);
    NSString *name = !group ? ID.name : group.name;
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
