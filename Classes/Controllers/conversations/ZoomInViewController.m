//
//  ZoomInViewController.m
//  Sechat
//
//  Created by Albert Moky on 2019/4/8.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "UIView+Extension.h"

#import "DIMInstantMessage+Extension.h"

#import "ZoomInViewController.h"

@interface ZoomInViewController ()

@end

@implementation ZoomInViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    UIImage *image = _msg.image;
    
    // view size
    CGSize vSize = self.view.bounds.size;
    
    // image size
    CGSize iSize = image.size;
    
    // content size
    CGSize cSize = CGSizeMake(MAX(vSize.width, iSize.width),
                              MAX(vSize.height, iSize.height));
    // center
    CGPoint center = CGPointMake(cSize.width * 0.5, cSize.height * 0.5);
    
    _scrollView.contentSize = cSize;
    
    _imageView.image = image;
    _imageView.bounds = CGRectMake(0, 0, iSize.width, iSize.height);
    _imageView.center = center;
    
    [self.view addClickTarget:self action:@selector(onClick:)];
}

- (void)onClick:(UITapGestureRecognizer *)sender {
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
