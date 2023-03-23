//
//  DIMInstantMessage+Extension.m
//  Sechat
//
//  Created by Albert Moky on 2019/4/4.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "DIMFileTransfer.h"

#import "DIMInstantMessage+Extension.h"

@implementation DIMInstantMessage (Image)

- (nullable UIImage *)image {
    id<DKDImageContent> content = (id<DKDImageContent>)[self content];
    if (content.type != DKDContentType_Image) {
        // not Image message
        return nil;
    }

    NSData *imageData = [content imageData];
    if (!imageData) {
        DIMFileTransfer *ftp = [DIMFileTransfer sharedInstance];
        NSString *path = [ftp pathForContent:content];
        if (path) {
            imageData = [DIMStorage dataWithContentsOfFile:path];
        }
    }
    
    if (imageData) {
        UIImage *image = [UIImage imageWithData:imageData];
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

    NSData *imageData = (NSData *)content.thumbnail;
    if (imageData) {
        return [UIImage imageWithData:imageData];
    }
    return nil;
}

- (nullable NSData *)audioData {
    id<DKDAudioContent> content = (id<DKDAudioContent>)[self content];
    if (content.type != DKDContentType_Audio) {
        return nil;
    }
    
    NSData *audioData = [content audioData];
    if (!audioData) {
        DIMFileTransfer *ftp = [DIMFileTransfer sharedInstance];
        NSString *path = [ftp pathForContent:content];
        if (path) {
            audioData = [DIMStorage dataWithContentsOfFile:path];
        }
    }
    
    return audioData;
}

@end
