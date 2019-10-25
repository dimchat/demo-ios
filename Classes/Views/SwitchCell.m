//
//  SwitchCell.m
//  LycheeClient
//
//  Created by LiYonghui on 14-6-16.
//  Copyright (c) 2014年 LiYonghui. All rights reserved.
//

#import "SwitchCell.h"

@interface SwitchCell () {
    UISwitch *_switch;
}

@end

@implementation SwitchCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.accessoryType = UITableViewCellAccessoryNone;
        _switch = [[UISwitch alloc] initWithFrame:CGRectMake(0.0, 0.0, 31.0, 51.0)];
        [_switch addTarget:self action:@selector(switchValueChanged:) forControlEvents:UIControlEventValueChanged];
        [self.contentView addSubview:_switch];
        
        self.textLabel.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGRect rect = _switch.frame;
    rect.origin.x = CGRectGetWidth(self.contentView.bounds) - CGRectGetWidth(rect) - 15;
    rect.origin.y = (CGRectGetHeight(self.contentView.bounds) - CGRectGetHeight(rect)) / 2.0;
    _switch.frame = rect;
}

- (void)switchValueChanged:(id)sender {
    if (_delegate && [_delegate respondsToSelector:@selector(switchCell:didChangeValue:)]) {
        [_delegate switchCell:self didChangeValue:_switch.on];
    }
}


- (void)setSwitchOn:(BOOL)switchOn {
    _switch.on = switchOn;
}

- (BOOL)switchOn {
    return _switch.on;
}

- (void)setSwitchOn:(BOOL)on animated:(BOOL)animated {
    [_switch setOn:on animated:YES];
}

- (void)setSwitchTintColor:(UIColor *)switchTintColor {
    _switch.tintColor = switchTintColor;
}

- (UIColor *)switchTintColor {
    return _switch.tintColor;
}

- (void)setSwitchOnTintColor:(UIColor *)switchOnTintColor {
    _switch.onTintColor = switchOnTintColor;
}

- (UIColor *)switchOnTintColor {
    return _switch.onTintColor;
}

- (void)setSwitchThumbTintColor:(UIColor *)switchThumbTintColor {
    _switch.thumbTintColor = switchThumbTintColor;
}

- (UIColor *)switchThumbTintColor {
    return _switch.thumbTintColor;
}


- (void)setSwitchOnImage:(UIImage *)onImage {
    _switch.onImage = onImage;
}

- (UIImage *)switchOnImage {
    return _switch.onImage;
}

- (void)setSwitchOffImage:(UIImage *)offImage {
    _switch.offImage = offImage;
}

- (UIImage *)switchOffImage {
    return _switch.offImage;
}


@end
