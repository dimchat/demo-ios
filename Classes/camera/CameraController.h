//
//  CameraController.h
//  Sechat
//
//  Created by Albert Moky on 2019/4/2.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^ImagePickerControllerCompletionHandler)(UIImage * _Nullable image,
                                                      NSString *path,
                                                      NSDictionary<UIImagePickerControllerInfoKey, id> *info,
                                                      UIImagePickerController *ipc);

@interface ImagePickerController : UIImagePickerController <UIImagePickerControllerDelegate, UINavigationControllerDelegate> {
    
    ImagePickerControllerCompletionHandler _completionHandler;
}

@property (nonatomic) ImagePickerControllerCompletionHandler completionHandler;

- (void)showWithViewController:(UIViewController *)vc
             completionHandler:(ImagePickerControllerCompletionHandler _Nullable)completion;

@end

@interface CameraController : ImagePickerController

@property (readonly, nonatomic, getter=isCameraAvailable) BOOL cameraAvailable;
@property (readonly, nonatomic, getter=isRearCameraAvailable) BOOL rearCameraAvailable;
@property (readonly, nonatomic, getter=isFrontCameraAvailable) BOOL frontCameraAvailable;

@property (readonly, nonatomic, getter=doesCameraSupportShootingVideos) BOOL cameraSupportShootingVideos;
@property (readonly, nonatomic, getter=doesCameraSupportTakingPhotos) BOOL cameraSupportTakingPhotos;

@end

@interface AlbumController : ImagePickerController

@property (readonly, nonatomic, getter=isPhotoLibraryAvailable) BOOL photoLibraryAvailable;
@property (readonly, nonatomic, getter=canUserPickVideosFromPhotoLibrary) BOOL userPickVideosFromPhotoLibrary;
@property (readonly, nonatomic, getter=canUserPickPhotosFromPhotoLibrary) BOOL userPickPhotosFromPhotoLibrary;

@end

NS_ASSUME_NONNULL_END
