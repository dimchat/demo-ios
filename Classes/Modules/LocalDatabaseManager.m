//
//  LocalDatabaseManager.m
//  TimeFriend
//
//  Created by 陈均卓 on 2019/5/18.
//  Copyright © 2019 John Chen. All rights reserved.
//

#import "LocalDatabaseManager.h"
#import "FolderUtility.h"
#import "FMDB.h"

@interface LocalDatabaseManager()

@property(nonatomic, strong) FMDatabase *db;

@end

@implementation LocalDatabaseManager

+ (instancetype)sharedInstance {
    
    static LocalDatabaseManager *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[self alloc] init];
    });
    
    return _sharedInstance;
}

-(id)init{
    
    if(self = [super init]){
        
        NSString *documentPath = [[FolderUtility sharedInstance] applicationDocumentsDirectory];
        NSString *path = [documentPath stringByAppendingPathComponent:@"sechat.db"];
        NSLog(@"The database path is : %@", path);
        self.db = [FMDatabase databaseWithPath:path];
    }
    
    return self;
}

-(void)createTables{
    
    [self.db open];
    NSString *sql = @"CREATE TABLE IF NOT EXISTS messages (id integer primary key autoincrement, conversation_id text, sn integer, type integer, msg_text text, content text, sender text, receiver text, time integer, status integer);";
    BOOL success = [self.db executeStatements:sql];
    
    if(!success){
        NSLog(@"Can not create daily messages table");
    }
    
    [self.db close];
}

-(void)insertMessage:(DIMInstantMessage *)msg{
    
    [self.db open];
    
    
    
    [self.db close];
}

@end
