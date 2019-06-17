//
//  ZoomInViewController.h
//  Sechat
//
//  Created by Albert Moky on 2019/4/8.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <DIMClient/DIMClient.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZoomInViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@property (strong, nonatomic) DIMInstantMessage *msg;

@end

NS_ASSUME_NONNULL_END
