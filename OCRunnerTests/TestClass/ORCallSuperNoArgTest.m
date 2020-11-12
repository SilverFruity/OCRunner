//
//  ORCallSuperNoArgTest.m
//  OCRunnerTests
//
//  Created by Jiang on 2020/5/15.
//  Copyright © 2020 SilverFruity. All rights reserved.
//

#import "ORCallSuperNoArgTest.h"



@implementation MFCallSuperNoArgTestSupserTest

- (BOOL)testCallSuperNoArgTestSupser{
    return NO;
}

@end

@implementation MFCallSuperNoArgTest

- (BOOL)testCallSuperNoArgTestSupser{
    return [super testCallSuperNoArgTestSupser];
}

@end

#pragma mark - Car

@implementation Car

- (int)run
{
    return 0;
}

@end

#pragma mark - BMW

@implementation BMW

- (int)run
{
    return 1;
}

@end

#pragma mark - MiniBMW

@implementation MiniBMW

@end
