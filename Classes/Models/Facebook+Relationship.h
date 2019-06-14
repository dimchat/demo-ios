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

- (BOOL)user:(const DIMUser *)user addContact:(const DIMID *)contact;
- (BOOL)user:(const DIMUser *)user removeContact:(const DIMID *)contact;

@end

@interface Facebook (Members)

- (BOOL)group:(const DIMGroup *)group addMember:(const DIMID *)member;
- (BOOL)group:(const DIMGroup *)group removeMember:(const DIMID *)member;

@end

NS_ASSUME_NONNULL_END
