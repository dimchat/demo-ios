

#import "BadgeView.h"

@interface BadgeView(){
    CGFloat _badgeViewWidth;
    CGFloat _badgeViewHeight;
    
    UILabel *_label;
}

@end

@implementation BadgeView

-(id)init{
    _badgeViewWidth = 20.0;
    _badgeViewHeight = 20.0;
    
    CGFloat width = _badgeViewWidth;
    CGFloat height = _badgeViewHeight;
    
    if(self = [super initWithFrame:CGRectMake(0.0, 0.0, width, height)]){
        
        self.layer.cornerRadius = height / 2;
        self.layer.masksToBounds = YES;
        
        _label = [[UILabel alloc] initWithFrame:self.bounds];
        _label.textColor = [UIColor whiteColor];
        _label.backgroundColor = [UIColor clearColor];
        _label.highlightedTextColor = [UIColor whiteColor];
        _label.font = [UIFont systemFontOfSize:13.0];
        _label.textAlignment = NSTextAlignmentCenter;
        [self addSubview:_label];
    }
    
    return self;
}

-(void)setBadgeValue:(NSString *)badgeValue{
    
    _badgeValue = badgeValue;
    _label.text = badgeValue;
    [self setNeedsLayout];
}

-(void)layoutSubviews{
    
    [super layoutSubviews];
    [self layoutUI];
}

-(void)layoutUI{
    
    [_label sizeToFit];
    
    CGFloat x = 0.0;
    CGFloat y = 0.0;
    CGFloat width = _label.bounds.size.width + 12.0;
    
    if(width < _badgeViewWidth){
        width = _badgeViewWidth;
    }
    
    CGFloat height = _badgeViewHeight;
    
    self.bounds = CGRectMake(x, y, width, height);
    _label.frame = self.bounds;
}

-(void)sizeToFit{
    
    [self layoutUI];
}

- (void)setFont:(UIFont *)font {
    _label.font = font;
    
    [self setNeedsLayout];
}

- (void)setBadgeBackgroundColor:(UIColor *)color {
    _label.backgroundColor = color;
}

- (void)setMaxBounds:(CGRect)bounds {
    _badgeViewWidth = bounds.size.width;
    _badgeViewHeight = bounds.size.height;
    
    self.layer.cornerRadius = _badgeViewHeight / 2;
    [self setNeedsLayout];
}

@end
