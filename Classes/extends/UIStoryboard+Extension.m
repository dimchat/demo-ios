//
//  UIStoryboard+Extension.m
//  Sechat
//
//  Created by Albert Moky on 2019/4/8.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "UIStoryboard+Extension.h"

@implementation UIStoryboard (Extension)

+ (__kindof UIViewController *)instantiateViewControllerWithIdentifier:(NSString *)identifier storyboardName:(NSString *)name bundle:(nullable NSBundle *)storyboardBundleOrNil {
    
    UIStoryboard *sb = [UIStoryboard storyboardWithName:name bundle:storyboardBundleOrNil];
    UIViewController *vc = [sb instantiateViewControllerWithIdentifier:identifier];
    NSAssert(vc != nil, @"failed to get view controller: %@ -> %@", name, identifier);
    return vc;
}

+ (__kindof UIViewController *)instantiateViewControllerWithIdentifier:(NSString *)identifier storyboardName:(NSString *)name {
    
    return [self instantiateViewControllerWithIdentifier:identifier storyboardName:name bundle:nil];
}

@end
