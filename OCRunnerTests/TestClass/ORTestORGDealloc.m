//
//  ORTestORGDealloc.m
//  OCRunnerDemoTests
//
//  Created by Jiang on 2023/7/29.
//  Copyright © 2023 SilverFruity. All rights reserved.
//

#import "ORTestORGDealloc.h"

@implementation ORTestORGDealloc
- (instancetype)initWithCounter:(int *)counter {
    self = [super init];
    _counter = counter;
    return self;
}

- (void)dealloc {
    *_counter += 10;
}
@end
