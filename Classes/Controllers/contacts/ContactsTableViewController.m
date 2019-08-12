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
#import "Facebook+Relationship.h"

#import "Client.h"

#import "ContactCell.h"

#import "ProfileTableViewController.h"

#import "ContactsTableViewController.h"

static inline void sort_array(NSMutableArray *array) {
    NSStringEncoding enc = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
    NSComparator cmp = ^NSComparisonResult(NSString *obj1, NSString *obj2) {
        const char *s1 = [obj1 cStringUsingEncoding:enc];
        const char *s2 = [obj2 cStringUsingEncoding:enc];
        return strcmp(s1, s2);
    };
    [array sortUsingComparator:cmp];
}

@interface ContactsTableViewController () {
    
    NSMutableDictionary<NSString *, NSMutableArray<DIMID *> *> *_contactsTable;
    NSMutableArray *_contactsKey;
}

@end

@implementation ContactsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    _contactsTable = nil;
    _contactsKey = nil;
    [self reloadData];
    
    [NSNotificationCenter addObserver:self
                             selector:@selector(reloadData)
                                 name:kNotificationName_ContactsUpdated
                               object:nil];
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
    sort_array(_contactsKey);
    
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
    
    DIMUser *contact = DIMUserWithID(ID);
    
    ContactCell *cell = [tableView dequeueReusableCellWithIdentifier:@"contactCell" forIndexPath:indexPath];
    cell.contact = contact;
    
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
        Facebook *facebook = [Facebook sharedInstance];
        [facebook user:user removeContact:ID];
        
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

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    if ([segue.identifier isEqualToString:@"profileSegue"]) {
        ContactCell *cell = sender;
        
        ProfileTableViewController *vc = [segue visibleDestinationViewController];
        vc.contact = cell.contact;
    }
    
}

@end
