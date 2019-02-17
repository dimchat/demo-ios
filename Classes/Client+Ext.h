//
//  Client+Ext.h
//  DIM
//
//  Created by Albert Moky on 2019/1/28.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import <DIMCore/DIMCore.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark -

NSString *document_directory(void);

void make_dirs(NSString *dir);

BOOL file_exists(NSString *path);

NS_ASSUME_NONNULL_END
