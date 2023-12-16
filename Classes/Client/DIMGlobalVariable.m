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
//  DIMGlobalVariable.m
//  Sechat
//
//  Created by Albert Moky on 2023/3/13.
//  Copyright © 2023 DIM Group. All rights reserved.
//

#import "Client.h"

#import "DIMGlobalVariable.h"

@interface SharedArchivist : DIMClientArchivist

@end

@implementation SharedArchivist

- (DIMCommonFacebook *)facebook {
    DIMGlobalVariable *shared = [DIMGlobalVariable sharedInstance];
    return [shared facebook];
}

- (DIMCommonMessenger *)messenger {
    DIMGlobalVariable *shared = [DIMGlobalVariable sharedInstance];
    return [shared messenger];
}

@end

@implementation DIMGlobalVariable

OKSingletonImplementations(DIMGlobalVariable, sharedInstance)

- (instancetype)init {
    if (self = [super init]) {
        DIMSharedDatabase *db = [[DIMSharedDatabase alloc] init];
        DIMClientArchivist *archivist = [[SharedArchivist alloc] initWithDatabase:db];
        DIMSharedFacebook *facebook = [[DIMSharedFacebook alloc] init];
        self.adb = db;
        self.mdb = db;
        self.sdb = db;
        self.database = db;
        self.archivist = archivist;
        self.facebook = facebook;
        self.emitter = [[DIMEmitter alloc] init];
        self.terminal = [[Client alloc] initWithFacebook:facebook database:db];
        // load plugins
        [DIMSharedFacebook prepare];
        [DIMSharedMessenger prepare];
    }
    return self;
}

@end
