//
//  LocalDatabaseManager.h
//  TimeFriend
//
//  Created by 陈均卓 on 2019/5/18.
//  Copyright © 2019 John Chen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DIMStorage.h"

NS_ASSUME_NONNULL_BEGIN

@interface LocalDatabaseManager : NSObject

+(instancetype)sharedInstance;

-(void)createTables;
-(void)insertMessage:(DIMInstantMessage *)msg;

@end

NS_ASSUME_NONNULL_END
