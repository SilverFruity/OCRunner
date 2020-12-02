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
    CFMutableDictionaryRef classMethodCache;
    CFMutableDictionaryRef instanceMethodCache;
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
        classMethodCache = CFDictionaryCreateMutable(CFAllocatorGetDefault(), 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        instanceMethodCache = CFDictionaryCreateMutable(CFAllocatorGetDefault(), 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    }
    return self;
}

- (void)addMethodMapTableItem:(MFMethodMapTableItem *)methodMapTableItem{
    Class class = methodMapTableItem.clazz;
    NSString *sel = [methodMapTableItem.methodImp.declare selectorName];
    if (methodMapTableItem.methodImp.declare.isClassMethod){
        CFMutableDictionaryRef classMap = (CFMutableDictionaryRef)CFDictionaryGetValue(classMethodCache, (__bridge const void *)(class));
        if (classMap == NULL){
            classMap = CFDictionaryCreateMutable(CFAllocatorGetDefault(), 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
            CFDictionarySetValue(classMethodCache, (__bridge const void *)(class), classMap);
        }
        CFDictionarySetValue(classMap, (__bridge CFStringRef)(sel), (__bridge const void *)(methodMapTableItem));
    }else{
        CFMutableDictionaryRef classMap = (CFMutableDictionaryRef)CFDictionaryGetValue(instanceMethodCache, (__bridge const void *)(class));
        if (classMap == NULL){
            classMap = CFDictionaryCreateMutable(CFAllocatorGetDefault(), 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
            CFDictionarySetValue(instanceMethodCache, (__bridge const void *)(class), classMap);
        }
        CFDictionarySetValue(classMap, (__bridge CFStringRef)(sel), (__bridge const void *)(methodMapTableItem));
    }
}

- (MFMethodMapTableItem *)getMethodMapTableItemWith:(Class)clazz classMethod:(BOOL)classMethod sel:(SEL)sel{
    NSString *selector = NSStringFromSelector(sel);
    if (classMethod){
        CFDictionaryRef classMap = CFDictionaryGetValue(classMethodCache, (__bridge const void *)(clazz));
        if (classMap == NULL) return nil;
        return CFDictionaryGetValue(classMap, (__bridge CFStringRef)(selector));
    }else{
        CFDictionaryRef classMap = CFDictionaryGetValue(instanceMethodCache, (__bridge const void *)(clazz));
        if (classMap == NULL) return nil;
        return CFDictionaryGetValue(classMap, (__bridge CFStringRef)(selector));
    }
}
@end
