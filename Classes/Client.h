//
//  Client.h
//  DIM
//
//  Created by Albert Moky on 2019/1/28.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import <DIMCore/DIMCore.h>

#import "Station.h"

NS_ASSUME_NONNULL_BEGIN

@interface Client : NSObject {
    
    DIMUser *_currentUser;
    Station *_currentStation;
}

@property (strong, nonatomic) DIMUser *currentUser;
@property (readonly, strong, nonatomic) NSArray<DIMUser *> *users;

@property (strong, nonatomic) Station *currentStation;
@property (readonly, nonatomic) NSString *userAgent;

+ (instancetype)sharedInstance;

- (void)addUser:(DIMUser *)user;
- (void)removeUser:(DIMUser *)user;

#pragma mark -

- (void)postNotificationName:(NSNotificationName)aName;
- (void)postNotificationName:(NSNotificationName)aName object:(nullable id)anObject;
- (void)postNotificationName:(NSNotificationName)aName object:(nullable id)anObject userInfo:(nullable NSDictionary *)aUserInfo;

@end

#pragma mark -

NSString *document_directory(void);

void make_dirs(NSString *dir);

BOOL file_exists(NSString *path);

NS_ASSUME_NONNULL_END
