//
//  ContactsTableViewController.m
//  Sechat
//
//  Created by Albert Moky on 2018/12/23.
//  Copyright © 2018 DIM Group. All rights reserved.
//

#import "NSNotificationCenter+Extension.h"
#import "UIStoryboardSegue+Extension.h"
#import "User.h"
#import "Facebook.h"
#import "Client.h"
#import "ContactCell.h"
#import "ProfileTableViewController.h"
#import "ContactsTableViewController.h"
#import "SearchUsersTableViewController.h"
#import "ChatViewController.h"

@interface ContactsTableViewController ()<UITableViewDelegate, UITableViewDataSource> {
    
    NSMutableDictionary<NSString *, NSMutableArray<DIMID *> *> *_contactsTable;
    NSMutableArray *_contactsKey;
}

@property(nonatomic, strong) UITableView *tableView;

@end

@implementation ContactsTableViewController

-(void)loadView{
    
    [super loadView];
    
    self.navigationItem.title = NSLocalizedString(@"Contacts", @"title");
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(didPressAddButton:)];
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    [self.tableView registerClass:[ContactCell class] forCellReuseIdentifier:@"ContactCell"];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.view addSubview:self.tableView];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _contactsTable = nil;
    _contactsKey = nil;
    [self reloadData];
    
    [NSNotificationCenter addObserver:self
                             selector:@selector(reloadData)
                                 name:kNotificationName_ContactsUpdated
                               object:nil];
}

-(void)viewWillAppear:(BOOL)animated{
    
    [super viewWillAppear:animated];
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAutomatic;
}

- (void)reloadData {
    _contactsTable = [[NSMutableDictionary alloc] init];
    
    Client *client = [Client sharedInstance];
    DIMLocalUser *user = client.currentUser;
    NSArray<DIMID *> *contacts = user.contacts;
    NSInteger count = [contacts count];
    
    NSMutableArray<DIMID *> *mArray;
    DIMID *contact;
    DIMProfile *profile;
    NSString *name;
    while (--count >= 0) {
        contact = [contacts objectAtIndex:count];
        profile = DIMProfileForID(contact);
        name = profile.name;
        if (name.length == 0) {
            name = contact.name;
            if (name.length == 0) {
                name = @"Đ"; // BTC Address: ฿
            }
        }
        name = [name substringToIndex:1];
        mArray = [_contactsTable objectForKey:name];
        if (!mArray) {
            mArray = [[NSMutableArray alloc] init];
            [_contactsTable setObject:mArray forKey:name];
        }
        [mArray addObject:contact];
    }
    _contactsKey = [[_contactsTable allKeys] mutableCopy];
    
    NSStringEncoding enc = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
    NSComparator cmp = ^NSComparisonResult(NSString *obj1, NSString *obj2) {
        const char *s1 = [obj1 cStringUsingEncoding:enc];
        const char *s2 = [obj2 cStringUsingEncoding:enc];
        return strcmp(s1, s2);
    };
    [_contactsKey sortUsingComparator:cmp];
    
    [self.tableView reloadData];
}

#pragma mark - Table delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 64;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    return _contactsKey.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    NSString *key = [_contactsKey objectAtIndex:section];
    NSArray *contacts = [_contactsTable objectForKey:key];
    return contacts.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    
    NSString *key = [_contactsKey objectAtIndex:section];
    return key;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    // Configure the cell...
    NSInteger section = indexPath.section;
    NSInteger row = indexPath.row;
    
    NSString *key = [_contactsKey objectAtIndex:section];
    NSArray *list = [_contactsTable objectForKey:key];
    DIMID *ID = [list objectAtIndex:row];
    
    ContactCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ContactCell" forIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.contact = ID;
    
    return cell;
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView beginUpdates];
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        NSInteger section = indexPath.section;
        NSInteger row = indexPath.row;
        
        NSString *key = [_contactsKey objectAtIndex:section];
        NSMutableArray *list = [_contactsTable objectForKey:key];
        DIMID *ID = [list objectAtIndex:row];
        
        Client *client = [Client sharedInstance];
        DIMLocalUser *user = client.currentUser;
        [[DIMFacebook sharedInstance] user:user removeContact:ID];
        
        //Post contacts to server
        NSArray<MKMID *> *allContacts = [[DIMFacebook sharedInstance] contactsOfUser:user.ID];
        [client postContacts:allContacts];
        
        [list removeObjectAtIndex:row];
        if (list.count == 0) {
            [_contactsKey removeObject:key];
            [_contactsTable removeObjectForKey:key];
            
            [tableView deleteSections:[NSIndexSet indexSetWithIndex:indexPath.section]
                     withRowAnimation:UITableViewRowAnimationFade];
        }
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }
    
    [tableView endUpdates];
}

#pragma mark - Navigation

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    ContactCell *selectedCell = [tableView cellForRowAtIndexPath:indexPath];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    ProfileTableViewController *controller = [[ProfileTableViewController alloc] init];
    controller.contact = selectedCell.contact;
    controller.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:controller animated:YES];
}

-(void)didPressSearchButton:(id)sender{
    
    SearchUsersTableViewController *controller = [[SearchUsersTableViewController alloc] init];
    controller.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:controller animated:YES];
}

-(void)didPressAddButton:(id)sender{
    
    SearchUsersTableViewController *controller = [[SearchUsersTableViewController alloc] init];
    controller.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:controller animated:YES];
}

@end
