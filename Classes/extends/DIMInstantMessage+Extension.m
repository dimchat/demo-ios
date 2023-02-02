//
//  DIMInstantMessage+Extension.m
//  Sechat
//
//  Created by Albert Moky on 2019/4/4.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "DIMInstantMessage+Extension.h"

@implementation DIMInstantMessage (Image)

- (nullable UIImage *)image {
    DIMImageContent *content = (DIMImageContent *)self.content;
    if (content.type != DKDContentType_Image) {
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
        
        id<MKMSymmetricKey> scKey = MKMSymmetricKeyParse([content objectForKey:@"password"]);
        if (!scKey) {
            // key not exists, it means the downloaded data is already decrypted
            break;
        }
        
        // decrypt it
        imageData = [ftp decryptDataFromURL:url filename:filename wityKey:scKey];
        
        break;
    }
    
    UIImage *image = nil;
    if (imageData) {
        image = [UIImage imageWithData:imageData];
        if (image) {
            // the thumbnail is no use now
            [content removeObjectForKey:@"thumbnail"];
            return image;
        }
    }
    
    // use thumbnail as a stopgap
    return [self thumbnail];
}

- (UIImage *)thumbnail {
    DIMImageContent *content = (DIMImageContent *)self.content;
    if (content.type != DKDContentType_Image) {
        // not Image message
        return nil;
    }
    
    DIMFileServer *ftp = [DIMFileServer sharedInstance];

    NSString *filename = content.filename;
    NSData *imageData = (NSData *)content.thumbnail;
    if (imageData) {
        NSAssert(filename.length > 0, @"image filename not found: %@", content);
        
        if ([ftp saveThumbnail:imageData filename:filename]) {
            // saved, remove BASE64 data
            [content removeObjectForKey:@"thumbnail"];
        }
    } else {
        imageData = [ftp loadThumbnailWithFilename:filename];
    }
    
    if (imageData) {
        return [UIImage imageWithData:imageData];
    }
    return nil;
}

- (nullable NSData *)audioData {
    DIMAudioContent *content = (DIMAudioContent *)self.content;
    if (content.type != DKDContentType_Audio) {
        return nil;
    }
    
    NSData *audioData = (NSData *)content.audioData;
    while (audioData == nil) {
        
        // try from local cache
        DIMFileServer *ftp = [DIMFileServer sharedInstance];
        NSString *filename = content.filename;
        audioData = [ftp loadDataWithFilename:filename];
        if (audioData) {
            break;
        }
        
        // check URL
        NSURL *url = content.URL;
        if (!url) {
            break;
        }
        
        // try to download
        audioData = [ftp downloadEncryptedDataFromURL:url];
        if (!audioData) {
            break;
        }
        
        id<MKMSymmetricKey> scKey = MKMSymmetricKeyParse([content objectForKey:@"password"]);
        if (!scKey) {
            // key not exists, it means the downloaded data is already decrypted
            break;
        }
        
        // decrypt it
        audioData = [ftp decryptDataFromURL:url filename:filename wityKey:scKey];
        
        break;
    }
    
    return audioData;
}

@end
