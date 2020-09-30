//
//  MFMethodMapTable.m
//  MangoFix
//
//  Created by jerry.yong on 2018/2/23.
//  Copyright © 2018年 yongpengliang. All rights reserved.
//

#import "MFMethodMapTable.h"

@implementation MFMethodMapTableItem
- (instancetype)initWithClass:(Class)clazz method:(ORMethodImplementation *)method; {
	if (self = [super init]) {
		_clazz = clazz;
		_methodImp = method;
	}
	return self;
}
@end

@implementation MFMethodMapTable{
    NSCache *classMethodCache;
    NSCache *instanceMethodCache;
    NSLock *_lock;
}

+ (instancetype)shareInstance{
	static id st_instance;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		st_instance = [[MFMethodMapTable alloc] init];
	});
	return st_instance;
}

- (instancetype)init{
	if (self = [super init]) {
        classMethodCache = [NSCache new];
        instanceMethodCache = [NSCache new];
        _lock = [[NSLock alloc] init];
	}
	return self;
}

- (void)addMethodMapTableItem:(MFMethodMapTableItem *)methodMapTableItem{
    Class class = methodMapTableItem.clazz;
    NSString *sel = [methodMapTableItem.methodImp.declare selectorName];
    if (methodMapTableItem.methodImp.declare.isClassMethod){
        NSCache *classMap = [classMethodCache objectForKey:class];
        if (classMap == NULL){
            classMap = [NSCache new];
            [classMethodCache setObject:classMap forKey:class];
        }
        [classMap setObject:methodMapTableItem forKey:sel];
    }else{
        NSCache *classMap = [instanceMethodCache objectForKey:class];
        if (classMap == NULL){
            classMap = [NSCache new];
            [instanceMethodCache setObject:classMap forKey:class];
        }
        [classMap setObject:methodMapTableItem forKey:sel];
    }
}

- (MFMethodMapTableItem *)getMethodMapTableItemWith:(Class)clazz classMethod:(BOOL)classMethod sel:(SEL)sel{
    NSString *selector = NSStringFromSelector(sel);
    if (classMethod){
        NSCache *classMap = [classMethodCache objectForKey:clazz];
        return [classMap objectForKey:selector];
    }else{
        NSCache *classMap = [instanceMethodCache objectForKey:clazz];
        return [classMap objectForKey:selector];
    }
}
@end
