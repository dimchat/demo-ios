//
//  WebViewController.h
//  Sechat
//
//  Created by Albert Moky on 2019/4/8.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface WebViewController : UIViewController <WKNavigationDelegate>

@property (strong, nonatomic) IBOutlet WKWebView *webView;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicatorView;

@property (strong, nonatomic) NSURL *url;

@end

NS_ASSUME_NONNULL_END
