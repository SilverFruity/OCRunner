//
//  MFMethodMapTable.m
//  MangoFix
//
//  Created by jerry.yong on 2018/2/23.
//  Copyright © 2018年 yongpengliang. All rights reserved.
//

#import "MFMethodMapTable.h"

@implementation MFMethodMapTableItem
- (instancetype)initWithClass:(Class)clazz method:(ORMethodNode *)method; {
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
    if (!methodMapTableItem) return;
    
    Class class = methodMapTableItem.clazz;
    
    if (class == NULL) return;
    
    NSString *sel = [methodMapTableItem.methodImp.declare selectorName];
    
    if (!sel) return;
    
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
- (void)removeMethodsForClass:(Class)clazz{
    if (clazz == NULL) return;
    const void *key  = (__bridge const void *)clazz;
    if (CFDictionaryGetValue(classMethodCache, key)) {
        CFRelease(CFDictionaryGetValue(classMethodCache, key));
    }
    if (CFDictionaryGetValue(instanceMethodCache, key)) {
        CFRelease(CFDictionaryGetValue(instanceMethodCache, key));
    }
    CFDictionaryRemoveValue(classMethodCache, key);
    CFDictionaryRemoveValue(instanceMethodCache, key);
}

- (MFMethodMapTableItem *)getMethodMapTableItemWith:(Class)clazz classMethod:(BOOL)classMethod sel:(SEL)sel{
    if (clazz == NULL) { return nil; }
    
    NSString *selector = NSStringFromSelector(sel);
    
    if (!selector) { return nil; }
    
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
