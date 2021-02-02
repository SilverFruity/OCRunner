//
//  ORffiResultCache.h
//  OCRunner
//
//  Created by Jiang on 2021/2/2.
//

#import <Foundation/Foundation.h>
#import "ORCoreFunction.h"
NS_ASSUME_NONNULL_BEGIN

@interface ORffiResultCache : NSObject
@property (nonatomic, strong)NSMutableDictionary <NSValue *,NSValue *>*cache;
+ (instancetype)shared;
- (void)saveffiResult:(or_ffi_result *)result WithKey:(NSValue *)key;
- (or_ffi_result *)ffiResultForKey:(NSValue *)key;
- (void)removeForKey:(NSValue *)key;
- (void)clear;
@end

NS_ASSUME_NONNULL_END
