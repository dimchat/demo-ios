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
#import "DIMClientConstants.h"
#import "MessageProcessor.h"

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

@end
