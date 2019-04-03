//
//  FileTransporter.h
//  Sechat
//
//  Created by Albert Moky on 2019/4/2.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <DIMCore/DIMCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface FileTransporter : NSObject <NSURLSessionDelegate, NSURLSessionTaskDelegate>

+ (instancetype)sharedInstance;

- (NSURL *)uploadData:(const NSData *)data filename:(nullable const NSString *)name sender:(const DIMID *)from;

- (NSData *)downloadDataFromURL:(const NSURL *)url filename:(nullable const NSString *)name sender:(const DIMID *)from;

@end

NS_ASSUME_NONNULL_END
