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
 @return "Library/Caches/.dim/{address}/xxxx.png"
 */
static inline NSString *full_filepath(const DIMID *ID, NSString *filename) {
    assert(ID.isValid);
    // base directory: Library/Caches/.dim/{address}
    NSString *dir = caches_directory();
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

- (NSData *)buildHTTPBodyWithFilename:(const NSString *)name data:(const NSData *)data {
    
    NSMutableString *begin = [[NSMutableString alloc] init];
    [begin appendString:@"--4Tcjm5mp8BNiQN5YnxAAAnexqnbb3MrWjK\r\n"];
    [begin appendFormat:@"Content-Disposition: form-data; name=file; filename=%@\r\n", name];
    [begin appendString:@"Content-Type: application/octet-stream\r\n\r\n"];
    
    NSString *end = @"\r\n--4Tcjm5mp8BNiQN5YnxAAAnexqnbb3MrWjK--";
    
    NSUInteger len = begin.length + data.length + end.length;
    NSMutableData *mData = [[NSMutableData alloc] initWithCapacity:len];
    [mData appendData:[begin data]];
    [mData appendData:[data copy]];
    [mData appendData:[end data]];
    return mData;
}

- (void)post:(NSData *)data name:(NSString *)filename url:(NSURL *)url {
    if ([_uploadings objectForKey:filename]) {
        NSAssert(false, @"post twice: %@", filename);
        return;
    }
    
    // URL request
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
                                 
                                 // remove uploading task
                                 NSLog(@"removing task: %@, filename: %@", [self->_uploadings objectForKey:filename], filename);
                                 [self->_uploadings removeObjectForKey:filename];
                             }];
    [_uploadings setObject:task forKey:filename];
    
    // start
    [task resume];
}

- (void)get:(NSURL *)url name:(NSString *)filename sender:(const DIMID *)sender {
    if ([_downloadings objectForKey:filename]) {
        NSLog(@"waiting for download: %@", filename);
        return ;
    }
    
    NSURLSessionDataTask *task;
    task = [self.session dataTaskWithURL:url
                       completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                           NSLog(@"HTTP task complete: %@, %@, %@", response, error, [data UTF8String]);
                           
                           if (error) {
                               NSLog(@"download %@ error: %@", url, error);
                           } else {
                               // save to local
                               NSString *path = full_filepath(sender, filename);
                               NSFileManager *fm = [NSFileManager defaultManager];
                               if (![fm fileExistsAtPath:path]) {
                                   [data writeToFile:path atomically:YES];
                               }
                           }
                           
                           // remove downloading task
                           NSLog(@"removing task: %@, filename: %@", [self->_downloadings objectForKey:filename], filename);
                           [self->_downloadings removeObjectForKey:filename];
                       }];
    [_downloadings setObject:task forKey:filename];
    
    // start
    [task resume];
}

#pragma mark -

- (NSURL *)uploadData:(const NSData *)data filename:(nullable const NSString *)name sender:(const DIMID *)from {
    
    // 0. prepare filename (make sure that filenames won't conflict)
    NSString *filename = [[data md5] hexEncode];
    NSString *ext = [name pathExtension];
    if (ext.length > 0) {
        filename = [filename stringByAppendingPathExtension:ext];
    }
    
    // 1. save to local storage
    NSString *path = full_filepath(from, filename);
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:path]) {
        [data writeToFile:path atomically:YES];
    }
    
    // 2. upload to CDN
    NSString *api = [[NSString alloc] initWithFormat:@"%@/%@/upload", _baseURL, from.address];
    NSURL *url = [NSURL URLWithString:api];
    [self post:(NSData *)data name:filename url:url];
    
    // 3. build download URL
    NSString *downloadURL = [[NSString alloc] initWithFormat:@"%@/download/%@/%@", _baseURL, from.address, filename];
    return [NSURL URLWithString:downloadURL];
}

- (NSData *)downloadDataFromURL:(const NSURL *)url filename:(nullable const NSString *)name sender:(const DIMID *)from {
    
    // 0. prepare filename
    NSString *filename = [url lastPathComponent];
    
    // 1. check local storage
    NSString *path = full_filepath(from, filename);
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:path]) {
        return [[NSData alloc] initWithContentsOfFile:path];
    }
    
    // 2. download from url
    [self get:(NSURL *)url name:filename sender:from];
    return nil;
}

@end
