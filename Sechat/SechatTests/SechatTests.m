//
//  SechatTests.m
//  SechatTests
//
//  Created by Albert Moky on 2019/2/24.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "NSObject+JsON.h"
#import "NSData+Crypto.h"

@interface SechatTests : XCTestCase

@end

@implementation SechatTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

- (void)testJSON {
    
    NSString *ID = @"assistant@2PpB6iscuBjA15oTjAsiswoX9qis5V3c1Dq";
    NSString *dir = [[NSBundle mainBundle] resourcePath];
    dir = [dir stringByAppendingPathComponent:ID];
    
    NSString *path = [dir stringByAppendingPathComponent:@"meta.js"];
    NSData *data = [NSData dataWithContentsOfFile:path];
    NSString *json = [NSString stringWithCString:[data bytes] encoding:NSUTF8StringEncoding];
    NSLog(@"meta.js: %@", json);
    
    NSDictionary *dict = [data jsonDictionary];
    path = [dir stringByAppendingPathComponent:@"meta.plist"];
    [dict writeToFile:path atomically:YES];
    NSLog(@"wrote into: %@", path);
}

@end
