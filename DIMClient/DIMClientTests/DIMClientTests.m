//
//  DIMClientTests.m
//  DIMClientTests
//
//  Created by Albert Moky on 2018/12/21.
//  Copyright © 2018 DIM Group. All rights reserved.
//

#import <XCTest/XCTest.h>

#import <DIMCore/DIMCore.h>

#import "NSObject+JsON.h"

@interface DIMClientTests : XCTestCase

@end

@implementation DIMClientTests

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

- (void)testRSA {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"gsp" ofType:@"plist"];
    NSDictionary *gsp = [NSDictionary dictionaryWithContentsOfFile:path];
    NSArray *stations = [gsp objectForKey:@"stations"];
    NSDictionary *station = stations.firstObject;
    NSDictionary *private = [station objectForKey:@"privateKey"];
    NSLog(@"SK: %@", private);
    
    DIMPrivateKey *SK = [[DIMPrivateKey alloc] initWithDictionary:private];
    DIMPublicKey *PK = SK.publicKey;
    NSLog(@"PK: %@", PK);
}

- (void)testJsON {
    NSString *jsonString = @"{\"type\": 136, \"sn\": 3351670147, \"command\": \"handshake\", \"message\": \"DIM?\", \"session\": \"c04112b5ebaac8fd973ac7662df4a9dacbac164e4152a67c035f029982151503\"}";
    NSData *data = [jsonString data];
    NSDictionary *dict = [data jsonDictionary];
    NSLog(@"%@ -> %@", jsonString, dict);
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
