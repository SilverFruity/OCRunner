//
//  ORTestClassProperty.m
//  OCRunnerTests
//
//  Created by Jiang on 2020/5/15.
//  Copyright © 2020 SilverFruity. All rights reserved.
//

#import "ORTestClassProperty.h"

@implementation ORTestClassProperty
{
    NSMutableString *_flag;
}
- (instancetype)initDeallocFlag:(NSMutableString *)flag{
    self = [super init];
    _flag = flag;
    return self;
}
- (NSString *)testObjectPropertyTest{
    return nil;
}

- (id)testWeakObjectProperty{
    return nil;
}
- (id)testStrongObjectProperty{
    return nil;
}
- (NSString *)testIvarx{
    return @"";
}
- (NSInteger)testProMathAdd{
    return 0;
}
-(NSInteger)testBasePropertyTest{
    return 0;
}
- (NSInteger)testPropertyIvar{
    return 0;
}
- (void)dealloc
{
    [_flag appendString:@"has_dealloc"];
}
@end
