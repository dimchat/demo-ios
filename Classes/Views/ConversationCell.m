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
#import "UIColor+Extension.h"
#import "Client.h"

@implementation ConversationCell

-(id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    
    if(self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]){
        
        self.avatarImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, 44.0, 44.0)];
        self.avatarImageView.layer.cornerRadius = 22.0;
        self.avatarImageView.layer.masksToBounds = YES;
        [self.contentView addSubview:self.avatarImageView];
        
        self.nameLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.nameLabel.font = [UIFont systemFontOfSize:16.0];
        [self.contentView addSubview:self.nameLabel];
        
        self.lastMsgLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.lastMsgLabel.font = [UIFont systemFontOfSize:13.0];
        self.lastMsgLabel.textColor = [UIColor colorWithHexString:@"9f9f9f"];
        [self.contentView addSubview:self.lastMsgLabel];
        
        self.lastTimeLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.lastTimeLabel.font = [UIFont systemFontOfSize:12.0];
        self.lastTimeLabel.textColor = [UIColor colorWithHexString:@"9f9f9f"];
        self.lastTimeLabel.textAlignment = NSTextAlignmentRight;
        [self.contentView addSubview:self.lastTimeLabel];
        
        self.separatorInset = UIEdgeInsetsMake(0.0, 70.0, 0.0, 0.0);
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadData) name:kNotificationName_MessageUpdated object:nil];
    }
    
    return self;
}

-(void)dealloc{
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setConversation:(DIMConversation *)conversation {
    if (![_conversation.ID isEqual:conversation.ID]) {
        _conversation = conversation;
        [self loadData];
        [self setNeedsLayout];
    }
}

-(void)onConversationUpdated:(NSNotification *)o{
    
    NSDictionary *info = [o userInfo];
    DIMID *ID = DIMIDWithString([info objectForKey:@"ID"]);
    if ([_conversation.ID isEqual:ID]) {
    
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self loadData];
            [self setNeedsLayout];
        });
    }
}

-(void)loadData{
    
    // avatar
    CGRect frame = _avatarImageView.frame;
    UIImage *image;
    if (MKMNetwork_IsGroup(_conversation.ID.type)) {
        image = [_conversation.profile logoImageWithSize:frame.size];
    } else {
        image = [_conversation.profile avatarImageWithSize:frame.size];
    }
    
    [_avatarImageView setImage:image];
    
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
                last = NSLocalizedString(@"[Image]", @"title");
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

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat x = 13.0;
    CGFloat y = 10.0;
    CGFloat width = 44.0;
    CGFloat height = 44.0;
    
    self.avatarImageView.frame = CGRectMake(x, y, width, height);
    
    width = 70.0;
    y = 13.0;
    x = self.contentView.bounds.size.width - width - 13.0;
    height = 19.0;
    self.lastTimeLabel.frame = CGRectMake(x, y, width, height);
    
    x = self.avatarImageView.frame.origin.x + self.avatarImageView.frame.size.width + 13.0;
    y = 13.0;
    width = self.lastTimeLabel.frame.origin.x - x - 5.0;
    height = 19.0;
    self.nameLabel.frame = CGRectMake(x, y, width, height);
    
    y = y + height + 5.0;
    height = 15.0;
    width = self.bounds.size.width - 13.0 - x;
    self.lastMsgLabel.frame = CGRectMake(x, y, width, height);
}

-(NSString *)dateString:(NSDate *)date{
    
    NSString *timeString = @"";
    NSDate *days_ago = [[[NSDate date] dateBySubtractingDays:7] dateAtStartOfDay];
    
    if([date isYesterday]){
        timeString = NSLocalizedString(@"Yesterday", @"title");
    } else if([date isToday]){
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"HH:mm a"];
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

@end
