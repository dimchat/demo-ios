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
//  DIMSharedDatabase.h
//  Sechat
//
//  Created by Albert Moky on 2019/9/6.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "DIMMetaTable.h"
#import "DIMDocumentTable.h"
#import "DIMUserTable.h"
//#import "DIMContactTable.h"
#import "DIMGroupTable.h"
//#import "DIMMsgKeyTable.h"
#import "DIMKeyStore.h"
//#import "DIMLoginTable.h"
//#import "DIMProviderTable.h"

NS_ASSUME_NONNULL_BEGIN

@interface DIMSharedDatabase : NSObject <DIMAccountDBI, DIMMessageDBI, DIMSessionDBI,
                                         DIMUserTable, DIMGroupTable>

//@property(nonatomic, strong) id<DIMPrivateKeyTable> privateKeyTable;

@property(nonatomic, strong) id<DIMMetaTable> metaTable;

@property(nonatomic, strong) id<DIMDocumentTable> documentTable;

@property(nonatomic, strong) id<DIMUserTable> userTable;

//@property(nonatomic, strong) id<DIMContactTable> contactTable;

@property(nonatomic, strong) id<DIMGroupTable> groupTable;

@property(nonatomic, strong) id<DIMMsgKeyTable> msgKeyTable;

//@property(nonatomic, strong) id<DIMLoginTable> loginTable;

//@property(nonatomic, strong) id<DIMProviderTable> providerTable;

@end

NS_ASSUME_NONNULL_END
