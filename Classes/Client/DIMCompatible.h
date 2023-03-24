//
//  DIMCompatible.h
//  Sechat
//
//  Created by Albert Moky on 2023/3/13.
//  Copyright © 2023 DIM Group. All rights reserved.
//

#import <DIMClient/DIMClient.h>

NS_ASSUME_NONNULL_BEGIN

// TODO: remove after all server/client upgraded
@interface DIMCompatible : NSObject

+ (void)fixMetaAttachment:(id<DKDReliableMessage>)rMsg;

// fixMetaVersion
+ (NSDictionary<NSString *, id> *)fixMeta:(NSDictionary<NSString *, id> *)meta;

+ (id<DKDCommand>)fixCommand:(id<DKDCommand>)content;

+ (id<DKDCommand>)fixCmd:(id<DKDCommand>)content;

+ (void)fixReceiptCommand:(id<DKDReceiptCommand>)content;

@end

NS_ASSUME_NONNULL_END
