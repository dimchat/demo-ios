//
//  Facebook+Relationship.m
//  Sechat
//
//  Created by Albert Moky on 2019/6/4.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "NSNotificationCenter+Extension.h"

#import "Client.h"
#import "Facebook+Register.h"

#import "Facebook+Relationship.h"

@implementation Facebook (Contacts)

// {document_directory}/.mkm/{address}/contacts.plist
- (void)flushContactsWithUser:(DIMUser *)user {
    
    NSMutableArray<DIMID *> *contacts = [_contactsTable objectForKey:user.ID.address];
    if (contacts.count > 0) {
        NSString *dir = document_directory();
        NSString *path = [NSString stringWithFormat:@"%@/.mkm/%@/contacts.plist", dir, user.ID.address];
        [contacts writeToFile:path atomically:YES];
        NSLog(@"contacts updated: %@", contacts);
    } else {
        NSLog(@"no contacts");
    }
}

- (BOOL)user:(DIMUser *)user addContact:(DIMID *)contact {
    NSLog(@"user %@ add contact %@", user, contact);
    NSMutableArray<DIMID *> *contacts = [_contactsTable objectForKey:user.ID.address];
    if (contacts) {
        if ([contacts containsObject:contact]) {
            NSLog(@"contact %@ already exists, user: %@", contact, user.ID);
            return NO;
        } else {
            [contacts addObject:contact];
        }
    } else {
        contacts = [[NSMutableArray alloc] initWithCapacity:1];
        [contacts addObject:contact];
        [_contactsTable setObject:contacts forKey:user.ID.address];
    }
    [self flushContactsWithUser:user];
    [NSNotificationCenter postNotificationName:kNotificationName_ContactsUpdated object:self];
    return YES;
}

- (BOOL)user:(DIMUser *)user removeContact:(DIMID *)contact {
    NSLog(@"user %@ remove contact %@", user, contact);
    NSMutableArray<DIMID *> *contacts = [_contactsTable objectForKey:user.ID.address];
    if (contacts) {
        if ([contacts containsObject:contact]) {
            [contacts removeObject:contact];
        } else {
            NSLog(@"contact %@ not exists, user: %@", contact, user.ID);
            return NO;
        }
    } else {
        NSLog(@"user %@ doesn't has contact yet", user.ID);
        return NO;
    }
    [self flushContactsWithUser:user];
    [NSNotificationCenter postNotificationName:kNotificationName_ContactsUpdated object:self];
    return YES;
}

@end

@implementation Facebook (Members)

- (BOOL)group:(DIMGroup *)group addMember:(DIMID *)member {
    NSArray<DIMID *> *members = group.members;
    if ([members containsObject:member]) {
        NSAssert(false, @"member already exists: %@, %@", member, group);
        return NO;
    }
    NSMutableArray *mArray = [members mutableCopy];
    [mArray addObject:members];
    return [self saveMembers:mArray withGroupID:group.ID];
}

- (BOOL)group:(DIMGroup *)group removeMember:(DIMID *)member {
    NSArray<DIMID *> *members = group.members;
    if (![members containsObject:member]) {
        NSAssert(false, @"member not exists: %@, %@", member, group);
        return NO;
    }
    NSMutableArray *mArray = [[NSMutableArray alloc] initWithCapacity:(members.count - 1)];
    for (DIMID *item in members) {
        if ([item isEqual:member]) {
            continue;
        }
        [mArray addObject:item];
    }
    return [self saveMembers:mArray withGroupID:group.ID];
}


@end
