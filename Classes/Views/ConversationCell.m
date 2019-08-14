//
//  ConversationCell.m
//  Sechat
//
//  Created by Albert Moky on 2019/3/5.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "UIView+Extension.h"
#import "DIMProfile+Extension.h"
#import "NSDate+Extension.h"
#import "User.h"

#import "ConversationCell.h"

@implementation ConversationCell

- (void)setConversation:(DIMConversation *)conversation {
    if (![_conversation.ID isEqual:conversation.ID]) {
        _conversation = conversation;
        
        [self setNeedsLayout];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    // avatar
    CGRect frame = _avatarImageView.frame;
    UIImage *image;
    if (MKMNetwork_IsGroup(_conversation.ID.type)) {
        image = [_conversation.profile logoImageWithSize:frame.size];
    } else {
        image = [_conversation.profile avatarImageWithSize:frame.size];
    }
    if (!image) {
        image = [UIImage imageNamed:@"AppIcon"];
    }
    [_avatarImageView setImage:image];
    
    // name
    _nameLabel.text = readable_name(_conversation.ID);
    
    // last message
    NSString *last = nil;
    NSInteger count = [_conversation numberOfMessage];
    DIMInstantMessage *msg;
    DIMContent *content;
    while (--count >= 0) {
        msg = [_conversation messageAtIndex:count];
        content = msg.content;
        switch (content.type) {
            case DKDContentType_Text: {
                last = [(DIMTextContent *)content text];
            }
                break;
            
            case DKDContentType_File: {
                NSString *filename = [(DIMFileContent *)content filename];
                NSString *format = NSLocalizedString(@"[File:%@]", nil);
                last = [NSString stringWithFormat:format, filename];
            }
                break;
                
            case DKDContentType_Image: {
                NSString *filename = [(DIMImageContent *)content filename];
                NSString *format = NSLocalizedString(@"[Image:%@]", nil);
                last = [NSString stringWithFormat:format, filename];
            }
                break;
                
            case DKDContentType_Audio: {
                NSString *filename = [(DIMAudioContent *)content filename];
                NSString *format = NSLocalizedString(@"[Voice:%@]", nil);
                last = [NSString stringWithFormat:format, filename];
            }
                break;
                
            case DKDContentType_Video: {
                NSString *filename = [(DIMVideoContent *)content filename];
                NSString *format = NSLocalizedString(@"[Movie:%@]", nil);
                last = [NSString stringWithFormat:format, filename];
            }
                break;
                
            case DKDContentType_Page: {
                DIMWebpageContent *page = (DIMWebpageContent *)content;
                NSString *text = page.title;
                if (text.length == 0) {
                    text = page.desc;
                    if (text.length == 0) {
                        text = [page.URL absoluteString];
                    }
                }
                NSString *format = NSLocalizedString(@"[Web:%@]", nil);
                last = [NSString stringWithFormat:format, text];
            }
                break;
                
            default:
                break;
        }
        if (last.length > 0) {
            // got it
            break;
        }
    }
    _lastMsgLabel.text = last;
    
    NSTimeInterval timestamp = [[msg objectForKey:@"time"] doubleValue];
    NSDate *date = [[NSDate alloc] initWithTimeIntervalSince1970:timestamp];
    
    self.lastTimeLabel.text = [self dateString:date];
}

-(NSString *)dateString:(NSDate *)date{
    
    NSString *timeString = @"";
    NSDate *days_ago = [[[NSDate date] dateBySubtractingDays:7] dateAtStartOfDay];
    
    if([date isYesterday]){
        timeString = NSLocalizedString(@"Yesterday", @"title");
    } else if([date isToday]){
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"a HH:mm"];
        timeString = [dateFormatter stringFromDate:date];
        
    } else if([date isLaterThanDate:days_ago]){
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"EEEE"];
        timeString = [dateFormatter stringFromDate:date];
    } else {
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy/MM/dd"];
        timeString = [dateFormatter stringFromDate:date];
    }
    
    return timeString;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    
    // avatar
    [_avatarImageView roundedCorner];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
