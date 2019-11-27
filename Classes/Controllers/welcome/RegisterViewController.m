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
#import "WebViewController.h"
#import "RegisterViewController.h"
#import "ImportAccountViewController.h"

@interface RegisterViewController ()<UITextFieldDelegate, UIDocumentPickerDelegate>

@property (strong, nonatomic) DIMPrivateKey *SK;
@property (strong, nonatomic) DIMMeta *meta;
@property (strong, nonatomic) DIMID *ID;

@property (strong, nonatomic) UIButton *changeButton;
@property (strong, nonatomic) UILabel *avatarLabel;
@property (strong, nonatomic) UIImageView *avatarImageView;
@property (strong, nonatomic) UITextField *nicknameTextField;
@property (strong, nonatomic) UIButton *importButton;
@property (strong, nonatomic) NSData *imageData;

@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) NSString *nickname;

@end

@implementation RegisterViewController

-(void)loadView{
    
    [super loadView];
    
    self.navigationItem.title = NSLocalizedString(@"Register", @"title");
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Next", @"title") style:UIBarButtonItemStylePlain target:self action:@selector(didPressStartButton:)];
    self.view.backgroundColor = [UIColor colorNamed:@"ViewBackgroundColor"];
    
    CGFloat width = 120.0;
    CGFloat height = 120.0;
    CGFloat y = 128.0;
    
    if([UIScreen mainScreen].bounds.size.width == 320.0){
        y = 64.0;
        width = 80.0;
        height = 80.0;
    }
    
    CGFloat x = (self.view.bounds.size.width - width) / 2.0;
    
    self.avatarImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"default_avatar"]];
    self.avatarImageView.frame = CGRectMake(x, y, width, height);
    self.avatarImageView.backgroundColor = [UIColor lightGrayColor];
    self.avatarImageView.layer.cornerRadius = width / 2;
    self.avatarImageView.layer.masksToBounds = YES;
    [self.view addSubview:self.avatarImageView];
    
    height = 24.0;
    x = 0.0;
    y = self.avatarImageView.bounds.size.height - height;
    
    self.avatarLabel = [[UILabel alloc] initWithFrame:CGRectMake(x, y, width, height)];
    self.avatarLabel.backgroundColor = [UIColor blackColor];
    self.avatarLabel.text = NSLocalizedString(@"Edit", @"title");
    self.avatarLabel.font = [UIFont systemFontOfSize:14.0];
    self.avatarLabel.textColor = [UIColor whiteColor];
    self.avatarLabel.textAlignment = NSTextAlignmentCenter;
    [self.avatarImageView addSubview:self.avatarLabel];
    
    self.changeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.changeButton.frame = self.avatarImageView.frame;
    [self.changeButton addTarget:self action:@selector(changeAvatar:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.changeButton];
    
    y = self.avatarImageView.frame.origin.y + self.avatarImageView.frame.size.height + 20.0;
    x = 35.0;
    width = self.view.bounds.size.width - x * 2.0;
    height = 0.5;
    
    UIView *seperator = [[UIView alloc] initWithFrame:CGRectMake(x, y, width, height)];
    seperator.backgroundColor = [UIColor lightGrayColor];
    [self.view addSubview:seperator];
    
    height = 44.0;
    width = 100.0;
    UILabel *nicknameLabel = [[UILabel alloc] initWithFrame:CGRectMake(x, y, width, height)];
    nicknameLabel.text = NSLocalizedString(@"Nickname", @"title");
    [self.view addSubview:nicknameLabel];
    
    x = nicknameLabel.frame.origin.x + width + 10.0;
    width = seperator.frame.origin.x + seperator.frame.size.width - x;
    self.nicknameTextField = [[UITextField alloc] initWithFrame:CGRectMake(x, y, width, height)];
    self.nicknameTextField.placeholder = NSLocalizedString(@"e.g moky", @"title");
    self.nicknameTextField.delegate = self;
    self.nicknameTextField.returnKeyType = UIReturnKeyDone;
    [self.view addSubview:self.nicknameTextField];
    
    y = nicknameLabel.frame.origin.y + nicknameLabel.frame.size.height;
    x = 35.0;
    width = self.view.bounds.size.width - x * 2.0;
    height = 0.5;
    
    seperator = [[UIView alloc] initWithFrame:CGRectMake(x, y, width, height)];
    seperator.backgroundColor = [UIColor lightGrayColor];
    [self.view addSubview:seperator];
    
    y = seperator.frame.origin.y;
    height = 44.0;
    self.importButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.importButton.frame = CGRectMake(x, y, width, height);
    [self.importButton setTitle:NSLocalizedString(@"Import Existing Account", @"title") forState:UIControlStateNormal];
    [self.importButton addTarget:self action:@selector(importAccount:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.importButton];
    
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

-(void)viewDidAppear:(BOOL)animated{
    
    [super viewDidAppear:animated];
    [self.nicknameTextField becomeFirstResponder];
}

- (void)changeAvatar:(id)sender {
    
    if([[UIDevice currentDevice].systemName hasPrefix:@"Mac"]){
        
        UIDocumentPickerViewController *picController = [[UIDocumentPickerViewController alloc] initWithDocumentTypes:@[@"public.image"] inMode:UIDocumentPickerModeOpen];
        picController.delegate = self;
        [self presentViewController:picController animated:YES completion:nil];
        
    } else {
        
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
                self.imageData = data;
                self.avatarImageView.image = image;
            }
        };
        
        AlbumController *album = [[AlbumController alloc] init];
        album.allowsEditing = YES;
        [album showWithViewController:self completionHandler:handler];
    }
}

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls{
    
    NSLog(@"The urls is %@", urls);
    
    if(urls.count == 0){
        return;
    }
    
    NSURL *url = [urls objectAtIndex:0];
    UIImage *image = [[UIImage alloc] initWithContentsOfFile:[url path]];
    
    if(image.size.width > 320.0){
        image = [image aspectFit:CGSizeMake(320.0, 320.0)];
    }
    
    NSData *data = [image jpegDataWithQuality:UIImage_JPEGCompressionQuality_Photo];
    self.imageData = data;
    self.avatarImageView.image = image;
}

-(NSError *)saveAndSubmit {
    
    Client *client = [Client sharedInstance];
    DIMUser *user = client.currentUser;
    DIMID *ID = user.ID;
    
    id<DIMUserDataSource> dataSource = user.dataSource;
    DIMPrivateKey *SK = [dataSource privateKeyForSignatureOfUser:user.ID];
    
    DIMProfile *profile = user.profile;
    
    if(self.imageData != nil){
        
        NSString *filename = [[[self.imageData md5] hexEncode] stringByAppendingPathExtension:@"jpeg"];
        
        // save to local storage
        [[Facebook sharedInstance] saveAvatar:self.imageData name:filename forID:profile.ID];
        
        // upload to CDN
        DIMFileServer *ftp = [DIMFileServer sharedInstance];
        NSURL *url = [ftp uploadAvatar:self.imageData filename:filename sender:ID];
        
        // got avatar URL
        profile.avatar = [url absoluteString];
    }
    
    [profile setName:self.nickname];
    [profile sign:SK];
    
    [[DIMFacebook sharedInstance] saveProfile:profile];
    
    // submit to station
    [client postProfile:profile];
    
    return nil;
}

-(NSError *)generate{
    NSLog(@"refreshing...");
    
    NSString *username = @"dim";
    
    // 1. generate private key
    self.SK = MKMPrivateKeyWithAlgorithm(ACAlgorithmRSA);
    
    if(self.SK == nil){
        return [NSError errorWithDomain:@"chat.dim" code:1 userInfo:@{NSLocalizedDescriptionKey: @"Can not generate private key"}];
    }
    
    // 2. generate meta
    self.meta = MKMMetaGenerate(MKMMetaDefaultVersion, _SK, username);
    
    if(self.meta == nil){
        return [NSError errorWithDomain:@"chat.dim" code:1 userInfo:@{NSLocalizedDescriptionKey: @"Can not generate meta"}];
    }
    
    // 3. generate ID
    self.ID = [self.meta generateID:MKMNetwork_Main];
    
    if(self.ID == nil){
        return [NSError errorWithDomain:@"chat.dim" code:1 userInfo:@{NSLocalizedDescriptionKey: @"Can not generate ID"}];
    }
    
    Client *client = [Client sharedInstance];
    if(![client saveUser:self.ID meta:self.meta privateKey:self.SK name:self.nickname]){
        return [NSError errorWithDomain:@"chat.dim" code:1 userInfo:@{NSLocalizedDescriptionKey: @"Can not save user to client"}];
    }
    
    return nil;
}

-(void)didPressStartButton:(id)sender{
    
    NSString *nickname = self.nicknameTextField.text;
    
    if(nickname == nil || nickname.length == 0){
        NSString *message = @"Please Input your nickname";
        NSString *title = @"Dim!";
        [self showMessage:NSLocalizedString(message, nil)
                withTitle:NSLocalizedString(title, nil)];
        return;
    }
    
    self.nickname = nickname;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.activityIndicator];
    self.navigationController.navigationBar.userInteractionEnabled = NO;
    [self.activityIndicator startAnimating];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
    
        NSError *error = [self generate];
        
        if(error != nil){
            [self showError:error];
            [self restoreUI];
            return;
        }
        
        error = [self saveAndSubmit];
        if(error != nil){
            [self showError:error];
            [self restoreUI];
            return;
        }
        
        Client *client = [Client sharedInstance];
        //New User add Moky as contact
        NSString *itemString = @"baloo@4LA5FNbpxP38UresZVpfWroC2GVomDDZ7q";
        [client addUserToContact:itemString];
        
        itemString = @"dim@4TM96qQmGx1UuGtwkdyJAXbZVXufFeT1Xf";
        [client addUserToContact:itemString];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.navigationController dismissViewControllerAnimated:YES completion:nil];
        });
    });
}

-(void)restoreUI{
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Next", @"title") style:UIBarButtonItemStylePlain target:self action:@selector(didPressStartButton:)];
    self.navigationController.navigationBar.userInteractionEnabled = YES;
}

-(void)importAccount:(id)sender{
    
    ImportAccountViewController *vc = [[ImportAccountViewController alloc] initWithNibName:@"ImportAccountViewController" bundle:nil];
    [self.navigationController pushViewController:vc animated:YES];
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    
    [self.nicknameTextField resignFirstResponder];
    
    return YES;
}

@end
