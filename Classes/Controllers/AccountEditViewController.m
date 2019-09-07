//
//  AccountEditViewController.m
//  Sechat
//
//  Created by Albert Moky on 2019/2/1.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import <DIMClient/DIMClient.h>

#import "NSObject+JsON.h"
#import "NSData+Extension.h"
#import "NSNotificationCenter+Extension.h"

#import "UIViewController+Extension.h"
#import "UIView+Extension.h"
#import "UIImage+Extension.h"

#import "DIMProfile+Extension.h"

#import "ImagePickerController.h"

#import "User.h"
#import "Client.h"
#import "Facebook+Profile.h"
#import "Facebook+Register.h"
#import "dimMacros.h"
#import "AccountEditViewController.h"

@interface AccountEditViewController ()

@end

@implementation AccountEditViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    Client *client = [Client sharedInstance];
    DIMLocalUser *user = client.currentUser;
    DIMID *ID = user.ID;
    
    CGSize avatarSize = _avatarImageView.bounds.size;
    
    UIImage *image = [user.profile avatarImageWithSize:avatarSize];
    NSString *nickname = user.name;
    
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
    
    self.navigationItem.title = nickname;
}

- (void)onAvatarUpdated:(NSNotification *)notification {
    
    DIMProfile *profile = [notification.userInfo objectForKey:@"profile"];
    DIMLocalUser *user = [Client sharedInstance].currentUser;
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
            image = [image aspectFit:CGSizeMake(320, 320)];
            NSData *data = [image jpegDataWithQuality:UIImage_JPEGCompressionQuality_Photo];
            NSString *filename = [[[data md5] hexEncode] stringByAppendingPathExtension:@"jpeg"];
            NSLog(@"avatar data length: %lu, %lu", data.length, [image pngData].length);
            
            Client *client = [Client sharedInstance];
            DIMLocalUser *user = client.currentUser;
            DIMID *ID = user.ID;
            DIMProfile *profile = user.profile;
            if (!profile) {
                NSAssert(false, @"profile should not be empty");
                return ;
            }
            
            id<DIMUserDataSource> dataSource = user.dataSource;
            DIMPrivateKey *SK = [dataSource privateKeyForSignatureOfUser:user.ID];
            
            // save to local storage
            [[Facebook sharedInstance] saveAvatar:data name:filename forID:profile.ID];
            
            // upload to CDN
            DIMFileServer *ftp = [DIMFileServer sharedInstance];
            NSURL *url = [ftp uploadAvatar:data filename:filename sender:ID];
            
            // got avatar URL
            profile.avatar = [url absoluteString];
            [profile sign:SK];
            
            // save profile with new avatar
            [[DIMFacebook sharedInstance] saveProfile:profile];
            
            // submit to network
            [client postProfile:profile];
            
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
    DIMLocalUser *user = client.currentUser;
    
    id<DIMUserDataSource> dataSource = user.dataSource;
    DIMPrivateKey *SK = [dataSource privateKeyForSignatureOfUser:user.ID];
    
    DIMProfile *profile = user.profile;
    [profile setName:nickname];
    [profile sign:SK];
    
    [[DIMFacebook sharedInstance] saveProfile:profile];
    
    // submit to station
    [client postProfile:profile];
    // broadcast to all contacts
    [client broadcastProfile:profile];
    
    [NSNotificationCenter postNotificationName:kNotificationName_UsersUpdated object:self];
    return YES;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSInteger section = indexPath.section;
    NSInteger row = indexPath.row;
    NSLog(@"section: %ld, row: %ld", (long)section, (long)row);
    
    if (section == 0) {
        // avatar & nickname
    } else if (section == 1) {
        // profiles
    } else if (section == 2){
        // function
        if (row == 0) {
            // Save
            if ([self saveAndSubmit]) {
                // saved
                [self showMessage:NSLocalizedString(@"Success", nil)
                        withTitle:nil];
            }
        }
    } else if(section == 3){
        //Export Account
        Client *client = [Client sharedInstance];
        DIMLocalUser *user = client.currentUser;
        NSUInteger version = user.meta.version;
        
        DIMPrivateKey *key = [DIMPrivateKey loadKeyWithIdentifier:user.ID.address];
        [key setObject:user.ID.name forKey:@"username"];
        [key setObject:user.profile.name forKey:@"nickname"];
        [key setObject:[NSNumber numberWithUnsignedInteger:version] forKey:@"version"];
        NSLog(@"The private key is : %@", key);
        
        Class nativeJsonParser = NSClassFromString(@"NSJSONSerialization");
        NSData *jsonData = [nativeJsonParser dataWithJSONObject:key options:0 error:NULL];
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        
        //Copy to clipboard
        [[UIPasteboard generalPasteboard] setString:jsonString];
        
        [self showMessage:NSLocalizedString(@"Your account infomation has been saved to clipboard, please save it to Notes", nil)
                withTitle:NSLocalizedString(@"Success", @"title")];
    }
}

@end
