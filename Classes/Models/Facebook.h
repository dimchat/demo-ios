//
//  Facebook.h
//  DIMClient
//
//  Created by Albert Moky on 2018/11/11.
//  Copyright © 2018 DIM Group. All rights reserved.
//

#import <DIMClient/DIMClient.h>

NS_ASSUME_NONNULL_BEGIN

extern const NSString *kNotificationName_ContactsUpdated;

typedef NSArray<const DIMID *> ContactTable;

@interface Facebook : NSObject <DIMEntityDataSource,
                                DIMUserDataSource,
                                DIMGroupDataSource,
                                DIMBarrackDelegate> {
    
    NSMutableDictionary<const DIMAddress *, NSMutableArray<const DIMID *> *> *_contactsTable;
}

+ (instancetype)sharedInstance;

- (nullable const DIMID *)IDWithAddress:(const DIMAddress *)address;

- (void)addStation:(const DIMID *)stationID provider:(const DIMServiceProvider *)sp;

- (ContactTable *)reloadContactsWithUser:(const DIMID *)user;

- (void)setProfile:(const DIMProfile *)profile forID:(const DIMID *)ID;

@end

NS_ASSUME_NONNULL_END
