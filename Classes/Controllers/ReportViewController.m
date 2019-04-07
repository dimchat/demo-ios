//
//  ReportViewController.m
//  Sechat
//
//  Created by Albert Moky on 2019/4/5.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import <DIMCore/DIMCore.h>

#import "Client.h"

#import "ReportViewController.h"

@interface ReportViewController ()

@end

@implementation ReportViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    Client *client = [Client sharedInstance];
    DIMUser *user = client.currentUser;
    
    NSString *sender = [[NSString alloc] initWithFormat:@"%@", user.ID];
    NSString *identifier = [[NSString alloc] initWithFormat:@"%@", _ID];
    NSString *type = @"individual";
    if (MKMNetwork_IsGroup(_ID.type)) {
        type = @"group";
    }
    NSString *api = client.reportAPI;
    api = [api stringByReplacingOccurrencesOfString:@"{sender}" withString:sender];
    api = [api stringByReplacingOccurrencesOfString:@"{ID}" withString:identifier];
    api = [api stringByReplacingOccurrencesOfString:@"{type}" withString:type];
    NSLog(@"report to URL: %@", api);
    
    // open in web view
    self.webView.customUserAgent = client.userAgent;
    
    self.webView.navigationDelegate = self;
    
    NSURL *url = [NSURL URLWithString:api];
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
