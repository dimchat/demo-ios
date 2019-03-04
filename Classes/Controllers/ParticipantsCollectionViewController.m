//
//  ParticipantsCollectionViewController.m
//  Sechat
//
//  Created by Albert Moky on 2019/3/2.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "ParticipantsCollectionViewController.h"

@interface ParticipantsCollectionViewController () {
    
    NSMutableArray *_participants;
}

@end

@implementation ParticipantsCollectionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Register cell classes
//    [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:reuseIdentifier];
    
    // Do any additional setup after loading the view.
    
    _participants = [[NSMutableArray alloc] init];
    
    if (MKMNetwork_IsCommunicator(_conversation.ID.type)) {
        // personal conversation
        [_participants addObject:_conversation.ID];
    } else if (MKMNetwork_IsGroup(_conversation.ID.type)) {
        // group conversation
        DIMGroup *group = MKMGroupWithID(_conversation.ID);
        NSArray *members = group.members;
        [_participants addObjectsFromArray:members];
    }
}

- (NSInteger)numberOfParticipants {
    return _participants.count;
}

- (DIMID *)participantsAtIndex:(NSInteger)index {
    return [_participants objectAtIndex:index];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self numberOfParticipants] + 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = nil;
    
    // Configure the cell
    NSInteger count = [self numberOfParticipants];
    NSInteger row = indexPath.row;
    if (row >= count) {
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"MoreCell" forIndexPath:indexPath];
        return cell;
    }
    
    cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"ParticipantCell" forIndexPath:indexPath];
    DIMID *ID = [self participantsAtIndex:row];
    
    DIMProfile *profile = MKMProfileForID(ID);
    
    // avatar
    UIImage *image = [profile avatarImageWithSize:cell.contentView.bounds.size];
    if (!image) {
        image = [UIImage imageNamed:@"AppIcon"];
    }
    UIImageView *imageView = cell.contentView.subviews.firstObject;
    [imageView setImage:image];
    
    // name
    NSString *name = profile.name;
    if (!name) {
        name = _conversation.ID.name;
    }
    UILabel *label = cell.contentView.subviews.lastObject;
    label.text = name;
    
    return cell;
}

#pragma mark <UICollectionViewDelegate>

/*
// Uncomment this method to specify if the specified item should be highlighted during tracking
- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}
*/

/*
// Uncomment this method to specify if the specified item should be selected
- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}
*/

/*
// Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
- (BOOL)collectionView:(UICollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath {
	return NO;
}

- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	return NO;
}

- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	
}
*/

@end
