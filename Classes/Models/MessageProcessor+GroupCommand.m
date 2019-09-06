//
//  MessageProcessor+GroupCommand.m
//  Sechat
//
//  Created by Albert Moky on 2019/3/10.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "NSNotificationCenter+Extension.h"

#import "User.h"
#import "Client.h"
#import "Facebook+Register.h"

#import "MessageProcessor.h"

NSString * const kNotificationName_GroupMembersUpdated = @"GroupMembersUpdated";

@implementation MessageProcessor (GroupCommand)

- (BOOL)processQueryCommand:(DIMGroupCommand *)gCmd
                  commander:(DIMID *)sender
                  polylogue:(DIMPolylogue *)group {
    if (![super processQueryCommand:gCmd commander:sender polylogue:group]) {
        // command error
        return NO;
    }
    
    NSArray *members = group.members;
    
    // pack command and send out
    DIMInviteCommand *invite;
    invite = [[DIMInviteCommand alloc] initWithGroup:group.ID members:members];
    Client *client = [Client sharedInstance];
    [client sendContent:invite to:sender];
    
    return YES;
}

- (BOOL)processGroupCommand:(DIMGroupCommand *)gCmd
                  commander:(DIMID *)sender {
    BOOL OK = [super processGroupCommand:gCmd commander:sender];
    
    if (OK) {
        // notice
        DIMID *groupID = DIMIDWithString(gCmd.group);
        NSString *name = kNotificationName_GroupMembersUpdated;
        NSDictionary *info = @{@"group": groupID};
        [NSNotificationCenter postNotificationName:name
                                            object:self
                                          userInfo:info];
    }
    return OK;
}

@end
