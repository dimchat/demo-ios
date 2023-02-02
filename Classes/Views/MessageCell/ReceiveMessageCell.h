//
//  MsgCell.h
//  Sechat
//
//  Created by Albert Moky on 2019/2/1.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MessageCell.h"

NS_ASSUME_NONNULL_BEGIN

@interface ReceiveMessageCell : MessageCell

@property(nonatomic, readwrite) BOOL showName;
+ (CGSize)sizeWithMessage:(id<DKDInstantMessage>)iMsg bounds:(CGRect)rect showName:(BOOL)showName;

@end

NS_ASSUME_NONNULL_END
