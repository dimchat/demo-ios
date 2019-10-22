//
//  DIMCommand+Extension.h
//  Sechat
//
//  Created by Albert Moky on 2019/10/22.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import <DIMCore/DIMCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface DIMCommand (Extension)

- (nullable NSString *)messageWithSender:(DIMID *)sender;

@end

NS_ASSUME_NONNULL_END
