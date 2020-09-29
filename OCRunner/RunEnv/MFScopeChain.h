//
//  ANEScopeChain.h
//  MangoFix
//
//  Created by jerry.yong on 2018/2/28.
//  Copyright © 2018年 yongpengliang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ORArgsStack.h"
#import "ORGlobalFunctionTable.h"
#import "built-in.h"
@class MFValue;
NS_ASSUME_NONNULL_BEGIN
extern const void *mf_propKey(NSString *propName);
@interface MFScopeChain: NSObject
@property (strong, nonatomic) NSMutableDictionary<NSString *,MFValue *> *vars;
+ (instancetype)topScope;
@property (strong, nonatomic) MFScopeChain *next;
@property (strong, nonatomic) MFValue *instance;

+ (instancetype)scopeChainWithNext:(MFScopeChain *)next;
- (nullable MFValue *)getValueWithIdentifier:(NSString *)identifier endScope:(nullable MFScopeChain *)endScope;
- (nullable MFValue *)recursiveGetValueWithIdentifier:(NSString *)identifier;
- (nullable MFValue *)getValueWithIdentifier:(NSString *)identifer;
- (void)setValue:(MFValue *)value withIndentifier:(NSString *)identier;
- (void)assignWithIdentifer:(NSString *)identifier value:(MFValue *)value;
- (void)clear;
@end
NS_ASSUME_NONNULL_END
