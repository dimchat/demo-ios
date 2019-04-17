//
//  UIScrollView+Extension.m
//  Sechat
//
//  Created by Albert Moky on 2019/4/17.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "UIScrollView+Extension.h"

@implementation UIScrollView (Extension)

- (void)scrollsToBottom {
    [self scrollsToBottom:NO];
}

- (void)scrollsToBottom:(BOOL)animated {
    
    if ([self isKindOfClass:[UITableView class]]) {
        // table view
        UITableView *tableView = (UITableView *)self;
        
        NSInteger section = [tableView numberOfSections] - 1;
        if (section < 0) {
            return ;
        }
        NSInteger row = [tableView numberOfRowsInSection:section] - 1;
        if (row < 0) {
            // TODO: get last section's last row
            return ;
        }
        
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row
                                                    inSection:section];
        [tableView scrollToRowAtIndexPath:indexPath
                         atScrollPosition:UITableViewScrollPositionBottom
                                 animated:animated];
        return ;
    }
    
    // scroll view
    CGRect rect = self.frame;
    CGSize size = self.contentSize;
    
    CGFloat y = size.height - rect.size.height;
    if (y > 0) {
        [self setContentOffset:CGPointMake(0, y)];
    } else {
        [self setContentOffset:CGPointMake(0, 0)];
    }
}

@end
