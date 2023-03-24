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
#import <DIMClient/DIMClient.h>

NS_ASSUME_NONNULL_BEGIN

@interface DIMFileTransfer : NSObject <DIMUploadDelegate, DIMDownloadDelegate>

// upload API
//      @"https://sechat.dim.chat/{ID}/upload?md5={MD5}&salt={SALT}"
@property(nonatomic, strong) NSString *api;
// upload key (hex)
@property(nonatomic, strong) NSString *secret;

+ (instancetype)sharedInstance;

@end

@interface DIMFileTransfer (Path)

+ (NSString *)filenameForData:(NSData *)data
                     filename:(NSString *)origin;

+ (NSString *)filenameForRequest:(DIMUploadRequest *)req;

//
//  Decryption process
//  ~~~~~~~~~~~~~~~~~~
//
//  1. get 'filename' from file content and call 'getCacheFilePath(filename)',
//     if not null, means this file is already downloaded an decrypted;
//
//  2. get 'URL' from file content and call 'downloadEncryptedFile(url)',
//     if not null, means this file is already downloaded but not decrypted yet,
//     this step will get a temporary path for encrypted data, continue step 3;
//     if the return path is null, then let the delegate waiting for response;
//
//  3. get 'password' from file content and call 'decryptFileData(path, password)',
//     this step will get the decrypted file data, you should save it to cache path
//     by calling 'cacheFileData(data, filename)', notice that this filename is in
//     hex format by hex(md5(data)), which is the same string with content.filename.
//

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
 * @return remote URL if same file uploaded before
 */
- (nullable NSURL *)uploadAvatar:(NSData *)image
                        filename:(NSString *)filename
                          sender:(id<MKMID>)from;

/**
 *  Upload encrypted file data for user
 *
 * @param data     - encrypted data
 * @param filename - data file name ('voice.mp4')
 * @param from     - user ID
 * @return remote URL if same file uploaded before
 */
- (nullable NSURL *)uploadEncryptedData:(NSData *)data
                               filename:(NSString *)filename
                                 sender:(id<MKMID>)from;

@end

@interface DIMFileTransfer (Download)

/**
 *  Download avatar image file
 *
 * @param url      - avatar URL
 * @return local path if same file downloaded before
 */
- (nullable NSString *)downloadAvatar:(NSURL *)url;

/**
 *  Download encrypted file data for user
 *
 * @param url      - relay URL
 * @return temporary path if same file downloaded before
 */
- (nullable NSString *)downloadEncryptedData:(NSURL *)url;

@end

NS_ASSUME_NONNULL_END
