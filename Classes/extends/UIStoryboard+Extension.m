//
//  UIStoryboard+Extension.m
//  Sechat
//
//  Created by Albert Moky on 2019/4/8.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "UIStoryboard+Extension.h"

@implementation UIStoryboard (Identifier)

+ (__kindof UIViewController *)instantiateViewControllerWithIdentifier:(nullable NSString *)identifier storyboardName:(NSString *)name bundle:(nullable NSBundle *)storyboardBundleOrNil {
    
    UIStoryboard *sb = [UIStoryboard storyboardWithName:name bundle:storyboardBundleOrNil];
    UIViewController *vc;
    if (identifier) {
        vc = [sb instantiateViewControllerWithIdentifier:identifier];
    } else {
        vc = [sb instantiateInitialViewController];
    }
    NSAssert(vc != nil, @"failed to get view controller: %@ -> %@", name, identifier);
    return vc;
}

+ (__kindof UIViewController *)instantiateViewControllerWithIdentifier:(NSString *)identifier storyboardName:(NSString *)name {
    
    return [self instantiateViewControllerWithIdentifier:identifier storyboardName:name bundle:nil];
}

+ (__kindof UIViewController *)instantiateInitialViewControllerWithStoryboardName:(NSString *)name {
    
    return [self instantiateViewControllerWithIdentifier:nil storyboardName:name bundle:nil];
}

@end
