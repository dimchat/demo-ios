//
//  MsgCell.m
//  Sechat
//
//  Created by Albert Moky on 2019/2/1.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "TimeCell.h"
#import "NSDate+Extension.h"

@interface TimeCell()

@property (strong, nonatomic) UILabel *timeLabel;

@end

@implementation TimeCell

-(id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    
    if(self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]){
        
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        self.timeLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.timeLabel.font = [UIFont systemFontOfSize:12.0];
        self.timeLabel.textColor = [UIColor lightGrayColor];
        self.timeLabel.backgroundColor = [UIColor clearColor];
        self.timeLabel.textAlignment = NSTextAlignmentCenter;
        [self.contentView addSubview:self.timeLabel];
    }
    
    return self;
}

+ (CGSize)sizeWithMessage:(DIMInstantMessage )iMsg bounds:(CGRect)rect {
    return CGSizeMake(rect.size.width, 20.0);
}

-(void)setTime:(NSTimeInterval)timestamp{
    self.timeLabel.text = [self timeString:timestamp];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat x = 0.0;
    CGFloat y = 7.0;
    CGFloat width = self.contentView.bounds.size.width;
    CGFloat height = 13.0;
    self.timeLabel.frame = CGRectMake(x, y, width, height);
}

-(NSString *)timeString:(NSTimeInterval)timestamp{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSDate *date = [[NSDate alloc] initWithTimeIntervalSince1970:timestamp];
    NSDate *days_ago = [[[NSDate date] dateBySubtractingDays:7] dateAtStartOfDay];
    
    if ([date isToday]) {
        [dateFormatter setDateFormat:NSLocalizedString(@"HH:mm a", @"title")];
    } else if ([date isYesterday]) {
        [dateFormatter setDateFormat:NSLocalizedString(@"HH:mm a", @"title")];
        NSString *string = [dateFormatter stringFromDate:date];
        NSString *format = NSLocalizedString(@"Yesterday %@" ,@"title");
        return [NSString stringWithFormat:format, string];
    } else if ([date isLaterThanDate:days_ago]) {
        [dateFormatter setDateFormat:@"EEEE HH:mm"];
    } else {
        [dateFormatter setDateFormat:@"yyyy/MM/dd HH:mm"];
    }
    return [dateFormatter stringFromDate:date];
}

@end
