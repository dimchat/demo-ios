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
//  DIMFileTransfer.h
//  Sechat
//
//  Created by Albert Moky on 2019/9/6.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import <MingKeMing/MingKeMing.h>
#import <DIMP/DIMP.h>

NS_ASSUME_NONNULL_BEGIN

@interface DIMFileTransfer : NSObject <DIMUploadDelegate, DIMDownloadDelegate>

// upload API
//      @"https://sechat.dim.chat/{ID}/upload?md5={MD5}&salt={SALT}"
@property(nonatomic, strong) NSString *api;
// upload key (hex)
@property(nonatomic, strong) NSString *secret;

//@property(nonatomic, readonly) NSString *avatarDirectory;  // "Library/Caches/.mkm/avatar"
//@property(nonatomic, readonly) NSString *cachesDirectory;  // "Library/Caches/.dkd/caches"
//
//@property(nonatomic, readonly) NSString *uploadDirectory;    // "tmp/.dkd/upload"
//@property(nonatomic, readonly) NSString *downloadDirectory;  // "tmp/.dkd/download"

+ (instancetype)sharedInstance;

@end

@interface DIMFileTransfer (Path)

+ (NSString *)filenameForData:(NSData *)data
                     filename:(NSString *)origin;

+ (NSString *)filenameForRequest:(DIMUploadRequest *)req
                        filename:(NSString *)origin;

- (nullable NSString *)pathForContent:(id<DKDFileContent>)content;

/**
 *  Get entity file path: "Library/Caches/mkm/{AA}/{BB}/{address}/{filename}"
 *
 * @param ID     - user or group ID
 * @param origin - entity file name
 * @return entity file path
 */
+ (NSString *)pathForEntity:(id<MKMID>)ID
                   filename:(NSString *)origin;

/**
 *  Save cache file with name (or path)
 *
 * @param data     - decrypted data
 * @param filename - cache file name
 * @return data length
 */
+ (NSInteger)cacheFileData:(NSData *)data filename:(NSString *)filename;

@end

@interface DIMFileTransfer (Upload)

/**
 *  Upload avatar image data for user
 *
 * @param image    - image data
 * @param filename - image filename ('avatar.jpg')
 * @param from     - user ID
 * @param delegate - callback
 * @return remote URL if same file uploaded before
 */
- (nullable NSURL *)uploadAvatar:(NSData *)image
                        filename:(NSString *)filename
                          sender:(id<MKMID>)from
                        delegate:(id<DIMUploadDelegate>)delegate;

/**
 *  Upload encrypted file data for user
 *
 * @param data     - encrypted data
 * @param filename - data file name ('voice.mp4')
 * @param from     - user ID
 * @param delegate - callback
 * @return remote URL if same file uploaded before
 */
- (nullable NSURL *)uploadEncryptedData:(NSData *)data
                               filename:(NSString *)filename
                                 sender:(id<MKMID>)from
                               delegate:(id<DIMUploadDelegate>)delegate;

@end

@interface DIMFileTransfer (Download)

/**
 *  Download avatar image file
 *
 * @param url      - avatar URL
 * @param delegate - callback
 * @return local path if same file downloaded before
 */
- (nullable NSString *)downloadAvatar:(NSURL *)url
                             delegate:(id<DIMDownloadDelegate>)delegate;

/**
 *  Download encrypted file data for user
 *
 * @param url      - relay URL
 * @param delegate - callback
 * @return temporary path if same file downloaded before
 */
- (nullable NSString *)downloadEncryptedData:(NSURL *)url
                                    delegate:(id<DIMDownloadDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END
