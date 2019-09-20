@interface CommandMsgCell : UITableViewCell {
    
    DIMInstantMessage *_msg;
}

@property (strong, nonatomic) DIMInstantMessage *msg;

+ (CGSize)sizeWithMessage:(DIMInstantMessage *)iMsg bounds:(CGRect)rect;

@property (strong, nonatomic) IBOutlet UILabel *timeLabel;
@property (strong, nonatomic) IBOutlet UILabel *messageLabel;

@end
