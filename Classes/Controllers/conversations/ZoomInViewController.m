//
//  ZoomInViewController.m
//  Sechat
//
//  Created by Albert Moky on 2019/4/8.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "UIView+Extension.h"
#import "ZoomInViewController.h"

@interface ZoomInViewController ()

@property (nonatomic) CGSize realSize; // image real size
@property (nonatomic) CGSize fitSize;  // zoomed image size aspect fit to the window
@property (strong, nonatomic) UIScrollView *scrollView;
@property (strong, nonatomic) UIImageView *imageView;

@end

@implementation ZoomInViewController

-(void)loadView{
    
    [super loadView];
    
    self.view.backgroundColor = [UIColor colorNamed:@"ViewBackgroundColor"];
    
    self.scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.scrollView];
    
    self.imageView = [[UIImageView alloc] initWithFrame:self.scrollView.bounds];
    self.imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.scrollView addSubview:self.imageView];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    CGSize vSize = self.view.frame.size;
    
    UIImage *image = self.image;
    _realSize = image.size;
    
    if (_realSize.width > 0 && _realSize.height > 0) {
        CGFloat ratio = MIN(vSize.width / _realSize.width, vSize.height / _realSize.height);
        _fitSize = CGSizeMake(_realSize.width * ratio, _realSize.height * ratio);
    } else {
        _fitSize = _realSize;
    }
    
    _scrollView.contentSize = vSize;
    
    _imageView.image = image;
    if (_realSize.width > _fitSize.width) {
        _imageView.bounds = CGRectMake(0, 0, _fitSize.width, _fitSize.height);
    } else {
        _imageView.bounds = CGRectMake(0, 0, _realSize.width, _realSize.height);
    }
    _imageView.center = CGPointMake(vSize.width * 0.5, vSize.height * 0.5);
    
    // click events
    [_scrollView addClickTarget:self action:@selector(onClick:)];
    [_scrollView addDoubleClickTarget:self action:@selector(onDoubleClick:)];
}

- (UIModalPresentationStyle)modalPresentationStyle {
    return UIModalPresentationFullScreen;
}

- (void)onClick:(UITapGestureRecognizer *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)onDoubleClick:(UITapGestureRecognizer *)sender {
    
    CGSize vSize = self.view.frame.size;
    CGSize size;// = _imageView.bounds.size;
    
    if (CGSizeEqualToSize(_imageView.frame.size, _fitSize)) {
        // zoom to real size
        size = _realSize;
    } else {
        // zoom to fit window
        size = _fitSize;
    }
    
    if (vSize.width < size.width) {
        vSize.width = size.width;
    }
    if (vSize.height < size.height) {
        vSize.height = size.height;
    }
    CGPoint center = CGPointMake(vSize.width * 0.5, vSize.height * 0.5);
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.5];
    
    _scrollView.contentSize = vSize;
    
    vSize = self.view.frame.size;
    CGPoint offset = CGPointZero;
    if (size.width > vSize.width) {
        offset.x = (size.width - vSize.width) * 0.5;
    }
    if (size.height > vSize.height) {
        offset.y = (size.height - vSize.height) * 0.5;
    }
    _scrollView.contentOffset = offset;
    
    _imageView.bounds = CGRectMake(0, 0, size.width, size.height);
    _imageView.center = center;
    
    [UIView commitAnimations];
}

@end
