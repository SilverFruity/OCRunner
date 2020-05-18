//
//  ORTestReplaceClass.h
//  OCRunnerTests
//
//  Created by Jiang on 2020/5/14.
//  Copyright © 2020 SilverFruity. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ORTestReplaceClass : NSObject
- (int)test;
- (int)arg1:(NSNumber *)arg1;
- (int)arg1:(NSNumber *)arg1 arg2:(NSNumber *)arg2;
- (void *)valueAdress;
+ (BOOL)testClassMethodReplaceTest;
- (NSInteger)testOriginalMethod;
- (NSInteger)testAddGlobalVar;
- (NSDictionary *(^)(void))testMethodParameterListAndReturnValueWithString:(NSString *)str block:(NSString *(^)(NSString *))block;
@end

NS_ASSUME_NONNULL_END
