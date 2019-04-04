//
//  DIMInstantMessage+Extension.m
//  Sechat
//
//  Created by Albert Moky on 2019/4/4.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "DIMInstantMessage+Extension.h"

@implementation DIMInstantMessage (Extension)

- (nullable UIImage *)image {
    DIMMessageContent *content = self.content;
    if (content.type != DIMMessageType_Image) {
        // not Image message
        return nil;
    }
    
    NSData *imageData = (NSData *)content.imageData;
    while (imageData == nil) {
        
        // try from local cache
        DIMFileServer *ftp = [DIMFileServer sharedInstance];
        NSString *filename = content.filename;
        imageData = [ftp loadDataWithFilename:filename];
        if (imageData) {
            break;
        }
        
        // check URL
        NSURL *url = content.URL;
        if (!url) {
            break;
        }
        
        // try to download
        imageData = [ftp downloadEncryptedDataFromURL:url];
        if (!imageData) {
            break;
        }
        
        DIMSymmetricKey *scKey = [content objectForKey:@"key"];
        if (!scKey) {
            // key not exists, it means the downloaded data is already decrypted
            break;
        }
        
        // decrypt it
        scKey = [DIMSymmetricKey keyWithKey:scKey];
        imageData = [ftp decryptDataFromURL:url filename:filename wityKey:scKey];
        
        break;
    }
    
    UIImage *image = nil;
    if (imageData) {
        image = [UIImage imageWithData:imageData];
        if (image) {
            return image;
        }
    }
    // use thumbnail as a stopgap
    imageData = (NSData *)content.thumbnail;
    if (imageData) {
        image = [UIImage imageWithData:imageData];
    }
    return image;

}

@end
