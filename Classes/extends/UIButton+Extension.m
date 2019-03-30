//
//  UIButton+Extension.m
//  Sechat
//
//  Created by Albert Moky on 2019/3/30.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "UIViewController+Extension.h"

#import "UIButton+Extension.h"

@implementation MessageButton

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        _title = nil;
        _message = nil;
        
        [self addTarget:self action:@selector(onClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        _title = nil;
        _message = nil;
        
        [self addTarget:self action:@selector(onClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return self;
}

- (void)onClick:(id)sender {
    NSAssert(_message.length > 0, @"message not set");
    NSAssert(_controller, @"controller not set");
    [_controller showMessage:_message withTitle:_title];
}

@end
