//
//  User.m
//  DIMClient
//
//  Created by Albert Moky on 2019/2/4.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "Facebook+Profile.h"

#import "User.h"

NSString *user_title(DIMID ID) {
    MKMUser *user = DIMUserWithID(ID);
    NSString *name = !user ? ID.name : user.name;
    return name;
}

NSString *group_title(DIMID ID) {
    MKMGroup *group = DIMGroupWithID(ID);
    NSString *name = !group ? ID.name : group.name;
    NSUInteger count = group.members.count;
    return [NSString stringWithFormat:@"%@ (%lu)", name, (unsigned long)count];
}

NSString *readable_name(DIMID ID) {
    DIMDocument profile = DIMDocumentForID(ID, @"*");
    NSString *nickname = profile.name;
    NSString *username = ID.name;
    if (nickname) {
        if (username && MKMIDIsUser(ID)) {
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
