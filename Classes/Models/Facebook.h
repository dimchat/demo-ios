//
//  Facebook.h
//  DIMClient
//
//  Created by Albert Moky on 2018/11/11.
//  Copyright © 2018 DIM Group. All rights reserved.
//

#import <DIMClient/DIMClient.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString * const kNotificationName_ContactsUpdated;

typedef NSArray<DIMID *> ContactTable;

@interface Facebook : NSObject <DIMEntityDataSource,
                                DIMUserDataSource,
                                DIMGroupDataSource,
                                DIMBarrackDelegate> {
    
    NSMutableDictionary<DIMAddress *, NSMutableArray<DIMID *> *> *_contactsTable;
}

+ (instancetype)sharedInstance;

- (nullable DIMID *)IDWithAddress:(DIMAddress *)address;

- (void)addStation:(DIMID *)stationID provider:(DIMServiceProvider *)sp;

- (ContactTable *)reloadContactsWithUser:(DIMID *)user;

- (void)setProfile:(DIMProfile *)profile forID:(DIMID *)ID;

@end

NS_ASSUME_NONNULL_END
