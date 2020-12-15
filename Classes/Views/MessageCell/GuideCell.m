//
//  MsgCell.m
//  Sechat
//
//  Created by Albert Moky on 2019/2/1.
//  Copyright © 2019 DIM Group. All rights reserved.
//
#import "GuideCell.h"
#import "Client.h"

@interface GuideCell()

@property (strong, nonatomic) UILabel *messageLabel;
@property (strong, nonatomic) UIButton *agreementButton;

@end

@implementation GuideCell

-(id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    
    if(self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]){
        
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        self.messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(25.0, 0.0, 320.0, 50.0)];
        self.messageLabel.font = [UIFont systemFontOfSize:14.0];
        self.messageLabel.textColor = [UIColor lightGrayColor];
        self.messageLabel.numberOfLines = 4;
        self.messageLabel.textAlignment = NSTextAlignmentCenter;
        self.messageLabel.text = NSLocalizedString(@"It is forbidden to send contents that violate the existing laws and regulations. If a violator is found, please click the button in the upper right corner and report it.", @"title");
        [self.contentView addSubview:self.messageLabel];
        
        self.agreementButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.agreementButton setTitle:NSLocalizedString(@"user agreements and privacy clauses", @"title") forState:UIControlStateNormal];
        self.agreementButton.titleLabel.font = [UIFont systemFontOfSize:14.0];
        [self.agreementButton addTarget:self action:@selector(didPressAgreementButton:) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:self.agreementButton];
    }
    
    return self;
}

+ (CGSize)sizeWithMessage:(DIMInstantMessage)iMsg bounds:(CGRect)rect {
    return CGSizeMake(rect.size.width, 100.0);
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat x = 10.0;
    CGFloat y = 10.0;
    CGFloat width = self.bounds.size.width - x * 2;
    CGFloat height = 70.0;
    
    self.messageLabel.frame = CGRectMake(x, y, width, height);
    
    y = y + height;
    height = 20.0;
    self.agreementButton.frame = CGRectMake(x, y, width, height);
}

-(void)didPressAgreementButton:(id)sender{
    
    if(self.delegate != nil){
        
        Client *client = [Client sharedInstance];
        NSURL *url = [NSURL URLWithString:client.termsAPI];
        [self.delegate messageCell:self openUrl:url];
    }
}

@end
