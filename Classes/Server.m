//
//  Server.m
//  Sechat
//
//  Created by Albert Moky on 2019/4/3.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "FileTransporter.h"

#import "Server.h"

@implementation Server

#pragma mark DKDTransceiverDelegate

- (NSURL *)uploadEncryptedFileData:(const NSData *)CT
                          filename:(nullable const NSString *)name
                            sender:(const MKMID *)ID {
    
    FileTransporter *ftp = [FileTransporter sharedInstance];
    return [ftp uploadData:CT filename:name sender:ID];
}

- (nullable NSData *)downloadEncryptedFileDataFromURL:(const NSURL *)url
                                             filename:(nullable const NSString *)name
                                               sender:(const MKMID *)ID {
    
    FileTransporter *ftp = [FileTransporter sharedInstance];
    return [ftp downloadDataFromURL:url filename:name sender:ID];
}

@end
