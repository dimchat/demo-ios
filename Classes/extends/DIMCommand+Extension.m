//
//  DIMCommand+Extension.m
//  Sechat
//
//  Created by Albert Moky on 2019/10/22.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import <DIMClient/DIMClient.h>
#import "DIMCommand+Extension.h"

@implementation DIMCommand (Extension)

- (nullable NSString *)messageWithSender:(DIMID *)sender {
    // build text by subclass
    return [self objectForKey:@"text"];
}

@end

#pragma mark - Group Commands

static inline NSString *readable_name(DIMID *ID) {
    DIMProfile *profile = DIMProfileForID(ID);
    NSString *nickname = profile.name;
    NSString *username = ID.name;
    if (nickname) {
        if (username && [ID isUser]) {
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

static inline NSArray<DIMID *> *id_list(NSArray<NSString *> *list) {
    DIMFacebook *facebook = [DIMFacebook sharedInstance];
    NSMutableArray *mArr = [[NSMutableArray alloc] initWithCapacity:[list count]];
    for (NSString *item in list) {
        [mArr addObject:[facebook IDWithString:item]];
    }
    return mArr;
}

#pragma mark Group Command: Invite

@implementation DIMInviteCommand (Text)

- (nullable NSString *)messageWithSender:(DIMID *)sender {
    NSString *text = [super messageWithSender:sender];
    if ([text length] > 0) {
        return text;
    }
    // get 'added' list
    NSArray<DIMID *> *addeds = id_list([self objectForKey:@"added"]);
    // build message
    NSMutableArray *mArr = [[NSMutableArray alloc] initWithCapacity:addeds.count];
    for (DIMID *item in addeds) {
        [mArr addObject:readable_name(DIMIDWithString(item))];
    }
    NSString *str = [mArr componentsJoinedByString:@", "];
    NSString *format = NSLocalizedString(@"%@ has invited member(s): %@.", nil);
    text = [NSString stringWithFormat:format, readable_name(sender), str];
    [self setObject:text forKey:@"text"];
    return text;
}

@end

#pragma mark Group Command: Expel

@implementation DIMExpelCommand (Text)

- (nullable NSString *)messageWithSender:(DIMID *)sender {
    NSString *text = [super messageWithSender:sender];
    if ([text length] > 0) {
        return text;
    }
    // get 'removed' list
    NSArray<DIMID *> *removeds = id_list([self objectForKey:@"removed"]);
    NSMutableArray *mArr = [[NSMutableArray alloc] initWithCapacity:removeds.count];
    for (DIMID *item in removeds) {
        [mArr addObject:readable_name(DIMIDWithString(item))];
    }
    NSString *str = [mArr componentsJoinedByString:@", "];
    NSString *format = NSLocalizedString(@"%@ has removed member(s): %@.", nil);
    text = [NSString stringWithFormat:format, readable_name(sender), str];
    [self setObject:text forKey:@"text"];
    return text;
}

@end

#pragma mark Group Command: Quit

@implementation DIMQuitCommand (Text)

- (nullable NSString *)messageWithSender:(DIMID *)sender {
    NSString *text = [super messageWithSender:sender];
    if ([text length] > 0) {
        return text;
    }
    NSString *format = NSLocalizedString(@"%@ has quitted group chat.", nil);
    text = [NSString stringWithFormat:format, readable_name(sender)];
    [self setObject:text forKey:@"text"];
    return text;
}

@end

#pragma mark Group Command: Query

@implementation DIMQueryGroupCommand (Text)

- (nullable NSString *)messageWithSender:(DIMID *)sender {
    NSString *text = [super messageWithSender:sender];
    if ([text length] > 0) {
        return text;
    }
    NSString *format = NSLocalizedString(@"%@ was querying group info, responding...", nil);
    text = [NSString stringWithFormat:format, readable_name(sender)];
    [self setObject:text forKey:@"text"];
    return text;
}

@end

#pragma mark Group Command: Reset

@implementation DIMResetGroupCommand (Text)

- (nullable NSString *)messageWithSender:(DIMID *)sender {
    NSString *text = [super messageWithSender:sender];
    if ([text length] > 0) {
        return text;
    }
    NSString *format = NSLocalizedString(@"%@ has updated group members", nil);
    text = [NSString stringWithFormat:format, readable_name(sender)];
    
    // get 'added' list
    NSArray<DIMID *> *addeds = id_list([self objectForKey:@"added"]);
    if (addeds.count > 0) {
        NSMutableArray *mArr = [[NSMutableArray alloc] initWithCapacity:addeds.count];
        for (DIMID *item in addeds) {
            [mArr addObject:readable_name(item)];
        }
        NSString *str = [mArr componentsJoinedByString:@", "];
        text = [text stringByAppendingFormat:@"; %@ %@", NSLocalizedString(@"invited", nil), str];
    }
    
    // get 'removed' list
    NSArray<DIMID *> *removeds = id_list([self objectForKey:@"removed"]);
    if (removeds.count > 0) {
        NSMutableArray *mArr = [[NSMutableArray alloc] initWithCapacity:removeds.count];
        for (DIMID *item in removeds) {
            [mArr addObject:readable_name(item)];
        }
        NSString *str = [mArr componentsJoinedByString:@", "];
        text = [text stringByAppendingFormat:@"; %@ %@", NSLocalizedString(@"removed", nil), str];
    }
    
    [self setObject:text forKey:@"text"];
    return text;
}

@end
