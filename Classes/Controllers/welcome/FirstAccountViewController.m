//
//  FirstAccountViewController.m
//  Sechat
//
//  Created by Albert Moky on 2019/4/9.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "UIColor+Extension.h"
#import "UIImage+Extension.h"
#import "UIView+Extension.h"
#import "UIImageView+Extension.h"
#import "UIViewController+Extension.h"
#import "NSData+Crypto.h"
#import "NSData+Extension.h"

#import "DIMProfile+Extension.h"
#import "NSNotificationCenter+Extension.h"
#import "ImagePickerController.h"
#import "User.h"
#import "Client.h"
#import "Facebook+Register.h"
#import "Facebook+Profile.h"

#import "FirstAccountViewController.h"

@interface FirstAccountViewController ()

@property (strong, nonatomic) DIMPrivateKey *SK;
@property (strong, nonatomic) DIMMeta *meta;
@property (strong, nonatomic) DIMID *ID;
@property (weak, nonatomic) IBOutlet UIButton *changeButton;
@property (weak, nonatomic) IBOutlet UILabel *avatarLabel;

@end

@implementation FirstAccountViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    if (_nickname.length > 0) {
        self.title = _nickname;
        CGSize size = _avatarImageView.frame.size;
        NSString *text = [_nickname substringToIndex:1];
        UIColor *textColor = [UIColor whiteColor];
        UIImage *bgImage = [UIImage imageNamed:@"avatar-bg"];
        if (bgImage) {
            _avatarImageView.image = [UIImage imageWithText:text size:size color:textColor backgroundImage:bgImage];
        } else {
            UIColor *bgColor = [UIColor colorWithHexString:@"1F1F0A"];
            _avatarImageView.image = [UIImage imageWithText:text size:size color:textColor backgroundColor:bgColor];
        }
    }
    [_avatarImageView roundedCorner];
    
    self.avatarLabel.layer.cornerRadius = 10;
    self.avatarLabel.layer.masksToBounds = YES;
    
    //[_refreshButton roundedCorner];
    //[_startButton roundedCorner];
    
    [self.changeButton addTarget:self action:@selector(changeAvatar:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addClickTarget:self action:@selector(onBackgroundClick:)];
    [NSNotificationCenter addObserver:self selector:@selector(onAvatarUpdated:) name:kNotificationName_AvatarUpdated object:nil];
    
    [self _generate];
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
    
    NSString *nickname = _usernameTextField.text;
    
    // check nickname
    if (nickname.length == 0) {
        [self showMessage:NSLocalizedString(@"Nickname cannot be empty.", nil)
                withTitle:NSLocalizedString(@"Nickname Error!", nil)];
        [_usernameTextField becomeFirstResponder];
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
    [client postProfile:profile meta:nil];
    
    return YES;
}

- (void)onBackgroundClick:(id)sender {
    
    [_usernameTextField resignFirstResponder];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    CGRect rect = _scrollView.frame;
    UIEdgeInsets insets = _scrollView.adjustedContentInset;
    
    CGSize vSize = CGSizeMake(rect.size.width - insets.left - insets.right,
                              rect.size.height - insets.top - insets.bottom);
    
    CGSize size = CGSizeMake(320, MAX(vSize.height, 520));
    
    _trayView.frame = CGRectMake((vSize.width - size.width) * 0.5, 0,
                                 size.width, size.height);
    _scrollView.frame = CGRectMake(0, 0,
                                   rect.origin.x + rect.size.width,
                                   rect.origin.y + rect.size.height);
    _scrollView.contentSize = CGSizeMake(size.width, size.height);
}

- (BOOL)_generate {
    NSLog(@"refreshing...");
    
    // clear
    _addressLabel.text = @"";
    _numberLabel.text = @"";
    
    _SK = nil;
    _meta = nil;
    _ID = nil;
    
    NSString *username = @"dim";
    
    if(_usernameTextField.text == nil || _usernameTextField.text.length == 0){
        self.nickname = @"dim_user";
    }else{
        self.nickname = _usernameTextField.text;
    }
    
    // check username
    if (username.length == 0) {
        NSString *message = @"Username cannot be empty.";
        NSString *title = @"Username Error!";
        [self showMessage:NSLocalizedString(message, nil)
                withTitle:NSLocalizedString(title, nil)];
        [_usernameTextField becomeFirstResponder];
        return NO;
    } else if (!check_username(username)) {
        NSString *message = @"Username must be composed of letters, digits, underscores, or hyphens.";
        NSString *title = @"Username Error!";
        [self showMessage:NSLocalizedString(message, nil)
                withTitle:NSLocalizedString(title, nil)];
        [_usernameTextField becomeFirstResponder];
        return NO;
    }
    
    // 1. generate private key
    _SK = MKMPrivateKeyWithAlgorithm(ACAlgorithmRSA);
    // 2. generate meta
    _meta = MKMMetaGenerate(MKMMetaDefaultVersion, _SK, username);
    // 3. generate ID
    _ID = [_meta generateID:MKMNetwork_Main];
    
    _addressLabel.text = (NSString *)_ID.address;
    _numberLabel.text = search_number(_ID.number);
    
    if(_ID != nil && _meta != nil && _SK != nil){
        Client *client = [Client sharedInstance];
        [client saveUser:_ID meta:_meta privateKey:_SK name:self.nickname];
    }
    
    return YES;
}

- (IBAction)onUsernameEditExit:(UITextField *)sender {
    
    [_usernameTextField resignFirstResponder];
}

- (IBAction)onUsernameEditEnd:(UITextField *)sender {
    
    //[self _generate];
}

- (IBAction)onRefreshClick:(UIButton *)sender {
    
    //[self _generate];
}

- (IBAction)onStartClick:(UIButton *)sender {
    NSLog(@"start chat");
    
    if(_usernameTextField.text == nil || _usernameTextField.text.length == 0){
        NSString *message = @"Please Input your nickname";
        NSString *title = @"Error!";
        [self showMessage:NSLocalizedString(message, nil)
                withTitle:NSLocalizedString(title, nil)];
        return;
    }
    self.nickname = _usernameTextField.text;
    
    if (_SK == nil || _meta == nil || _ID == nil) {
        
        if (![self _generate]) {
            // username error
            return ;
        }
        
        // check again
        if (_SK == nil || _meta == nil || _ID == nil) {
            NSString *message = @"Generate account failed.";
            NSString *title = @"Error!";
            [self showMessage:NSLocalizedString(message, nil)
                    withTitle:NSLocalizedString(title, nil)];
            [_usernameTextField becomeFirstResponder];
            return ;
        }
    }
    
    DIMPrivateKey *SK = _SK;
    DIMMeta *meta = _meta;
    const DIMID *ID = _ID;
    
    DIMProfile *profile = DIMProfileForID(ID);
    if(profile.avatar == nil || profile.avatar.length == 0){
        NSString *message = @"Please choose your avatar";
        NSString *title = @"Error!";
        [self showMessage:NSLocalizedString(message, nil)
                withTitle:NSLocalizedString(title, nil)];
        return;
    }
    
    NSString *nickname = _nickname;
    
    void (^handler)(UIAlertAction *);
    handler = ^(UIAlertAction *action) {
        
        if (![self saveAndSubmit]) {
            [self showMessage:NSLocalizedString(@"Failed to create user.", nil)
                    withTitle:NSLocalizedString(@"Error!", nil)];
            return ;
        }
        
        // dismiss the welcome page
        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    };
    
    NSString *message = [NSString stringWithFormat:@"%@ (%@)", _nickname, search_number(_ID.number)];
    [self showMessage:message
            withTitle:NSLocalizedString(@"New Account", nil)
        cancelHandler:nil
         cancelButton:NSLocalizedString(@"Cancel", nil)
       defaultHandler:handler
        defaultButton:NSLocalizedString(@"OK", nil)];
}

@end
