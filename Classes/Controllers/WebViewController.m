//
//  WebViewController.m
//  Sechat
//
//  Created by Albert Moky on 2019/4/8.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "DIMGlobalVariable.h"
#import "Client.h"

#import "WebViewController.h"

@interface WebViewController () {
    
    NSString *_originalTitle;
}

@end

@implementation WebViewController

-(void)loadView{
    
    [super loadView];
    
    self.activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [self.view addSubview:self.activityIndicatorView];
    
    self.webView = [[WKWebView alloc] initWithFrame:self.view.bounds];
    self.webView.navigationDelegate = self;
    [self.view addSubview:self.webView];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    _originalTitle = self.title;
    
    Client *client = [DIMGlobal terminal];
    self.webView.customUserAgent = client.userAgent;
    
    NSAssert(_url, @"entrance URL not set yet");
    NSURLRequest *request = [NSURLRequest requestWithURL:_url];
    [self.webView loadRequest:request];
}

-(void)viewWillAppear:(BOOL)animated{
    
    [super viewWillAppear:animated];
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView didReceiveServerRedirectForProvisionalNavigation:(WKNavigation *)navigation {
    
    NSURL *url = [webView URL];
    NSString *string = NSStringFromURL(url);
    if ([string hasPrefix:@"http://"]) {
        string = [@"https://" stringByAppendingString:[string substringFromIndex:7]];
        NSURL *url = NSURLFromString(string);
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        [webView loadRequest:request];
    }
}

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    
    [_activityIndicatorView startAnimating];
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    
    [_activityIndicatorView stopAnimating];
    
    NSString *title = self.webView.title;
    if (title.length > 0) {
        self.title = title;
    } else {
        self.title = _originalTitle;
    }
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    
    [_activityIndicatorView stopAnimating];
    
    NSString *title = self.webView.title;
    if (title.length > 0) {
        self.title = title;
    } else if (error.domain.length > 0) {
        self.title = error.domain;
    } else {
        self.title = _originalTitle;
    }
}

@end
