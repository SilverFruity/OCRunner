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
    NSLock *_lock;
    NSCache *classCaches;
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
        _dic = [NSMutableDictionary dictionary];
        _lock = [[NSLock alloc] init];
    }
    return self;
}

- (void)addPropertyMapTableItem:(MFPropertyMapTableItem *)propertyMapTableItem{
    NSString *propertyName = propertyMapTableItem.property.var.var.varname;
    if (!propertyName.length) {
        return;
    }
    Class class = propertyMapTableItem.clazz;
    NSCache *propertyMap = [classCaches objectForKey:class];
    if (propertyMap == NULL){
        propertyMap = [NSCache new];
        [classCaches setObject:propertyMap forKey:class];
    }
    [propertyMap setObject:propertyMapTableItem forKey:propertyName];
}

- (MFPropertyMapTableItem *)getPropertyMapTableItemWith:(Class)clazz name:(NSString *)name{
    NSCache *propertyMap = [classCaches objectForKey:clazz];
    return [propertyMap objectForKey:name];
}


@end
