//
//  ChatVoiceView.m
//  Sechat
//
//  Created by 陈均卓 on 2020/8/14.
//  Copyright © 2020 DIM Group. All rights reserved.
//

#import "ChatVoiceView.h"
#import "UIColor+Extension.h"

@interface ChatVoiceView()

@property(nonatomic, strong) UIImageView *micImageView;
@property(nonatomic, strong) UILabel *messageLabel;

@end


@implementation ChatVoiceView

-(id)initWithFrame:(CGRect)frame{
    
    if(self = [super initWithFrame:frame]){
        
        self.micImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"chatVoiceTips"]];
        self.messageLabel = [[UILabel alloc] init];
        self.messageLabel.font = [UIFont systemFontOfSize:13.0];
        self.messageLabel.textColor = [UIColor colorWithHexString:@"E6E6E6"];
        self.messageLabel.textAlignment = NSTextAlignmentCenter;
        self.messageLabel.text = NSLocalizedString(@"Release to send voice", @"title");
        
        [self addSubview:self.micImageView];
        [self addSubview:self.messageLabel];
    }
    
    return self;
}

-(void)layoutSubviews{
    
    [super layoutSubviews];
    
    CGFloat x = (self.frame.size.width - self.micImageView.frame.size.width) / 2.0;
    CGFloat y = 40.0;
    CGFloat width = self.micImageView.frame.size.width;
    CGFloat height = self.micImageView.frame.size.height;
    self.micImageView.frame = CGRectMake(x, y, width, height);
    
    width = self.frame.size.width;
    height = 16.0;
    x = 0.0;
    y = self.frame.size.height - height - 10.0;
    
    self.messageLabel.frame = CGRectMake(x, y, width, height);
}

@end
