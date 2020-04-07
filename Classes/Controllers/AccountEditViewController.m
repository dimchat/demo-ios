//
//  AccountEditViewController.m
//  Sechat
//
//  Created by Albert Moky on 2019/2/1.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import <DIMClient/DIMClient.h>

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

@interface AccountEditViewController ()<UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UIDocumentPickerDelegate>

@property(nonatomic, strong) UITableView *tableView;
@property(nonatomic, strong) UIView *headerView;
@property (strong, nonatomic) UIImageView *avatarImageView;
@property (strong, nonatomic) UIButton *changeButton;
@property (strong, nonatomic) UILabel *avatarLabel;
@property (strong, nonatomic) UITextField *nicknameTextField;

@end

@implementation AccountEditViewController

-(void)loadView{
    
    [super loadView];
    
    self.view.backgroundColor = [UIColor colorNamed:@"ViewBackgroundColor"];
    
    CGFloat x = 0.0;
    CGFloat y = 0.0;
    CGFloat width = self.view.bounds.size.width;
    CGFloat height = 215.0;
    
    self.headerView = [[UIView alloc] initWithFrame:CGRectMake(x, y, width, height)];
    
    width = 120.0;
    height = 120.0;
    x = (self.view.bounds.size.width - width) / 2;
    y = 15.0;
    self.avatarImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"default_avatar"]];
    self.avatarImageView.frame = CGRectMake(x, y, width, height);
    self.avatarImageView.layer.cornerRadius = width / 2;
    self.avatarImageView.layer.masksToBounds = YES;
    [self.headerView addSubview:self.avatarImageView];
    
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
    [self.headerView addSubview:self.changeButton];
    
    width = self.view.bounds.size.width;
    height = 38.0;
    x = 0.0;
    y = self.avatarImageView.frame.origin.y + self.avatarImageView.frame.size.height + 13.0;
    self.nicknameTextField = [[UITextField alloc] initWithFrame:CGRectMake(x, y, width, height)];
    self.nicknameTextField.textAlignment = NSTextAlignmentCenter;
    self.nicknameTextField.font = [UIFont systemFontOfSize:34.0];
    self.nicknameTextField.returnKeyType = UIReturnKeyDone;
    self.nicknameTextField.delegate = self;
    [self.headerView addSubview:self.nicknameTextField];
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.tableHeaderView = self.headerView;
    [self.view addSubview:self.tableView];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    Client *client = [Client sharedInstance];
    DIMUser *user = client.currentUser;
    
    CGSize avatarSize = _avatarImageView.bounds.size;
    
    UIImage *image = [user.profile avatarImageWithSize:avatarSize];
    NSString *nickname = user.name;
    
    _avatarImageView.image = image;
    _nicknameTextField.text = nickname;
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(onAvatarUpdated:)
               name:kNotificationName_AvatarUpdated object:nil];
    
    self.navigationItem.title = nickname;
}

-(void)viewWillAppear:(BOOL)animated{
    
    [super viewWillAppear:animated];
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
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
        dispatch_async(dispatch_get_main_queue(), ^{
            [self->_avatarImageView setImage:image];
        });
    }
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
            [self handleAvatarImage:image];
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
    [self handleAvatarImage:image];
}

-(void)handleAvatarImage:(UIImage *)image{
    
    if (image) {
        // image file
        
        if(image.size.width > 320){
            image = [image aspectFit:CGSizeMake(320, 320)];
        }
        
        NSData *data = [image jpegDataWithQuality:UIImage_JPEGCompressionQuality_Photo];
        NSString *filename = [MKMHexEncode(MKMMD5Digest(data)) stringByAppendingPathExtension:@"jpeg"];
        NSLog(@"avatar data length: %lu, %lu", data.length, [image pngData].length);
        
        DIMFacebook *facebook = [DIMFacebook sharedInstance];
        Client *client = [Client sharedInstance];
        DIMUser *user = client.currentUser;
        DIMID *ID = user.ID;
        DIMProfile *profile = user.profile;
        if (!profile) {
            NSAssert(false, @"profile should not be empty");
            return ;
        }
        
        id<DIMUserDataSource> dataSource = user.dataSource;
        id<DIMSignKey> SK = [dataSource privateKeyForSignature:user.ID];
        
        // save to local storage
        [facebook saveAvatar:data name:filename forID:ID];
        
        // upload to CDN
        DIMFileServer *ftp = [DIMFileServer sharedInstance];
        NSURL *url = [ftp uploadAvatar:data filename:filename sender:ID];
        
        // got avatar URL
        profile.avatar = [url absoluteString];
        [profile sign:SK];
        
        // save profile with new avatar
        [facebook saveProfile:profile];
        
        // submit to network
        DIMMessenger *messenger = [DIMMessenger sharedInstance];
        [messenger postProfile:profile];
        
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc postNotificationName:kNotificationName_AvatarUpdated object:self
                        userInfo:@{@"ID": profile.ID, @"profile": profile}];
    }
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
    
    id<DIMUserDataSource> dataSource = user.dataSource;
    id<DIMSignKey> SK = [dataSource privateKeyForSignature:user.ID];
    
    DIMProfile *profile = user.profile;
    [profile setName:nickname];
    [profile sign:SK];
    
    [[DIMFacebook sharedInstance] saveProfile:profile];
    DIMMessenger *messenger = [DIMMessenger sharedInstance];
    
    // submit to station
    [messenger postProfile:profile];
    // broadcast to all contacts
    [messenger broadcastProfile:profile];
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:kNotificationName_AvatarUpdated
                      object:self userInfo:@{@"ID": user.ID}];
    return YES;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    Client *client = [Client sharedInstance];
    DIMUser *user = client.currentUser;
    DIMID *ID = user.ID;
    
    UITableViewCell *cell = nil;
    
    if(indexPath.section == 0){
        
        cell = [tableView dequeueReusableCellWithIdentifier:@"ProfileCell"];
        if(cell == nil){
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:@"ProfileCell"];
        }
        
        if(indexPath.row == 0){
            
            cell.textLabel.text = NSLocalizedString(@"Search NO.", @"title");
            cell.detailTextLabel.text = search_number(ID.number);
            
        } else if(indexPath.row == 1){
            
            cell.textLabel.text = NSLocalizedString(@"Address", @"title");
            cell.detailTextLabel.text = ID.address;
        }
        
    } else if(indexPath.section == 1){
        
        cell = [tableView dequeueReusableCellWithIdentifier:@"ActionCell"];
        if(cell == nil){
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"ActionCell"];
        }
        
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        
        if(indexPath.row == 0){
            cell.textLabel.text = NSLocalizedString(@"Save", @"title");
        } else if(indexPath.row == 1){
            cell.textLabel.text = NSLocalizedString(@"Export", @"title");
        }
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44.0;
}

- (BOOL)tableView:(UITableView *)tableView shouldShowMenuForRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

-(BOOL)tableView:(UITableView *)tableView canPerformAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
    return (action == @selector(copy:));
}

- (void)tableView:(UITableView *)tableView performAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
    
    if(action == @selector(copy:)){
        
        NSInteger section = indexPath.section;
        NSInteger row = indexPath.row;
        
        Client *client = [Client sharedInstance];
        DIMUser *user = client.currentUser;
        
        if(section == 0){

            if(row == 0){
                //Copy search number
                [[UIPasteboard generalPasteboard] setString:search_number(user.number)];
            } else if (row == 1){
                //Copy address
                [[UIPasteboard generalPasteboard] setString:user.ID.address];
            }
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSInteger section = indexPath.section;
    NSInteger row = indexPath.row;
    NSLog(@"section: %ld, row: %ld", (long)section, (long)row);
    
    Client *client = [Client sharedInstance];
    DIMUser *user = client.currentUser;
    
    if (section == 1){
        // function
        if (row == 0) {
            // Save
            if ([self saveAndSubmit]) {
                // saved
                [self showMessage:NSLocalizedString(@"Success", nil) withTitle:nil];
            }
        } else if(row == 1){
            //Export Account
            
            DIMPrivateKey *key = [DIMPrivateKey loadKeyWithIdentifier:user.ID.address];
            
            NSString *privateKeyString = key[@"data"];
            NSString *privateKey = RSAPrivateKeyContentFromNSString(privateKeyString);
            
            //Copy to clipboard
            [[UIPasteboard generalPasteboard] setString:privateKey];
            
            [self showMessage:NSLocalizedString(@"Your account infomation has been saved to clipboard, please save it to Notes", nil)
                    withTitle:NSLocalizedString(@"Success", @"title")];
        }
    }
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    
    [self.nicknameTextField resignFirstResponder];
    return YES;
}

@end
