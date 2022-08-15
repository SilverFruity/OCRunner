//
//  ORHookNatvieMultiSuperCall.m
//  OCRunnerDemoTests
//
//  Created by Jiang on 2022/8/15.
//  Copyright © 2022 SilverFruity. All rights reserved.
//

#import "ORHookNatvieMultiSuperCall.h"

@implementation NativeFinalObject
- (int)test:(int)count {
    return count + 1;
}
@end


@implementation NativeHotBaseController
- (int)test:(int)count {
    return [super test:count + 1];
}
@end

@implementation NativeViewController3
- (int)test:(int)count {
    return [super test:count + 1];
}
@end
