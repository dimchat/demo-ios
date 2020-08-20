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
-(void)messageCell:(MessageCell *)cell showProfile:(DIMID *)profile;
-(void)messageCell:(MessageCell *)cell playAudio:(NSString *)audioPath;

@end


@interface MessageCell : UITableViewCell

@property (nonatomic, assign) id<MessageCellDelegate>delegate;
@property (strong, nonatomic) DIMInstantMessage *message;
@property (strong, nonatomic) UIImageView *avatarImageView;
@property (strong, nonatomic) UILabel *nameLabel;
@property (strong, nonatomic) UIImageView *messageImageView;
@property (strong, nonatomic) UIImageView *picImageView;
@property (strong, nonatomic) UILabel *messageLabel;

@property (nonatomic, strong) UILongPressGestureRecognizer *longPressGuesture;
@property (nonatomic, strong) UIButton *audioButton;

+ (CGSize)sizeWithMessage:(DIMInstantMessage *)message bounds:(CGRect)rect;

@end

NS_ASSUME_NONNULL_END
