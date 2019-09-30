
#import <UIKit/UIKit.h>

@interface BadgeView : UIView

@property(nonatomic, strong) NSString *badgeValue;
@property(nonatomic, strong) UIFont *font;

- (void)setMaxBounds:(CGRect)bounds;
- (void)setBadgeBackgroundColor:(UIColor *)color;

@end
