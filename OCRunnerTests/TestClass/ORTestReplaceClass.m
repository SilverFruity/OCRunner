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
+ (BOOL)testClassMethodReplaceTest{
    return NO;
}
- (NSInteger)testOriginalMethod{
    return 1;
}
- (NSInteger)testAddGlobalVar{
    return 1;
}
- (NSDictionary* (^)(void))testMethodParameterListAndReturnValueWithString:(NSString *)str block:(NSString *(^)(NSString *))block{
    return nil;
}
- (int)testNoSignatureBlock:(int(^)(int))arg{
    return 0;
}
- (NSString *)testInputStackBlock{
    __block NSString *result = @"";
    __weak typeof(self) weakSelf = self;
    [self receiveStackBlock:^(NSString * _Nonnull str) {
        result = str;
        NSLog(@"%@",weakSelf);
    }];
    return result;
}
- (void)receiveStackBlock:(void (^)(NSString *str))block{
    block(@"123");
}
- (void)test6ArgsMethoCall:(int)arg1 arg2:(int)arg2  arg3:(int)arg3 arg4:(int)arg4 arg5:(int)arg5 arg6:(int)arg6{
}
- (int)scriptReceiveCArray:(int *)array len:(int)len{
    return 0;
}
- (int)receiveCArray:(int *)array len:(int)len{
    int r = 0;
    for (int i = 0; i < len; i++) {
        r += array[i];
    }
    return r;
}
@end
