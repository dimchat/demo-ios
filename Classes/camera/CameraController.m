//
//  CameraController.m
//  Sechat
//
//  Created by Albert Moky on 2019/4/2.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import <MobileCoreServices/MobileCoreServices.h>

#import "CameraController.h"

static inline BOOL supports(NSString *mediaType, UIImagePickerControllerSourceType sourceType) {
    NSArray *availableTypes = [UIImagePickerController availableMediaTypesForSourceType:sourceType];
    for (NSString *item in availableTypes) {
        if ([item isEqualToString:mediaType]) {
            return YES;
        }
    }
    return NO;
}

@implementation ImagePickerController

- (instancetype)init {
    if (self = [super init]) {
        self.allowsEditing = YES;
        self.delegate = self;
    }
    return self;
}

- (void)showWithViewController:(UIViewController *)vc completionHandler:(ImagePickerControllerCompletionHandler)completion {
    self.completionHandler = completion;
    [vc presentViewController:self animated:YES completion:^{
        //
    }];
}

#pragma mark UIImagePickerControllerDelegate

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissViewControllerAnimated:YES completion:^{
        //
    }];
}

@end

#pragma mark -

@implementation CameraController

- (instancetype)init {
    if (self = [super init]) {
        // source type
        if ([self isCameraAvailable]) {
            self.sourceType = UIImagePickerControllerSourceTypeCamera;
            // media types
            NSMutableArray *mediaTypes = [[NSMutableArray alloc] init];
            if ([self doesCameraSupportTakingPhotos]) {
                [mediaTypes addObject:(NSString *)kUTTypeImage];
            }
            if ([self doesCameraSupportShootingVideos]) {
                [mediaTypes addObject:(NSString *)kUTTypeMovie];
            }
            self.mediaTypes = mediaTypes;
            
            // video
            self.videoQuality = UIImagePickerControllerQualityTypeHigh;
            self.videoMaximumDuration = 10.0f;
        }
    }
    return self;
}

- (BOOL)isCameraAvailable {
    return [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera];
}

- (BOOL)isRearCameraAvailable {
    return [UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceRear];
}

- (BOOL)isFrontCameraAvailable {
    return [UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront];
}

- (BOOL)doesCameraSupportShootingVideos {
    return supports((NSString *)kUTTypeMovie, UIImagePickerControllerSourceTypeCamera);
}

- (BOOL)doesCameraSupportTakingPhotos {
    return supports((NSString *)kUTTypeImage, UIImagePickerControllerSourceTypeCamera);
}

#pragma mark UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey, id> *)info {
    NSLog(@"media info: %@", info);
    NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    if ([mediaType isEqualToString:(NSString *)kUTTypeImage]) {
        // image
        UIImage *image;
        if ([self allowsEditing]) {
            image = [info objectForKey:UIImagePickerControllerEditedImage];
        } else {
            image = [info objectForKey:UIImagePickerControllerOriginalImage];
        }
        NSURL *imageURL = [info objectForKey:UIImagePickerControllerImageURL];
        NSString *path = [imageURL path];
        if (_completionHandler) {
            _completionHandler(image, path, info, self);
        }
    } else if ([mediaType isEqualToString:(NSString *)kUTTypeMovie]) {
        // movie
        NSURL *movieURL = [info objectForKey:UIImagePickerControllerMediaURL];
        NSString *path = [movieURL path];
        if (_completionHandler) {
            _completionHandler(nil, path, info, self);
        }
    }
    // dismiss
    [self dismissViewControllerAnimated:YES completion:^{
        //
    }];
}

@end

@implementation AlbumController

- (instancetype)init {
    if (self = [super init]) {
        // source type
        if ([self isPhotoLibraryAvailable]) {
            self.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            // media types
            NSMutableArray *mediaTypes = [[NSMutableArray alloc] initWithCapacity:2];
            if ([self canUserPickPhotosFromPhotoLibrary]) {
                [mediaTypes addObject:(NSString *)kUTTypeImage];
            }
            if ([self canUserPickVideosFromPhotoLibrary]) {
                [mediaTypes addObject:(NSString *)kUTTypeMovie];
            }
            self.mediaTypes = mediaTypes;
        }
    }
    return self;
}

- (BOOL)isPhotoLibraryAvailable {
    return [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary];
}

- (BOOL)canUserPickVideosFromPhotoLibrary {
    return supports((NSString *)kUTTypeMovie, UIImagePickerControllerSourceTypePhotoLibrary);
}

- (BOOL)canUserPickPhotosFromPhotoLibrary {
    return supports((NSString *)kUTTypeImage, UIImagePickerControllerSourceTypePhotoLibrary);
}

#pragma mark UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey, id> *)info {
    
}

@end
