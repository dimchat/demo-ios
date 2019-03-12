//
//  MessageProcessor+GroupCommand.m
//  Sechat
//
//  Created by Albert Moky on 2019/3/10.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "Facebook+Register.h"

#import "MessageProcessor+GroupCommand.h"

@implementation MessageProcessor (GroupCommand)

- (BOOL)processGroupCommand:(DIMMessageContent *)content commander:(const DIMID *)sender {
    
    Facebook *facebook = [Facebook sharedInstance];
    
    NSString *command = content.command;
    NSLog(@"command: %@", command);
    
    const DIMID *groupID = content.group;
    DIMGroup *group = MKMGroupWithID(groupID);
    NSArray *members = group.members;
    const DIMID *member;
    
    if ([command isEqualToString:@"invite"]) {
        
        NSArray *invites = [content objectForKey:@"members"];
        NSMutableArray *addeds = [[NSMutableArray alloc] initWithCapacity:invites.count];
        
        for (NSString *item in invites) {
            member = [DIMID IDWithID:item];
            if ([members containsObject:member]) {
                // NOTE:
                //    the owner will receive the invite command sent by itself
                //    after it's already added these members to the group,
                //    just ignore this assert.
                //NSAssert(false, @"adding member error: %@, %@", members, invites);
                //return NO;
            } else {
                [addeds addObject:member];
            }
        }
        if (addeds.count == 0) {
            NSLog(@"members not changed: %@ invites %@", members, invites);
            return NO;
        }
        
        // save new members list
        if (![facebook saveMembers:invites withGroupID:groupID]) {
            NSLog(@"failed to invite members: %@ to group: %@", invites, groupID);
            return NO;
        }
        
        NSString *owner = [content objectForKey:@"owner"];
        NSString *str = [addeds componentsJoinedByString:@", "];
        NSString *text = [NSString stringWithFormat:@"%@ has added new member(s): %@", owner, str];
        NSAssert(![content objectForKey:@"text"], @"text should be empty here: %@", content);
        [content setObject:text forKey:@"text"];
        [content setObject:addeds forKey:@"added"];
        
    } else if ([command isEqualToString:@"expel"]) {
        
        NSArray *expels = [content objectForKey:@"members"];
        NSMutableArray *removeds = [[NSMutableArray alloc] initWithCapacity:expels.count];
        
        NSMutableArray *mArray = [members mutableCopy];
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
        if (removeds.count == 0) {
            NSLog(@"members not changed: %@ expels %@", members, expels);
            return NO;
        }
        members = mArray;
        
        // save new members list
        if ([facebook saveMembers:members withGroupID:groupID]) {
            NSLog(@"failed to expel members: %@ from group: %@", expels, groupID);
            return NO;
        }
        
        NSString *owner = [content objectForKey:@"owner"];
        NSString *str = [removeds componentsJoinedByString:@", "];
        NSString *text = [NSString stringWithFormat:@"%@ has removed member(s): %@", owner, str];
        NSAssert(![content objectForKey:@"text"], @"text should be empty here: %@", content);
        [content setObject:text forKey:@"text"];
        [content setObject:removeds forKey:@"removed"];
        
    } else if ([command isEqualToString:@"quit"]) {
        
        if ([facebook group:group removeMember:sender]) {
            NSString *text = [NSString stringWithFormat:@"%@ has quitted group chat", sender];
            NSAssert(![content objectForKey:@"text"], @"text should be empty here: %@", content);
            [content setObject:text forKey:@"text"];
        }
        
    }
    
    return YES;
}

@end
