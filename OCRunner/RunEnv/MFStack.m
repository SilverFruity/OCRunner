//
//  ANEStack.m
//  MangoFix
//
//  Created by jerry.yong on 2018/2/28.
//  Copyright © 2018年 yongpengliang. All rights reserved.
//

#import "MFStack.h"
#import <MFValue.h>
@implementation MFStack{
	NSMutableArray<NSMutableArray *> *_arr;
}
+ (instancetype)argsStack{
    static dispatch_once_t onceToken;
    static MFStack * _instance = nil;
    dispatch_once(&onceToken, ^{
        _instance = [MFStack new];
    });
    return _instance;
}
- (instancetype)init{
	if (self = [super init]) {
		_arr = [NSMutableArray array];
	}
	return self;
}

- (void)push:(NSMutableArray <MFValue *> *)value{
    NSAssert(value, @"value can not be nil");
	[_arr addObject:value];
}

- (NSMutableArray <MFValue *> *)pop{
	NSMutableArray *value = [_arr  lastObject];
    NSAssert(value, @"stack is empty");
	[_arr removeLastObject];
	return value;
}
- (BOOL)isEmpty{
    return [_arr count] == 0;
}
- (NSUInteger)size{
	return _arr.count;
}
@end

