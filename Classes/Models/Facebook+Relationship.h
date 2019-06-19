//
//  Facebook+Relationship.h
//  Sechat
//
//  Created by Albert Moky on 2019/6/4.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "Facebook.h"

NS_ASSUME_NONNULL_BEGIN

@interface Facebook (Contacts)

- (BOOL)user:(DIMUser *)user addContact:(DIMID *)contact;
- (BOOL)user:(DIMUser *)user removeContact:(DIMID *)contact;

@end

@interface Facebook (Members)

- (BOOL)group:(DIMGroup *)group addMember:(DIMID *)member;
- (BOOL)group:(DIMGroup *)group removeMember:(DIMID *)member;

@end

NS_ASSUME_NONNULL_END
