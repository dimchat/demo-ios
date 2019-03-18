//
//  MessageProcessor+GroupCommand.m
//  Sechat
//
//  Created by Albert Moky on 2019/3/10.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "User.h"
#import "Facebook+Register.h"

#import "MessageProcessor+GroupCommand.h"

@implementation MessageProcessor (GroupCommand)

- (BOOL)processGroupCommand:(DIMMessageContent *)content commander:(const DIMID *)sender {
    
    Facebook *facebook = [Facebook sharedInstance];
    
    NSString *command = content.command;
    NSLog(@"command: %@", command);
    
    const DIMID *groupID = [DIMID IDWithID:content.group];
    DIMGroup *group = DIMGroupWithID(groupID);
    NSArray *members = group.members;
    const DIMID *member;
    
    if ([command isEqualToString:@"invite"]) {
        
        NSArray *invites = [content objectForKey:@"members"];
        NSMutableArray *addeds = [[NSMutableArray alloc] initWithCapacity:invites.count];
        
        NSMutableArray *mArray = [members mutableCopy];
        if (!mArray) {
            mArray = [[NSMutableArray alloc] initWithCapacity:invites.count];
        }
        //invites = [invites copy];
        for (NSString *item in invites) {
            member = [DIMID IDWithID:item];
            if ([mArray containsObject:member]) {
                // NOTE:
                //    the owner will receive the invite command sent by itself
                //    after it's already added these members to the group,
                //    just ignore this assert.
                //NSAssert(false, @"adding member error: %@, %@", members, invites);
                //return NO;
            } else {
                [mArray addObject:member];
                [addeds addObject:member];
            }
        }
        if (addeds.count > 0) {
            NSLog(@"invite members: %@ to group: %@", addeds, groupID);
            // save new members list
            if (![facebook saveMembers:mArray withGroupID:groupID]) {
                return NO;
            }
        }
        
        DIMID *owner = [content objectForKey:@"owner"];
        owner = [DIMID IDWithID:owner];
        NSMutableArray *mArr = [[NSMutableArray alloc] initWithCapacity:addeds.count];
        //invites = [invites copy];
        for (DIMID *item in invites) {
            [mArr addObject:readable_name([DIMID IDWithID:item])];
        }
        NSString *str = [mArr componentsJoinedByString:@",\n"];
        NSString *text = [NSString stringWithFormat:@"%@ has invited member(s):\n%@.",
                          readable_name(owner), str];
        NSAssert(![content objectForKey:@"text"], @"text should be empty here: %@", content);
        [content setObject:text forKey:@"text"];
        [content setObject:addeds forKey:@"added"];
        
    } else if ([command isEqualToString:@"expel"]) {
        
        NSArray *expels = [content objectForKey:@"members"];
        NSMutableArray *removeds = [[NSMutableArray alloc] initWithCapacity:expels.count];
        
        NSMutableArray *mArray = [members mutableCopy];
        //expels = [expels copy];
        for (NSString *item in expels) {
            member = [DIMID IDWithID:item];
            if ([mArray containsObject:member]) {
                [mArray removeObject:member];
                [removeds addObject:member];
            } else {
                // NOTE:
                //    the owner will receive the expel command sent by itself
                //    after it's already removed these members from the group,
                //    just ignore this assert.
                //NSAssert(false, @"removing member error: %@, %@", members, expels);
                //return NO;
            }
        }
        if (removeds.count > 0) {
            NSLog(@"expel members: %@ from group: %@", removeds, groupID);
            // save new members list
            if (![facebook saveMembers:mArray withGroupID:groupID]) {
                return NO;
            }
        }
        
        DIMID *owner = [content objectForKey:@"owner"];
        owner = [DIMID IDWithID:owner];
        NSMutableArray *mArr = [[NSMutableArray alloc] initWithCapacity:expels.count];
        //expels = [expels copy];
        for (DIMID *item in expels) {
            [mArr addObject:readable_name([DIMID IDWithID:item])];
        }
        NSString *str = [mArr componentsJoinedByString:@",\n"];
        NSString *text = [NSString stringWithFormat:@"%@ has removed member(s):\n%@.",
                          readable_name(owner), str];
        NSAssert(![content objectForKey:@"text"], @"text should be empty here: %@", content);
        [content setObject:text forKey:@"text"];
        [content setObject:removeds forKey:@"removed"];
        
    } else if ([command isEqualToString:@"quit"]) {
        
        // remove member
        if (![facebook group:group removeMember:sender]) {
            return NO;
        }
        
        NSString *text = [NSString stringWithFormat:@"%@ has quitted group chat.", readable_name(sender)];
        NSAssert(![content objectForKey:@"text"], @"text should be empty here: %@", content);
        [content setObject:text forKey:@"text"];
        
    }
    
    return YES;
}

@end
