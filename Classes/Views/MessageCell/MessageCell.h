//
//  MessageCell.h
//  Sechat
//
//  Created by John Chen on 2019/9/20.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <DIMClient/DIMClient.h>

NS_ASSUME_NONNULL_BEGIN

@class MessageCell;

@protocol MessageCellDelegate <NSObject>

-(void)messageCell:(MessageCell *)cell showImage:(UIImage *)image;
-(void)messageCell:(MessageCell *)cell openUrl:(NSURL *)url;

@end


@interface MessageCell : UITableViewCell

@property (nonatomic, assign) id<MessageCellDelegate>delegate;

+ (CGSize)sizeWithMessage:(DIMInstantMessage *)iMsg bounds:(CGRect)rect;

@end

NS_ASSUME_NONNULL_END
