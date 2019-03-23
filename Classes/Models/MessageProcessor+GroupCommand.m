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

- (BOOL)_processResetCommand:(DIMMessageContent *)content commander:(const DIMID *)sender polylogue:(DIMPolylogue *)group {
    
    // 0. check permission
    if (![group isFounder:sender]) {
        NSAssert(false, @"%@ is not the founder of polylogue: %@, cannot reset members.", sender, group);
        return NO;
    }
    
    NSArray *members = group.members;
    
    NSArray *newMembers = [content objectForKey:@"members"];
    if (newMembers.count > 0) {
        // replace item to ID objects
        NSMutableArray *mArray = [[NSMutableArray alloc] initWithCapacity:newMembers.count];
        for (NSString *item in newMembers) {
            [mArray addObject:[DIMID IDWithID:item]];
        }
        newMembers = mArray;
    }
    
    // 1. check removed member(s)
    NSMutableArray *removeds = [[NSMutableArray alloc] initWithCapacity:members.count];
    for (DIMID *item in members) {
        if ([newMembers containsObject:item]) {
            // keep this member
        } else {
            [removeds addObject:item];
        }
    }
    
    // 2. check added member(s)
    NSMutableArray *addeds = [[NSMutableArray alloc] initWithCapacity:newMembers.count];
    for (DIMID *item in newMembers) {
        if ([members containsObject:item]) {
            // member already exist
        } else {
            [addeds addObject:item];
        }
    }
    
    if (addeds.count > 0 || removeds.count > 0) {
        NSLog(@"reset group members: %@, from %@ to %@", group.ID, members, newMembers);
        
        // 3. save new members list
        Facebook *facebook = [Facebook sharedInstance];
        if (![facebook saveMembers:newMembers withGroupID:group.ID]) {
            return NO;
        }
    }
    
    // 4. build message
    NSString *text = [NSString stringWithFormat:@"%@ has updated group members", readable_name(sender)];
    if (removeds.count > 0) {
        NSMutableArray *mArr = [[NSMutableArray alloc] initWithCapacity:removeds.count];
        for (DIMID *item in removeds) {
            [mArr addObject:readable_name(item)];
        }
        NSString *str = [mArr componentsJoinedByString:@",\n"];
        text = [text stringByAppendingFormat:@", removed %@", str];
        [content setObject:removeds forKey:@"removed"];
    }
    if (addeds.count > 0) {
        NSMutableArray *mArr = [[NSMutableArray alloc] initWithCapacity:addeds.count];
        for (DIMID *item in addeds) {
            [mArr addObject:readable_name(item)];
        }
        NSString *str = [mArr componentsJoinedByString:@",\n"];
        text = [text stringByAppendingFormat:@", invited %@", str];
        [content setObject:addeds forKey:@"added"];
    }
    NSAssert(![content objectForKey:@"text"], @"text should be empty here: %@", content);
    [content setObject:text forKey:@"text"];
    
    return YES;
}

- (BOOL)_processInviteCommand:(DIMMessageContent *)content commander:(const DIMID *)sender polylogue:(DIMPolylogue *)group {
    
    // 0. check permission
    if (![group isFounder:sender] && ![group existsMember:sender]) {
        NSAssert(false, @"%@ is not a member of polylogue: %@, cannot invite.", sender, group);
        return NO;
    }
    
    NSArray *members = group.members;
    
    NSMutableArray *newMembers = [[NSMutableArray alloc] initWithArray:members];
    
    NSArray *invites = [content objectForKey:@"members"];
    if (invites.count > 0) {
        // repace item to ID object
        NSMutableArray *mArray = [[NSMutableArray alloc] initWithCapacity:invites.count];
        for (NSString *item in invites) {
            [mArray addObject:[DIMID IDWithID:item]];
        }
        invites = mArray;
    }
    
    // 1. check founder for reset command
    if ([group isFounder:sender]) {
        for (DIMID *item in invites) {
            if ([group isFounder:item]) {
                // invite founder? it means this should be a 'reset' command
                return [self _processResetCommand:content commander:sender polylogue:group];
            }
        }
    }
    
    // 2. check added member(s)
    NSMutableArray *addeds = [[NSMutableArray alloc] initWithCapacity:invites.count];
    for (DIMID *item in invites) {
        if ([newMembers containsObject:item]) {
            // NOTE:
            //    the owner will receive the invite command sent by itself
            //    after it's already added these members to the group,
            //    just ignore this assert.
            //NSAssert(false, @"adding member error: %@, %@", members, invites);
            //return NO;
        } else {
            [newMembers addObject:item];
            [addeds addObject:item];
        }
    }
    
    if (addeds.count > 0) {
        NSLog(@"invite members: %@ to group: %@", addeds, group.ID);
        
        // 3. save new members list
        Facebook *facebook = [Facebook sharedInstance];
        if (![facebook saveMembers:newMembers withGroupID:group.ID]) {
            return NO;
        }
    }
    
    // 4. build message
    NSMutableArray *mArr = [[NSMutableArray alloc] initWithCapacity:invites.count];
    for (DIMID *item in invites) {
        [mArr addObject:readable_name([DIMID IDWithID:item])];
    }
    NSString *str = [mArr componentsJoinedByString:@",\n"];
    NSString *text = [NSString stringWithFormat:@"%@ has invited member(s):\n%@.",
                      readable_name(sender), str];
    NSAssert(![content objectForKey:@"text"], @"text should be empty here: %@", content);
    [content setObject:text forKey:@"text"];
    [content setObject:addeds forKey:@"added"];
    
    return YES;
}

- (BOOL)_processExpelCommand:(DIMMessageContent *)content commander:(const DIMID *)sender polylogue:(DIMPolylogue *)group {
    
    // 1. check permission
    if (![group isFounder:sender]) {
        NSAssert(false, @"%@ is not the founder of polylogue: %@, cannot expel.", sender, group);
        return NO;
    }
    
    NSArray *members = group.members;
    
    NSMutableArray *newMembers = [[NSMutableArray alloc] initWithArray:members];
    
    NSArray *expels = [content objectForKey:@"members"];
    if (expels.count > 0) {
        // repace item to ID object
        NSMutableArray *mArray = [[NSMutableArray alloc] initWithCapacity:expels.count];
        for (NSString *item in expels) {
            [mArray addObject:[DIMID IDWithID:item]];
        }
        expels = mArray;
    }
    
    // 2. check removed member(s)
    NSMutableArray *removeds = [[NSMutableArray alloc] initWithCapacity:expels.count];
    for (DIMID *item in expels) {
        if ([newMembers containsObject:item]) {
            [newMembers removeObject:item];
            [removeds addObject:item];
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
        NSLog(@"expel members: %@ from group: %@", removeds, group.ID);
        
        // 3. save new members list
        Facebook *facebook = [Facebook sharedInstance];
        if (![facebook saveMembers:newMembers withGroupID:group.ID]) {
            return NO;
        }
    }
    
    // 4. build message
    NSMutableArray *mArr = [[NSMutableArray alloc] initWithCapacity:expels.count];
    for (DIMID *item in expels) {
        [mArr addObject:readable_name([DIMID IDWithID:item])];
    }
    NSString *str = [mArr componentsJoinedByString:@",\n"];
    NSString *text = [NSString stringWithFormat:@"%@ has removed member(s):\n%@.",
                      readable_name(sender), str];
    NSAssert(![content objectForKey:@"text"], @"text should be empty here: %@", content);
    [content setObject:text forKey:@"text"];
    [content setObject:removeds forKey:@"removed"];
    
    return YES;
}

- (BOOL)_processQuitCommand:(DIMMessageContent *)content commander:(const DIMID *)sender polylogue:(DIMPolylogue *)group {
    
    // 1. check permission
    if ([group isFounder:sender]) {
        NSAssert(false, @"%@ is the founder of polylogue: %@, cannot quit.", sender, group);
        return NO;
    }
    if (![group existsMember:sender]) {
        NSAssert(false, @"%@ is not a member of polylogue: %@, cannot quit.", sender, group);
        return NO;
    }
    
    // 2. remove member
    Facebook *facebook = [Facebook sharedInstance];
    if (![facebook group:group removeMember:sender]) {
        return NO;
    }
    
    // 3. build message
    NSString *text = [NSString stringWithFormat:@"%@ has quitted group chat.", readable_name(sender)];
    NSAssert(![content objectForKey:@"text"], @"text should be empty here: %@", content);
    [content setObject:text forKey:@"text"];
    
    return YES;
}

- (BOOL)processGroupCommand:(DIMMessageContent *)content commander:(const DIMID *)sender {
    
    NSString *command = content.command;
    NSLog(@"command: %@", command);
    
    const DIMID *groupID = [DIMID IDWithID:content.group];
    if (groupID.type == MKMNetwork_Polylogue) {
        DIMPolylogue *group = (DIMPolylogue *)DIMGroupWithID(groupID);
        
        if ([command isEqualToString:@"invite"]) {
            return [self _processInviteCommand:content commander:sender polylogue:group];
        } else if ([command isEqualToString:@"expel"]) {
            return [self _processExpelCommand:content commander:sender polylogue:group];
        } else if ([command isEqualToString:@"quit"]) {
            return [self _processQuitCommand:content commander:sender polylogue:group];
        } else if ([command isEqualToString:@"reset"]) {
            return [self _processResetCommand:content commander:sender polylogue:group];
        } else {
            NSAssert(false, @"unknown polylogue command: %@", content);
        }
    } else {
        NSAssert(false, @"unsupport group command: %@", content);
    }
    return NO;
}

@end
