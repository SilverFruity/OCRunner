//
//  ORTestAspect.m
//  OCRunnerDemoTests
//
//  Created by 程聪 on 2025/12/29.
//  Copyright © 2025 SilverFruity. All rights reserved.
//

#import "ORTestAspect.h"

@implementation ORTestAspect
- (void)foo:(id)arg
{
    NSLog(@"foo Origin: %@", arg);
    self.argFromOrigin = arg;
}
@end
