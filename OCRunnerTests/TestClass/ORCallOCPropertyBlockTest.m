//
//  ORCallOCPropertyBlockTest.m
//  OCRunnerTests
//
//  Created by Jiang on 2020/5/15.
//  Copyright © 2020 SilverFruity. All rights reserved.
//

#import "ORCallOCPropertyBlockTest.h"

@implementation ORCallOCPropertyBlockTest
- (instancetype)init{
    if (self = [super init]) {
        _propertyBlock = ^(id arg1,id arg2){
            return [NSString stringWithFormat:@"%@%@",arg1,arg2];
        };
    }
    return self;
}

- (NSString * (^)(id,id))returnBlockMethod{
    id block = ^(id arg1,id arg2){
        return [NSString stringWithFormat:@"%@%@",arg1,arg2];
    };
    return block;
}

- (id)testCallOCReturnBlock{
    return nil;
}
@end
