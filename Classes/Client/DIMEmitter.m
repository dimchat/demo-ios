// license: https://mit-license.org
//
//  SeChat : Secure/secret Chat Application
//
//                               Written in 2023 by Moky <albert.moky@gmail.com>
//
// =============================================================================
// The MIT License (MIT)
//
// Copyright (c) 2023 Albert Moky
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
//  DIMEmitter.m
//  Sechat
//
//  Created by Albert Moky on 2023/3/13.
//  Copyright © 2023 DIM Group. All rights reserved.
//

#import "DIMConstants.h"
#import "DIMGlobalVariable.h"
#import "DIMMessageDataSource.h"

#import "DIMEmitter.h"

@interface DIMEmitter ()

// filename => URL
@property(nonatomic, strong) NSMutableDictionary<NSString *, NSURL *> *cdn;

@end

@implementation DIMEmitter

- (instancetype)init {
    if (self = [super init]) {
        self.cdn = [NSMutableDictionary dictionary];
        
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc addObserver:self selector:@selector(onFileUploadSuccess:) name:kNotificationName_FileUploaded object:nil];
        [nc addObserver:self selector:@selector(onFileUploadFailed:) name:kNotificationName_FileUploadFailed object:nil];
    }
    return self;
}

- (void)onFileUploadSuccess:(NSNotification *)notification {
    // TODO: send suspended message
}

- (void)onFileUploadFailed:(NSNotification *)notification {
    // TODO: mark message failed
}

- (void)sendText:(NSString *)text receiver:(id<MKMID>)to {
    id<DKDContent> content = [[DIMTextContent alloc] initWithText:text];
    [self sendContent:content receiver:to];
}

- (void)sendImage:(NSData *)jpeg thumbnail:(NSData *)small receiver:(id<MKMID>)to {
    NSUInteger length = jpeg.length;
    NSAssert(length > 0, @"image data empty");
    NSString *filename = MKMHexEncode(MKMMD5Digest(jpeg));
    filename = [filename stringByAppendingPathExtension:@"jpeg"];
    id<DKDImageContent> content;
    content = [[DIMImageContent alloc] initWithImageData:jpeg
                                                filename:filename];
    // add image data length & thumbnail into message content
    [content setObject:@(length) forKey:@"length"];
    [content setThumbnail:small];
    [self sendContent:content receiver:to];
}

- (void)sendVoice:(NSData *)mp4 duration:(NSTimeInterval)ti receiver:(id<MKMID>)to {
    NSUInteger length = mp4.length;
    NSAssert(length > 0, @"voice data empty");
    NSString *filename = MKMHexEncode(MKMMD5Digest(mp4));
    filename = [filename stringByAppendingPathExtension:@"mp4"];
    id<DKDAudioContent> content;
    content = [[DIMAudioContent alloc] initWithAudioData:mp4
                                                filename:filename];
    // add image data length & thumbnail into message content
    [content setObject:@(length) forKey:@"length"];
    [content setObject:@(ti) forKey:@"duration"];
    [self sendContent:content receiver:to];
}

// private
- (void)sendContent:(id<DKDContent>)content receiver:(id<MKMID>)to {
    NSAssert(to, @"receiver should not empty");
    DIMSharedMessenger *messenger = [DIMGlobal messenger];
    OKPair<id<DKDInstantMessage>, id<DKDReliableMessage>> *result;
    result = [messenger sendContent:content
                             sender:nil
                           receiver:to
                           priority:STDeparturePriorityNormal];
    if (result.second == nil) {
        NSLog(@"not send yet (type: %d): %@", content.type, to);
        return;
    }
    NSAssert(result.first, @"failed to pack instant message: %@", to);
    // save instant message
    DIMMessageDataSource *mds = [DIMMessageDataSource sharedInstance];
    [mds saveInstantMessage:result.first];
}

// private
- (void)sendInstantMessage:(id<DKDInstantMessage>)iMsg {
    NSLog(@"send insetant message (type: %d): %@ -> %@", iMsg.content.type, iMsg.sender, iMsg.receiver);
    // send by shared messenger
    DIMSharedMessenger *messenger = [DIMGlobal messenger];
    [messenger sendInstantMessage:iMsg priority:STDeparturePriorityNormal];
    // save instant message
    DIMMessageDataSource *mds = [DIMMessageDataSource sharedInstance];
    [mds saveInstantMessage:iMsg];
}

- (void)sendFileContentMessage:(id<DKDInstantMessage>)iMsg
                      password:(id<MKMSymmetricKey>)key {
    id<DKDFileContent> content = (id<DKDFileContent>)[iMsg content];
    // 1. save origin file data
    NSData *data = [content fileData];
    NSString *filename = [content filename];
    DIMFileServer *ftp = [DIMFileServer sharedInstance];
    BOOL ok = [ftp saveData:data filename:filename];
    if (!ok) {
        NSLog(@"failed to save file data (%lu bytes): %@", data.length, filename);
        return;
    }
    // 2. save instant message without file data
    [content setFileData:nil];
    DIMMessageDataSource *mds = [DIMMessageDataSource sharedInstance];
    ok = [mds saveInstantMessage:iMsg];
    if (!ok) {
        NSLog(@"failed to save file message: %@ -> %@", iMsg.sender, iMsg.receiver);
        return;
    }
    // 3. add upload task with encrypted data
    NSData *encrypted = [key encrypt:data];
    NSString *ext = [filename pathExtension];
    filename = MKMHexEncode(MKMMD5Digest(encrypted));
    if ([ext length] > 0) {
        filename = [filename stringByAppendingPathExtension:ext];
    }
    // 4. check for same file
    NSURL *url = [_cdn objectForKey:filename];
    if (url) {
        // already upload before, set URL and send out immediately
        NSLog(@"sent filename: %@ -> %@ => %@", content.filename, filename, url);
        [content setURL:url];
        [self sendInstantMessage:iMsg];
    } else {
        // TODO: add task for upload
    }
}

//
//  Upload Task Queue
//

- (DIMEmitter *)start {
    // TODO: start a background thread
    return self;
}

// Override
- (void)stop {
    [super stop];
}

// Override
- (BOOL)process {
    // TODO: run upload tasks in queue
    return NO;
}

@end
