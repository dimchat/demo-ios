//
//  SwitchCell.h
//  LycheeClient
//
//  Created by LiYonghui on 14-6-16.
//  Copyright (c) 2014年 LiYonghui. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SwitchCell;
@protocol SwitchCellDelegate <NSObject>

@optional
- (void)switchCell:(SwitchCell *)cell didChangeValue:(BOOL)on;

@end

@interface SwitchCell : UITableViewCell

@property (nonatomic, assign) id<SwitchCellDelegate> delegate;
@property (nonatomic, assign) BOOL switchOn;
@property (nonatomic, assign) UIColor *switchOnTintColor;
@property (nonatomic, assign) UIColor *switchTintColor;
@property (nonatomic, assign) UIColor *switchThumbTintColor;
@property (nonatomic, retain) UIImage *switchOnImage;
@property (nonatomic, retain) UIImage *switchOffImage;

- (void)setSwitchOn:(BOOL)on animated:(BOOL)animated;

@end
