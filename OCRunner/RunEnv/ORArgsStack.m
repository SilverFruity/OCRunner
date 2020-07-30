//
//  ANEStack.m
//  MangoFix
//
//  Created by jerry.yong on 2018/2/28.
//  Copyright © 2018年 yongpengliang. All rights reserved.
//

#import "ORArgsStack.h"
#import <MFValue.h>
@interface ORArgsStack()
@property(nonatomic, strong) NSMutableArray<NSMutableArray *> *array;
@end
@implementation ORArgsStack
+ (instancetype)threadStack{
    //每一个线程拥有一个独立的参数栈
    NSMutableDictionary *threadInfo = [[NSThread currentThread] threadDictionary];
    ORArgsStack *stack = threadInfo[@"argsStack"];
    if (!stack) {
        stack = [[ORArgsStack alloc] init];
        threadInfo[@"argsStack"] = stack;
    }
    return stack;
}
- (instancetype)init{
	if (self = [super init]) {
		_array = [NSMutableArray array];
	}
	return self;
}

+ (void)push:(NSMutableArray <MFValue *> *)value{
    NSAssert(value, @"value can not be nil");
	[[ORArgsStack threadStack].array addObject:value];
}

+ (NSMutableArray <MFValue *> *)pop{
	NSMutableArray *value = [[ORArgsStack threadStack].array  lastObject];
    NSAssert(value, @"stack is empty");
	[[ORArgsStack threadStack].array removeLastObject];
	return value;
}
+ (BOOL)isEmpty{
    return [[ORArgsStack threadStack].array count] == 0;
}
+ (NSUInteger)size{
    return [ORArgsStack threadStack].array.count;
}
@end

