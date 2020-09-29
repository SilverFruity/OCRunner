//
//  ORSystemFunctionTable.m
//  OCRunner
//
//  Created by Jiang on 2020/7/17.
//  Copyright © 2020 SilverFruity. All rights reserved.
//

#import "ORSystemFunctionPointerTable.h"

@implementation ORSystemFunctionPointerTable
{
    NSMutableDictionary <NSString *,NSValue *>*_table;
}
- (instancetype)init
{
    self = [super init];
    if (self) {
        _table = [NSMutableDictionary dictionary];
    }
    return self;
}
+ (instancetype)shareInstance{
    static id st_instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        st_instance = [[ORSystemFunctionPointerTable alloc] init];
    });
    return st_instance;
}
+ (void)reg:(NSString *)name pointer:(void *)pointer{
    [ORSystemFunctionPointerTable shareInstance]->_table[name] = [NSValue valueWithPointer:pointer];
}
+ (void *)pointerForFunctionName:(NSString *)name{
    NSValue *value = [ORSystemFunctionPointerTable shareInstance]->_table[name];
    return value.pointerValue;
}
@end
