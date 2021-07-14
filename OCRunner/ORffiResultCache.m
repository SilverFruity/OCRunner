//
//  ORffiResultCache.m
//  OCRunner
//
//  Created by Jiang on 2021/2/2.
//

#import "ORffiResultCache.h"

@implementation ORffiResultCache
+ (instancetype)shared{
    static dispatch_once_t onceToken;
    static ORffiResultCache *_instance;
    dispatch_once(&onceToken, ^{
        _instance = [ORffiResultCache new];
    });
    return _instance;
}
- (instancetype)init
{
    self = [super init];
    if (self) {
        self.cache = [NSMutableDictionary dictionary];
    }
    return self;
}
- (void)saveffiResult:(or_ffi_result *)result WithKey:(NSValue *)key{
    self.cache[key] = [NSValue valueWithPointer:result];
}
- (or_ffi_result *)ffiResultForKey:(NSValue *)key{
    return (or_ffi_result *)self.cache[key].pointerValue;
}
- (void)removeForKey:(NSValue *)key{
    [self.cache removeObjectForKey:key];
}
- (void)clear{
    self.cache = [NSMutableDictionary dictionary];
}
@end
