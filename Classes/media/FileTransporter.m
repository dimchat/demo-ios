//
//  FileTransporter.m
//  Sechat
//
//  Created by Albert Moky on 2019/4/2.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "NSObject+Singleton.h"
#import "NSObject+JsON.h"
#import "NSData+Crypto.h"

#import "Client.h"

#import "FileTransporter.h"

/**
 Get full filepath to Documents Directory
 
 @param ID - account ID
 @param filename - "xxxx.png"
 @return "Documents/.dim/{address}/xxxx.png"
 */
static inline NSString *full_filepath(const DIMID *ID, NSString *filename) {
    assert(ID.isValid);
    // base directory: Documents/.dim/{address}
    NSString *dir = document_directory();
    dir = [dir stringByAppendingPathComponent:@".dim"];
    const DIMAddress *addr = ID.address;
    if (addr) {
        dir = [dir stringByAppendingPathComponent:(NSString *)addr];
    }
    
    // check base directory exists
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:dir isDirectory:nil]) {
        NSError *error = nil;
        // make sure directory exists
        [fm createDirectoryAtPath:dir withIntermediateDirectories:YES
                       attributes:nil error:&error];
        assert(!error);
    }
    
    // build filepath
    return [dir stringByAppendingPathComponent:filename];
}

@interface FileTransporter () {
    
    NSString *_baseURL;
    
    NSMutableDictionary *_uploadings;
    NSMutableDictionary *_downloadings;
}

@property (strong, nonatomic) NSURLSession *session;

@end

@implementation FileTransporter

SingletonImplementations(FileTransporter, sharedInstance)

- (instancetype)init {
    if (self = [super init]) {
        _baseURL = @"http://0.0.0.0:8081";
        
        _uploadings = [[NSMutableDictionary alloc] init];
        _downloadings = [[NSMutableDictionary alloc] init];
    }
    return self;
}

#pragma mark - NSURLSessionTaskDelegate

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
                                didSendBodyData:(int64_t)bytesSent
                                 totalBytesSent:(int64_t)totalBytesSent
                       totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend {
    
    float progress = (float)totalBytesSent / totalBytesExpectedToSend;
    NSLog(@"progress %f", progress);
    
    // finished
    if (totalBytesSent == totalBytesExpectedToSend) {
    }
}

#pragma mark NSURLSession

- (NSURLSession *)session {
    if (!_session) {
        Client *client = [Client sharedInstance];
        
        NSURLSessionConfiguration *config;
        config = [NSURLSessionConfiguration defaultSessionConfiguration];
        config.timeoutIntervalForRequest = 5.0f;
        config.requestCachePolicy = NSURLRequestUseProtocolCachePolicy;
        config.HTTPAdditionalHeaders = @{@"User-Agent": client.userAgent};
        
        NSOperationQueue *queue = [[NSOperationQueue alloc] init];
        _session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:queue];
    }
    return _session;
}

- (NSData *)buildHTTPBodyWithFilename:(NSString *)name data:(NSData *)data {
    
    NSMutableString *begin = [[NSMutableString alloc] init];
    [begin appendString:@"--4Tcjm5mp8BNiQN5YnxAAAnexqnbb3MrWjK\r\n"];
    [begin appendFormat:@"Content-Disposition: form-data; name=file; filename=%@\r\n", name];
    [begin appendString:@"Content-Type: application/octet-stream\r\n\r\n"];
    
    NSString *end = @"\r\n--4Tcjm5mp8BNiQN5YnxAAAnexqnbb3MrWjK--";
    
    NSUInteger len = begin.length + data.length + end.length;
    NSMutableData *mData = [[NSMutableData alloc] initWithCapacity:len];
    [mData appendData:[begin data]];
    [mData appendData:data];
    [mData appendData:[end data]];
    return mData;
}

- (void)post:(NSData *)data name:(NSString *)filename url:(NSString *)urlString {
    if ([_uploadings objectForKey:filename]) {
        NSAssert(false, @"post twice: %@", filename);
        return;
    }
    
    // URL request
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    [request setValue:@"multipart/form-data; boundary=4Tcjm5mp8BNiQN5YnxAAAnexqnbb3MrWjK" forHTTPHeaderField:@"Content-Type"];
    request.HTTPMethod = @"POST";
    
    // HTTP body
    NSData *body = [self buildHTTPBodyWithFilename:filename data:data];
    
    // upload task
    NSURLSessionUploadTask *task;
    task = [self.session uploadTaskWithRequest:request
                                      fromData:body
                             completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                 NSLog(@"HTTP task complete: %@, %@, %@", response, error, [data UTF8String]);
                                 
                                 NSArray *keys = [self->_uploadings allKeysForObject:task];
                                 NSAssert([keys isEqualToArray:@[filename]], @"keys error: %@, filename: %@", keys, filename);
                                 [self->_uploadings removeObjectsForKeys:keys];
                                 NSLog(@"uploading task removed: %@, keys: %@", task, keys);
                             }];
    [_uploadings setObject:task forKey:filename];
    
    // start
    [task resume];
}

- (void)get:(NSURL *)url name:(NSString *)filename key:(DIMSymmetricKey *)scKey sender:(DIMID *)sender {
    if ([_downloadings objectForKey:filename]) {
        NSLog(@"waiting for download: %@", filename);
        return ;
    }
    
    NSURLSessionDataTask *task;
    task = [self.session dataTaskWithURL:url
                       completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                           NSLog(@"HTTP task complete: %@, %@, %@", response, error, [data UTF8String]);
                           
                           // 1. decrypt data and save to local storage
                           if (!error && data.length > 0) {
                               data = [scKey decrypt:data];
                               NSAssert(data.length > 0, @"failed to decrypt file data: %@, %@", filename, data);
                               // save to local
                               NSString *path = full_filepath(sender, filename);
                               NSFileManager *fm = [NSFileManager defaultManager];
                               if (![fm fileExistsAtPath:path]) {
                                   [data writeToFile:path atomically:YES];
                               }
                           }
                           
                           // 2. remove downloading task
                           NSArray *keys = [self->_downloadings allKeysForObject:task];
                           NSAssert([keys isEqualToArray:@[filename]], @"keys error: %@, filename: %@", keys, filename);
                           [self->_downloadings removeObjectsForKeys:keys];
                           NSLog(@"downloading task removed: %@, keys: %@", task, keys);
                       }];
    [_downloadings setObject:task forKey:filename];
    
    // start
    [task resume];
}

#pragma mark - Upload

- (NSString *)_uploadData:(NSData *)data filename:(NSString *)name sender:(const DIMID *)from {
    NSString *uploadURL = [[NSString alloc] initWithFormat:@"%@/%@/upload", _baseURL, from.address];
    [self post:data name:name url:uploadURL];
    
    NSString *downloadURL = [[NSString alloc] initWithFormat:@"%@/download/%@/%@", _baseURL, from.address, name];
    return downloadURL;
}

- (DIMInstantMessage *)uploadFileForMessage:(DIMInstantMessage *)iMsg {
    DIMMessageContent *content = iMsg.content;
    NSData *data = content.fileData;
    if (data == nil/* || content.URL != nil*/) {
        return iMsg;
    }
    
    // 0. check filename & type
    DIMMessageType type = content.type;
    NSString *filename = content.filename;
    NSString *ext = [filename pathExtension];
    if (ext.length > 0) {
        NSLog(@"got file type in message content: %@", ext);
    } else if (type == DIMMessageType_Image) {
        ext = @"png";
    } else if (type == DIMMessageType_Audio) {
        ext = @"mp3";
    } else if (type == DIMMessageType_Video) {
        ext = @"mp4";
    } else {
        NSAssert(false, @"unknown message type: %@", content);
        return iMsg;
    }
    // make sure that filenames won't conflict
    filename = [[NSString alloc] initWithFormat:@"%@.%@", [[data md5] hexEncode], ext];
    
    DIMEnvelope *env = iMsg.envelope;
    DIMID *sender = [DIMID IDWithID:env.sender];
    DIMID *receiver = [DIMID IDWithID:env.receiver];
    
    // 1. save to local
    NSString *path = full_filepath(sender, filename);
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:path]) {
        [data writeToFile:path atomically:YES];
    }
    
    // 2. encrypt
    DIMKeyStore *store = [DIMKeyStore sharedInstance];
    DIMSymmetricKey *scKey = nil;
    if (MKMNetwork_IsGroup(receiver.type)) {
        scKey = [store cipherKeyForGroup:receiver];
    } else {
        scKey = [store cipherKeyForAccount:receiver];
    }
    NSAssert(scKey != nil, @"failed to generate key for receiver: %@", receiver);
    data = [scKey encrypt:data];
    
    // 3. upload file and replace 'data' with 'URL'
    NSString *urlString = [self _uploadData:data filename:filename sender:sender];
    [content setObject:urlString forKey:@"URL"];
    [content removeObjectForKey:@"data"];
    
    return iMsg;
}

#pragma mark Download

- (DIMInstantMessage *)downloadFileForMessage:(DIMInstantMessage *)iMsg {
    DIMMessageContent *content = iMsg.content;
    if (content.URL == nil || content.fileData != nil) {
        return iMsg;
    }
    DIMEnvelope *env = iMsg.envelope;
    DIMID *sender = [DIMID IDWithID:env.sender];
    DIMID *receiver = [DIMID IDWithID:env.receiver];
    
    NSString *filename = content.filename;
    NSString *path = full_filepath(sender, filename);
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:path]) {
        NSData *data = [[NSData alloc] initWithContentsOfFile:path];
        [content setObject:[data base64Encode] forKey:@"data"];
    } else {
        DIMKeyStore *store = [DIMKeyStore sharedInstance];
        DIMSymmetricKey *scKey = [iMsg objectForKey:@"key"];
        if (scKey) {
            scKey = [DIMSymmetricKey keyWithKey:scKey];
        } else if (MKMNetwork_IsGroup(receiver.type)) {
            scKey = [store cipherKeyFromMember:sender inGroup:receiver];
        } else {
            scKey = [store cipherKeyFromAccount:sender];
        }
        // add task
        [self get:content.URL name:filename key:scKey sender:sender];
    }
    
    return iMsg;
}

@end
