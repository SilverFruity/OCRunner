//
//  ORTestReplaceClass.m
//  OCRunnerTests
//
//  Created by Jiang on 2020/5/14.
//  Copyright © 2020 SilverFruity. All rights reserved.
//

#import "ORTestReplaceClass.h"

@implementation ORTestReplaceClass
- (int)test{
    return 0;
}
- (int)arg1:(NSNumber *)arg1{
    return 0;
}
- (int)arg1:(NSNumber *)arg1 arg2:(NSNumber *)arg2{
    return 0;
}
- (BOOL)testInstanceMethodReplace{
    return NO;
}
+ (BOOL)testClassMethodReplaceTest{
    return NO;
}
- (NSString *)testOriginalMethod{
    return nil;
}
- (NSString *)testSuperMethodReplaceTest{
    return nil;
}
- (BOOL)testAddGlobalVar{
    return NO;
}
- (NSDictionary* (^)(void))testMethodParameterListAndReturnValueWithString:(NSString *)str block:(NSString *(^)(NSString *))block{
    return nil;
}

@end
