//
//  DIMCompatible.m
//  Sechat
//
//  Created by Albert Moky on 2023/3/13.
//  Copyright © 2023 DIM Group. All rights reserved.
//

#import "DIMCompatible.h"

@implementation DIMCompatible

+ (void)fixMetaAttachment:(id<DKDReliableMessage>)rMsg {
    id meta = [rMsg objectForKey:@"meta"];
    if (meta) {
        meta = [self fixMeta:meta];
        if (meta) {
            [rMsg setObject:meta forKey:@"meta"];
        }
    }
}

// fixMetaVersion
+ (NSDictionary<NSString *, id> *)fixMeta:(NSDictionary<NSString *, id> *)meta {
    NSMutableDictionary *mDict;
    if ([meta isKindOfClass:[NSMutableDictionary class]]) {
        mDict = (NSMutableDictionary *)meta;
    } else {
        mDict = [meta mutableCopy];
    }
    id version = [meta objectForKey:@"version"];
    if (!version) {
        version = [meta objectForKey:@"type"];
        [mDict setObject:version forKey:@"version"];
    } else if ([meta objectForKey:@"type"] == nil) {
        [mDict setObject:version forKey:@"type"];
    }
    return mDict;
}

+ (id<DKDCommand>)fixCommand:(id<DKDCommand>)content {
    // 1. fix 'cmd'
    content = [self fixCmd:content];
    // 2. fix other commands
    if ([content conformsToProtocol:@protocol(DKDReceiptCommand)]) {
        [self fixReceiptCommand:(id<DKDReceiptCommand>)content];
    } else if ([content conformsToProtocol:@protocol(DKDMetaCommand)]) {
        id meta = [content objectForKey:@"meta"];
        if (meta) {
            meta = [self fixMeta:meta];
            if (meta) {
                [content setObject:meta forKey:@"meta"];
            }
        }
    }
    // OK
    return content;
}

+ (id<DKDCommand>)fixCmd:(id<DKDCommand>)content {
    id cmd = [content objectForKey:@"cmd"];
    if (!cmd) {
        cmd = [content objectForKey:@"command"];
        [content setObject:cmd forKey:@"cmd"];
    } else if ([content objectForKey:@"command"] == nil) {
        [content setObject:cmd forKey:@"command"];
        content = DKDCommandParse(content.dictionary);
    }
    return content;
}

+ (void)fixReceiptCommand:(id<DKDReceiptCommand>)content {
    // check for v2.0
    id origin = [content objectForKey:@"origin"];
    if (origin) {
        // (v2.0)
        // compatible with v1.0
        [content setObject:origin forKey:@"envelope"];
        // compatible with older version
        [self copyReceiptValues:content fromOrigin:origin];
    } else {
        // check for v1.0
        id envelope = [content objectForKey:@"envelope"];
        if (envelope) {
            // (v1.0)
            // compatible with v2.0
            [content setObject:envelope forKey:@"origin"];
            // compatible with older version
            [self copyReceiptValues:content fromOrigin:envelope];
        } else {
            // check for older version
            if (![content objectForKey:@"sender"]) {
                // this receipt contains no envelope info,
                // no need to fix it.
                return;
            }
            // older version
            NSMutableDictionary *env = [[NSMutableDictionary alloc] initWithCapacity:5];
            copy_value(env, content, @"sender");
            copy_value(env, content, @"receiver");
            copy_value(env, content, @"time");
            copy_value(env, content, @"sn");
            copy_value(env, content, @"signature");
            [content setObject:env forKey:@"origin"];
            [content setObject:env forKey:@"envelope"];
        }
    }
}

static inline void copy_value(NSMutableDictionary *env, id<DKDReceiptCommand> content, NSString *key) {
    id value = [content objectForKey:key];
    if (value) {
        [env setObject:value forKey:key];
    } else {
        [env removeObjectForKey:key];
    }
}

+ (void)copyReceiptValues:(id<DKDReceiptCommand>)content fromOrigin:(NSDictionary *)origin {
    for (NSString *name in origin) {
        if ([name isEqualToString:@"type"]) {
            continue;
        } else if ([name isEqualToString:@"time"]) {
            continue;
        }
        [content setObject:[origin objectForKey:name] forKey:name];
    }
}

@end
