//
//  AccountEditViewController.m
//  Sechat
//
//  Created by Albert Moky on 2019/2/1.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import <DIMCore/DIMCore.h>

#import "NSObject+JsON.h"
#import "NSData+Crypto.h"
#import "NSNotificationCenter+Extension.h"

#import "UIViewController+Extension.h"
#import "UIView+Extension.h"
#import "UIImage+Extension.h"

#import "DIMProfile+Extension.h"

#import "ImagePickerController.h"

#import "User.h"
#import "Client.h"
#import "Facebook+Register.h"

#import "AccountEditViewController.h"

@interface AccountEditViewController ()

@end

@implementation AccountEditViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    Client *client = [Client sharedInstance];
    DIMUser *user = client.currentUser;
    const DIMID *ID = user.ID;
    
    DIMProfile *profile = DIMProfileForID(ID);
    
    CGSize avatarSize = _avatarImageView.bounds.size;
    
    UIImage *image = [profile avatarImageWithSize:avatarSize];
    NSString *nickname = profile.name;
    
    [_avatarImageView roundedCorner];
    _avatarImageView.image = image;
    
    [_changeButton addTarget:self action:@selector(changeAvatar:) forControlEvents:UIControlEventTouchUpInside];
    
    _nicknameTextField.text = nickname;
    _usernameLabel.text = ID.name;
    _addressLabel.text = (NSString *)ID.address;
    _numberLabel.text = search_number(ID.number);
    
    [NSNotificationCenter addObserver:self
                             selector:@selector(onAvatarUpdated:)
                                 name:kNotificationName_AvatarUpdated
                               object:nil];
}

- (void)onAvatarUpdated:(NSNotification *)notification {
    
    DIMProfile *profile = [notification.userInfo objectForKey:@"profile"];
    DIMUser *user = [Client sharedInstance].currentUser;
    if (![profile.ID isEqual:user.ID]) {
        // not my profile
        return ;
    }
    
    // avatar
    CGRect avatarFrame = _avatarImageView.frame;
    UIImage *image = [profile avatarImageWithSize:avatarFrame.size];
    if (image) {
        [_avatarImageView setImage:image];
    }
}

- (void)changeAvatar:(id)sender {
    
    ImagePickerControllerCompletionHandler handler;
    handler = ^(UIImage * _Nullable image,
                NSString *path,
                NSDictionary<UIImagePickerControllerInfoKey,id> *info,
                UIImagePickerController *ipc) {
        
        NSLog(@"pick image: %@, path: %@", image, path);
        if (image) {
            // image file
            NSData *data = [image jpegDataWithQuality:UIImage_JPEGCompressionQuality_Photo];
            NSString *filename = [[[data md5] hexEncode] stringByAppendingPathExtension:@"jpeg"];
            NSLog(@"avatar data length: %lu, %lu", data.length, [image pngData].length);
            
            Client *client = [Client sharedInstance];
            DIMUser *user = client.currentUser;
            const DIMID *ID = user.ID;
            DIMProfile *profile = DIMProfileForID(ID);
            if (!profile) {
                NSAssert(false, @"profile should not be empty");
                return ;
            }
            
            // save to local storage
            Facebook *facebook = [Facebook sharedInstance];
            [facebook saveAvatar:data name:filename forID:profile.ID];
            
            // upload to CDN
            DIMFileServer *ftp = [DIMFileServer sharedInstance];
            NSURL *url = [ftp uploadAvatar:data filename:filename sender:ID];
            
            // got avatar URL
            profile.avatar = [url absoluteString];
            
            // save profile with new avatar
            [facebook saveProfile:profile forID:ID];
            
            // submit to network
            [client postProfile:profile meta:nil];
            
            [NSNotificationCenter postNotificationName:kNotificationName_AvatarUpdated
                                                object:self
                                              userInfo:@{@"ID": profile.ID, @"profile": profile}];
        }
    };
    
    AlbumController *album = [[AlbumController alloc] init];
    album.allowsEditing = YES;
    [album showWithViewController:self completionHandler:handler];
}

- (BOOL)saveAndSubmit {
    
    NSString *nickname = _nicknameTextField.text;
    
    // check nickname
    if (nickname.length == 0) {
        [self showMessage:NSLocalizedString(@"Nickname cannot be empty.", nil)
                withTitle:NSLocalizedString(@"Nickname Error!", nil)];
        [_nicknameTextField becomeFirstResponder];
        return NO;
    }
    
    Client *client = [Client sharedInstance];
    DIMUser *user = client.currentUser;
    const DIMID *ID = user.ID;
    
    DIMProfile *profile = DIMProfileForID(ID);
    [profile setName:nickname];
    
    Facebook *facebook = [Facebook sharedInstance];
    [facebook saveProfile:profile forID:ID];
    
    // submit to station
    [client postProfile:profile meta:nil];
    
    return YES;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSInteger section = indexPath.section;
    NSInteger row = indexPath.row;
    NSLog(@"section: %ld, row: %ld", (long)section, (long)row);
    
    if (section == 0) {
        // avatar & nickname
    } else if (section == 1) {
        // profiles
    } else {
        // function
        if (row == 0) {
            // Save
            if ([self saveAndSubmit]) {
                // saved
                [self showMessage:NSLocalizedString(@"Success", nil)
                        withTitle:nil];
            }
        }
    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
