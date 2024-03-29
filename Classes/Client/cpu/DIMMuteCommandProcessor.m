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
//  DIMMuteCommandProcessor.m
//  DIMP
//
//  Created by Albert Moky on 2019/12/2.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "LocalDatabaseManager.h"

#import "DIMMuteCommandProcessor.h"

@implementation DIMMuteCommandProcessor

- (NSArray<id<DKDContent>> *)processContent:(id<DKDContent>)content
                                withMessage:(id<DKDReliableMessage>)rMsg {
    NSAssert([content isKindOfClass:[DIMMuteCommand class]], @"mute command error: %@", content);
    DIMMuteCommand *command = (DIMMuteCommand *)content;
    DIMCommonFacebook *facebook = self.facebook;
    
    NSArray *muteList = command.list;
    id<MKMUser> user = [facebook currentUser];
    
    LocalDatabaseManager *manager = [LocalDatabaseManager sharedInstance];
    [manager unmuteAllConversationForUser:user.ID];
    
    id<MKMID> conversationID;
    for (NSString *item in muteList){
        conversationID = MKMIDParse(item);
        [manager muteConversation:conversationID forUser:user.ID];
    }
    
    // no need to respond this command
    return nil;
}

@end
