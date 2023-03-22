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
//  DIMFileTransfer.m
//  Sechat
//
//  Created by Albert Moky on 2019/9/6.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import <ObjectKey/ObjectKey.h>

#import "DIMFileTransfer.h"

static NSPredicate *s_pred = nil;
static inline NSPredicate *hex_predicate(void) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *patten = @"^[0-9A-Fa-f]+$";
        s_pred = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", patten];
    });
    return s_pred;
}
static inline BOOL is_encoded(NSString *filename, NSString *ext) {
    if (ext.length > 0) {
        filename = [filename substringToIndex:(filename.length - ext.length - 1)];
    }
    return filename.length == 32 && [hex_predicate() evaluateWithObject:filename];
}

static inline NSString *get_cache_file_path(NSString *filename) {
    if ([filename containsString:@"/"]) {
        // full path?
        return filename;
    } else {
        // relative path?
        return [DIMStorage cachePathWithFilename:filename];
    }
}

static inline NSString *get_download_file_path(NSString *filename) {
    if ([filename containsString:@"/"]) {
        // full path?
        return filename;
    } else {
        // relative path?
        return [DIMStorage downloadPathWithFilename:filename];
    }
}

static inline NSData *load_downloaded_file(NSString *filename) {
    NSString *path = get_download_file_path(filename);
    if ([DIMStorage fileExistsAtPath:path]) {
        return [DIMStorage dataWithContentsOfFile:path];
    }
    NSLog(@"download file not exists: %@", path);
    return nil;
}

/**
 *  Decrypt temporary file with password from received message
 *
 * @param path     - temporary path
 * @param password - symmetric key
 * @return decrypted data
 */
static inline NSData *decrypt_file(NSString *path, id<MKMDecryptKey> password) {
    NSData *data = load_downloaded_file(path);
    if (!data) {
        NSLog(@"failed to load temporary file: %@", path);
        return nil;
    }
    NSLog(@"decrypting file: %@, size: %ld byte(s)", path, data.length);
    return [password decrypt:data];
}

static const NSString *FORM_AVATAR = @"avatar";
static const NSString *FORM_FILE   = @"file";

static const NSTimeInterval TEMPORARY_EXPIRES = 7 * 24 * 3600;

@interface HTTPClient : DIMHttpClient

@end

@implementation HTTPClient

// Override
- (void)cleanup {
    // clean expired temporary files for upload/download
    NSTimeInterval now = OKGetCurrentTimeInterval();
    NSString *dir = [DIMStorage temporaryDirectory];
//    [DIMStorage cleanup:dir expired:(now - TEMPORARY_EXPIRES)];
}

@end

@interface DIMFileTransfer ()

@property(nonatomic, strong) DIMHttpClient *http;

@end

@implementation DIMFileTransfer

OKSingletonImplementations(DIMFileTransfer, sharedInstance)

- (instancetype)init {
    if (self = [super init]) {
        self.api = @"https://sechat.dim.chat/{ID}/upload?md5={MD5}&salt={SALT}";
        self.secret = @"12345678";
        self.http = [[HTTPClient alloc] init];
        [self.http start];
    }
    return self;
}

//- (NSString *)avatarDirectory {
//    if (!_avatarDirectory) {
//        NSString *dir = [DIMStorage cachesDirectory];
//        dir = [dir stringByAppendingPathComponent:@".mkm"];
//        dir = [dir stringByAppendingPathComponent:@"avatar"];
//        _avatarDirectory = dir;
//    }
//    return _avatarDirectory;
//}
//
//- (NSString *)cachesDirectory {
//    if (!_cachesDirectory) {
//        NSString *dir = [DIMStorage cachesDirectory];
//        dir = [dir stringByAppendingPathComponent:@".dkd"];
//        dir = [dir stringByAppendingPathComponent:@"caches"];
//        _cachesDirectory = dir;
//    }
//    return _cachesDirectory;
//}
//
//- (NSString *)uploadDirectory {
//    if (!_uploadDirectory) {
//        NSString *dir = [DIMStorage cachesDirectory];
//        dir = [dir stringByAppendingPathComponent:@".dkd"];
//        dir = [dir stringByAppendingPathComponent:@"upload"];
//        _uploadDirectory = dir;
//    }
//    return _uploadDirectory;
//}
//
//- (NSString *)downloadDirectory {
//    if (!_downloadDirectory) {
//        NSString *dir = [DIMStorage cachesDirectory];
//        dir = [dir stringByAppendingPathComponent:@".dkd"];
//        dir = [dir stringByAppendingPathComponent:@"download"];
//        _downloadDirectory = dir;
//    }
//    return _downloadDirectory;
//}

@end

@implementation DIMFileTransfer (Path)

+ (NSString *)filenameForData:(NSData *)data
                     filename:(NSString *)origin {
    // split file extension
    NSString *ext = [origin pathExtension];
    if (is_encoded(origin, ext)) {
        // already encode
        return origin;
    }
    // get filename from data
    NSString *filename = MKMHexEncode(MKMMD5Digest(data));
    if (ext.length > 0) {
        return [filename stringByAppendingPathExtension:ext];
    } else {
        return filename;
    }
}

+ (NSString *)filenameForRequest:(DIMUploadRequest *)req
                        filename:(NSString *)origin {
    if ([req isKindOfClass:[DIMUploadTask class]]) {
        return [(DIMUploadTask *)req filename];
    } else {
        return [req.path lastPathComponent];
    }
}

- (nullable NSString *)pathForContent:(id<DKDFileContent>)content {
    NSString *filename = [content filename];
    if (!filename) {
        NSAssert(false, @"file content error: %@", content);
        return nil;
    }
    // check decrypted file
    NSString *cachePath = get_cache_file_path(filename);
    if ([DIMStorage fileExistsAtPath:cachePath]) {
        return cachePath;
    }
    // get download URL
    NSURL *url = [content URL];
    if (!url) {
        NSAssert(false, @"file URL not found: %@", content);
        return nil;
    }
    // try download file from remote URL
    NSString *tempPath = [self downloadEncryptedData:url delegate:self];
    if (!tempPath) {
        NSLog(@"not download yet: %@", url);
        return nil;
    }
    // decrypt with message password
    id<MKMDecryptKey> password = [content password];
    if (!password) {
        NSLog(@"password not found: %@", content);
        return nil;
    }
    NSData *data = decrypt_file(tempPath, password);
    if (!data) {
        NSAssert(false, @"failed to decrypt file: %@, password: %@", tempPath, password);
        // delete to download again
        [DIMStorage removeItemAtPath:tempPath];
        return nil;
    }
    // save decrypted file data
    BOOL ok = [DIMFileTransfer cacheFileData:data filename:cachePath];
    if (!ok) {
        NSLog(@"failed to cache file: %@", cachePath);
        return nil;
    }
    // success
    return cachePath;
}

+ (NSString *)pathForEntity:(id<MKMID>)ID
                   filename:(NSString *)origin {
    // get entity directory
    NSString *dir = [DIMStorage cachesDirectory];
    NSString *address = [ID.address string];
    NSString *aa = [address substringWithRange:NSMakeRange(0, 2)];
    NSString *bb = [address substringWithRange:NSMakeRange(2, 4)];
    // get entity file path
    return [NSString stringWithFormat:@"%@/mkm/%@/%@/%@/%@",
            dir, aa, bb, address, origin];
}

+ (NSInteger)cacheFileData:(NSData *)data filename:(NSString *)filename {
    NSString *path = get_cache_file_path(filename);
    return [DIMStorage data:data writeToFile:path];
}

@end

@implementation DIMFileTransfer (Upload)

- (nullable NSURL *)uploadAvatar:(NSData *)image
                        filename:(NSString *)filename
                          sender:(id<MKMID>)from
                        delegate:(id<DIMUploadDelegate>)delegate {
    //filename = [filename lastPathComponent];
    filename = [DIMFileTransfer filenameForData:image filename:filename];
    NSString *path = [DIMStorage avatarPathWithFilename:filename];
    return [self upload:image
                   path:path
                   name:FORM_AVATAR
                 sender:from
               delegate:delegate];
}

- (nullable NSURL *)uploadEncryptedData:(NSData *)data
                               filename:(NSString *)filename
                                 sender:(id<MKMID>)from
                               delegate:(id<DIMUploadDelegate>)delegate {
    //filename = [filename lastPathComponent];
    filename = [DIMFileTransfer filenameForData:data filename:filename];
    NSString *path = [DIMStorage uploadPathWithFilename:filename];
    return [self upload:data
                   path:path
                   name:FORM_FILE
                 sender:from
               delegate:delegate];
}

// private
- (nullable NSURL *)upload:(NSData *)data
                      path:(NSString *)path
                      name:(const NSString*)var
                    sender:(id<MKMID>)from
                  delegate:(id<DIMUploadDelegate>)delegate {
    NSURL *url = [[NSURL alloc] initWithString:self.api];
    NSData *key = MKMHexDecode(self.secret);
    if (!delegate) {
        delegate = self;
    }
    return [_http upload:url
                  secret:key
                    data:data
                    path:path
                    name:var
                  sender:from
                delegate:delegate];
}

@end

@implementation DIMFileTransfer (Download)

- (nullable NSString *)downloadAvatar:(NSURL *)url
                             delegate:(id<DIMDownloadDelegate>)delegate {
    NSString *filename = [DIMFileTransfer filenameForURL:url];
    NSString *path = [DIMStorage avatarPathWithFilename:filename];
    if (!delegate) {
        delegate = self;
    }
    return [_http download:url path:path delegate:delegate];
}

- (nullable NSString *)downloadEncryptedData:(NSURL *)url
                                    delegate:(id<DIMDownloadDelegate>)delegate {
    NSString *filename = [DIMFileTransfer filenameForURL:url];
    NSString *path = [DIMStorage downloadPathWithFilename:filename];
    if (!delegate) {
        delegate = self;
    }
    return [_http download:url path:path delegate:delegate];
}

// private
+ (NSString *)filenameForURL:(NSURL *)url {
    NSString *urlString = [url absoluteString];
    NSString *filename = [urlString lastPathComponent];
    NSData *data = MKMUTF8Encode(urlString);
    return [self filenameForData:data filename:filename];
}

@end
