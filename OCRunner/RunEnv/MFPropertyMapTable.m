//
//  MFPropertyMapTable.m
//  MangoFix
//
//  Created by yongpengliang on 2019/4/26.
//  Copyright © 2019 yongpengliang. All rights reserved.
//

#import "MFPropertyMapTable.h"

@implementation MFPropertyMapTableItem

- (instancetype)initWithClass:(Class)clazz property:(ORPropertyDeclare *)property{
    if (self = [super init]) {
        _clazz = clazz;
        _property = property;
    }
    return self;
}

@end

@implementation MFPropertyMapTable{
    CFMutableDictionaryRef _propertyCache;
}

+ (instancetype)shareInstance{
    static id st_instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        st_instance = [[MFPropertyMapTable alloc] init];
    });
    return st_instance;
}

- (instancetype)init{
    if (self = [super init]) {
        _propertyCache = CFDictionaryCreateMutable(CFAllocatorGetDefault(), 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    }
    return self;
}

- (void)addPropertyMapTableItem:(MFPropertyMapTableItem *)propertyMapTableItem{
    if (!propertyMapTableItem) return;
    
    NSString *propertyName = propertyMapTableItem.property.var.var.varname;
    if (!propertyName.length) return;
    
    Class class = propertyMapTableItem.clazz;
    
    if (class == NULL) return;
    
    CFMutableDictionaryRef propertyMap = (CFMutableDictionaryRef)CFDictionaryGetValue(_propertyCache, (__bridge const void *)(class));
    if (propertyMap == NULL){
        propertyMap = CFDictionaryCreateMutable(CFAllocatorGetDefault(), 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        CFDictionarySetValue(_propertyCache, (__bridge const void *)(class), propertyMap);
    }
    if (propertyName == nil) return;
    CFDictionarySetValue(propertyMap, (__bridge CFStringRef)(propertyName), (__bridge const void *)(propertyMapTableItem));
}

- (MFPropertyMapTableItem *)getPropertyMapTableItemWith:(Class)clazz name:(NSString *)name{
    if (clazz == NULL) return nil;
    if (name == nil) return nil;

    CFDictionaryRef propertyMap = CFDictionaryGetValue(_propertyCache, (__bridge const void *)(clazz));
    if (propertyMap == NULL) return nil;
    
    return CFDictionaryGetValue(propertyMap, (__bridge CFStringRef)(name));
}


@end
