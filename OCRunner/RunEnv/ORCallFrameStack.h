//
//  ORCallFrameStack.h
//  OCRunner
//
//  Created by Jiang on 2021/6/4.
//

#import <Foundation/Foundation.h>
#import "or_value.h"

NS_ASSUME_NONNULL_BEGIN
@class MFValue;
@class ORMethodNode;
@class ORFunctionNode;
@class MFScopeChain;
@interface ORCallFrameStack: NSObject
+ (void)pushMethodCall:(ORMethodNode *)imp instance:(MFValue *)instance;
+ (void)pushFunctionCall:(ORFunctionNode *)imp scope:(MFScopeChain *)scope;
+ (void)pop;
+ (instancetype)threadStack;
+ (NSString *)history;
@end
NS_ASSUME_NONNULL_END
