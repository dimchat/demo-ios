//
//  AboutViewController.m
//  Sechat
//
//  Created by Albert Moky on 2019/2/2.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import <DIMCore/DIMCore.h>

#import "Client.h"

#import "AboutViewController.h"

@interface AboutViewController ()

@end

@implementation AboutViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    Client *client = [Client sharedInstance];
    self.webView.customUserAgent = client.userAgent;
    
    self.webView.navigationDelegate = self;
    
    NSURL *url = [NSURL URLWithString:client.aboutAPI];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [self.webView loadRequest:request];
}

- (void)webView:(WKWebView *)webView didReceiveServerRedirectForProvisionalNavigation:(WKNavigation *)navigation {
    
    NSString *string = webView.URL.absoluteString;
    if ([string hasPrefix:@"http://"]) {
        string = [@"https://" stringByAppendingString:[string substringFromIndex:7]];
        NSURL *url = [NSURL URLWithString:string];
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        [webView loadRequest:request];
    }
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
