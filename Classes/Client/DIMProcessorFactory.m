// license: https://mit-license.org
//
//  SeChat : Secure/secret Chat Application
//
//                               Written in 2021 by Moky <albert.moky@gmail.com>
//
// =============================================================================
// The MIT License (MIT)
//
// Copyright (c) 2021 Albert Moky
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
//  DIMProcessorFactory.m
//  DIMP
//
//  Created by Albert Moky on 2021/11/22.
//  Copyright © 2021 DIM Group. All rights reserved.
//

#import "DIMSearchCommand.h"
#import "DIMStorageCommand.h"

#import "DIMDefaultProcessor.h"
#import "DIMApplicationContentProcessor.h"
#import "DIMFileContentProcessor.h"
#import "DIMMuteCommandProcessor.h"
#import "DIMBlockCommandProcessor.h"
#import "DIMStorageCommandProcessor.h"
#import "DIMSearchCommandProcessor.h"

#import "DIMProcessorFactory.h"

#define CREATE_CPU(clazz)                                                      \
            [[clazz alloc] initWithFacebook:self.facebook                      \
                                  messenger:self.messenger]                    \
                                                   /* EOF 'CREATE_CPU(clazz)' */

@implementation SCProcessorCreator

- (id<DIMContentProcessor>)createContentProcessor:(DKDContentType)type {
    // application customized
    if (type == DKDContentType_Application) {
        return CREATE_CPU(DIMAppContentProcessor);
    //} else if (type == DKDContentType_Customized) {
    //    return CREATE_CPU(DIMAppContentProcessor);
    }
//    if (type == DKDContentType_History) {
//        return CREATE_CPU(DIMHistoryCommandProcessor);
//    }
    // file
    if (type == DKDContentType_File) {
        return CREATE_CPU(DIMFileContentProcessor);
    } else if (type == DKDContentType_Image || type == DKDContentType_Audio || type == DKDContentType_Video) {
        // TODO: shared the same processor with 'FILE'?
        return CREATE_CPU(DIMFileContentProcessor);
    }
    // default
    if (type == 0) {
        return CREATE_CPU(DIMDefaultContentProcessor);
    }
    return [super createContentProcessor:type];
}

- (id<DIMContentProcessor>)createCommandProcessor:(NSString *)name type:(DKDContentType)type {
//    // receipt
//    if ([name isEqualToString:DIMCommand_Receipt]) {
//        return CREATE_CPU(DIMReceiptCommandProcessor);
//    }
    // mute
    if ([name isEqualToString:DIMCommand_Mute]) {
        return CREATE_CPU(DIMMuteCommandProcessor);
    }
    // block
    if ([name isEqualToString:DIMCommand_Block]) {
        return CREATE_CPU(DIMBlockCommandProcessor);
    }
//    // handshake
//    if ([name isEqualToString:DIMCommand_Handshake]) {
//        return CREATE_CPU(DIMHandshakeCommandProcessor);
//    }
//    // login
//    if ([name isEqualToString:DIMCommand_Login]) {
//        return CREATE_CPU(DIMLoginCommandProcessor);
//    }
    // storage
    if ([name isEqualToString:DIMCommand_Storage]) {
        return CREATE_CPU(DIMStorageCommandProcessor);
    } else if ([name isEqualToString:@"contacts"] || [name isEqualToString:@"private_key"]) {
        // TODO: shared the same processor with 'storage'?
        return CREATE_CPU(DIMStorageCommandProcessor);
    }
    // search
    if ([name isEqualToString:DIMCommand_Search]) {
        return CREATE_CPU(DIMSearchCommandProcessor);
    } else if ([name isEqualToString:DIMCommand_OnlineUsers]) {
        // TODO: shared the same processor with 'search'?
        return CREATE_CPU(DIMSearchCommandProcessor);
    }
//    // group commands
//    if ([name isEqualToString:@"group"]) {
//        return CREATE_CPU(DIMGroupCommandProcessor);
//    } else if ([name isEqualToString:DIMGroupCommand_Invite]) {
//        return CREATE_CPU(DIMInviteGroupCommandProcessor);
//    } else if ([name isEqualToString:DIMGroupCommand_Expel]) {
//        return CREATE_CPU(DIMExpelGroupCommandProcessor);
//    } else if ([name isEqualToString:DIMGroupCommand_Quit]) {
//        return CREATE_CPU(DIMQuitGroupCommandProcessor);
//    } else if ([name isEqualToString:DIMGroupCommand_Query]) {
//        return CREATE_CPU(DIMQueryGroupCommandProcessor);
//    } else if ([name isEqualToString:DIMGroupCommand_Reset]) {
//        return CREATE_CPU(DIMResetGroupCommandProcessor);
//    }
    // others
    return [super createCommandProcessor:name type:type];
}

@end
