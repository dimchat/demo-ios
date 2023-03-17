// license: https://mit-license.org
//
//  DIM-SDK : Decentralized Instant Messaging Software Development Kit
//
//                               Written in 2019 by Moky <albert.moky@gmail.com>
//
// =============================================================================
// The MIT License (MIT)
//
// Copyright (c) 2019 Albert Moky
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
// =============================================================================
//
//  DIMStorage.m
//  DIMP
//
//  Created by Albert Moky on 2019/9/6.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "DIMStorage.h"

@implementation DIMStorage

- (NSString *)documentDirectory {
    return [DIMStorage documentDirectory];
}

- (NSString *)cachesDirectory {
    return [DIMStorage cachesDirectory];
}

- (nullable NSDictionary *)dictionaryWithContentsOfFile:(NSString *)path {
    if (![DIMStorage fileExistsAtPath:path]) {
        NSLog(@"file not found: %@", path);
        return nil;
    }
    return [NSDictionary dictionaryWithContentsOfFile:path];
}

- (BOOL)dictionary:(NSDictionary *)dict writeToBinaryFile:(NSString *)path {
    NSString *dir = [path stringByDeletingLastPathComponent];
    if (![DIMStorage createDirectoryAtPath:dir]) {
        NSAssert(false, @"failed to create directory: %@", dir);
        return NO;
    }
    return [dict writeToBinaryFile:path];
}

- (nullable NSArray *)arrayWithContentsOfFile:(NSString *)path {
    if (![DIMStorage fileExistsAtPath:path]) {
        NSLog(@"file not found: %@", path);
        return nil;
    }
    return [NSArray arrayWithContentsOfFile:path];
}

- (BOOL)array:(NSArray *)list writeToFile:(NSString *)path {
    NSString *dir = [path stringByDeletingLastPathComponent];
    if (![DIMStorage createDirectoryAtPath:dir]) {
        NSAssert(false, @"failed to create directory: %@", dir);
        return NO;
    }
    return [list writeToFile:path atomically:YES];
}

@end

@implementation DIMStorage (Application)

static NSString *s_documentDirectory = nil;

+ (NSString *)documentDirectory {
    OKSingletonDispatchOnce(^{
        if (s_documentDirectory == nil) {
            NSArray *paths;
            paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                        NSUserDomainMask, YES);
            s_documentDirectory = paths.firstObject;
        }
    });
    return s_documentDirectory;
}

static NSString *s_cachesDirectory = nil;

+ (NSString *)cachesDirectory {
    OKSingletonDispatchOnce(^{
        if (s_cachesDirectory == nil) {
            NSArray *paths;
            paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory,
                                                        NSUserDomainMask, YES);
            s_cachesDirectory = paths.firstObject;
        }
    });
    return s_cachesDirectory;
}

@end

@implementation DIMStorage (FileManager)

+ (BOOL)createDirectoryAtPath:(NSString *)directory {
    // check base directory exists
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL isDir;
    if ([fm fileExistsAtPath:directory isDirectory:&isDir]) {
        // already exists
        NSAssert(isDir, @"path exists but not a directory: %@", directory);
        return YES;
    }
    NSError *error = nil;
    return [fm createDirectoryAtPath:directory
         withIntermediateDirectories:YES
                          attributes:nil
                               error:&error];
}

+ (BOOL)fileExistsAtPath:(NSString *)path {
    NSFileManager *fm = [NSFileManager defaultManager];
    return [fm fileExistsAtPath:path];
}

+ (BOOL)removeItemAtPath:(NSString *)path {
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:path]) {
        NSError *err = nil;
        [fm removeItemAtPath:path error:&err];
        if (err) {
            NSLog(@"failed to remove file: %@", err);
            return NO;
        }
    }
    return YES;
}

@end
