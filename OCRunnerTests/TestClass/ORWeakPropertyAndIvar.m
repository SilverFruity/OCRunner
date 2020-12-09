//
//  ORWeakPropertyAndIvar.m
//  OCRunnerDemoTests
//
//  Created by Jiang on 2020/12/9.
//  Copyright © 2020 SilverFruity. All rights reserved.
//

#import "ORWeakPropertyAndIvar.h"

@implementation ORWeakPropertyAndIvar
- (instancetype)initWithContainer:(NSMutableString *)container
{
    self = [super init];
    if (self) {
        self.container = container;
    }
    return self;
}
- (void)dealloc
{
    [self.container appendString:@"dealloc"];
}
@end
