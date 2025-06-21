//
//  ANEScopeChain.h
//  MangoFix
//
//  Created by jerry.yong on 2018/2/28.
//  Copyright © 2018年 yongpengliang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ORGlobalFunctionTable.h"
#import "built-in.h"
@class MFValue;
NS_ASSUME_NONNULL_BEGIN

@interface OREntryContext: NSObject
@property (strong, nonatomic) Class classNode;
@property (nonatomic, assign)bool isDeallocScope;
@property (nonatomic, assign)bool deferCallOrigDealloc;
@property (nonatomic, assign)bool deferCallSuperDealloc;
+ (instancetype)contextWithClass:(Class)classNode;
@end

FOUNDATION_EXPORT const void *mf_propKey(NSString *propName);

@interface MFScopeChain: NSObject
@property (strong, nonatomic) NSMutableDictionary<NSString *,MFValue *> *vars;
+ (instancetype)topScope;
@property (strong, nonatomic) MFScopeChain *next;
@property (strong, nonatomic) MFValue *instance;
// only in Method or Function's top scope.
@property (strong, nonatomic) OREntryContext *entryCtx;

- (Class)classNode;

+ (instancetype)scopeChainWithNext:(MFScopeChain *)next;
- (nullable MFValue *)getValueWithIdentifier:(NSString *)identifier endScope:(nullable MFScopeChain *)endScope;
- (nullable MFValue *)recursiveGetValueWithIdentifier:(NSString *)identifier;
- (nullable MFValue *)getValueWithIdentifier:(NSString *)identifer;
- (void)setValue:(MFValue *)value withIndentifier:(NSString *)identier;
- (void)assignWithIdentifer:(NSString *)identifier value:(MFValue *)value;
- (void)removeForIdentifier:(NSString *)key;
- (void)clear;
@end
NS_ASSUME_NONNULL_END
