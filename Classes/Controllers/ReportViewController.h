//
//  ReportViewController.h
//  Sechat
//
//  Created by Albert Moky on 2019/4/5.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

#import <DIMCore/DIMCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface ReportViewController : UIViewController <WKNavigationDelegate>

@property (weak, nonatomic) IBOutlet WKWebView *webView;

@property (strong, nonatomic) const DIMID *ID;

@end

NS_ASSUME_NONNULL_END