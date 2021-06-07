//
//  ORThreadContext.h
//  OCRunner
//
//  Created by APPLE on 2021/6/4.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@class MFValue;
@class ORMethodImplementation;
@class ORFunctionImp;
@class MFScopeChain;
@interface ORCallFrameStack: NSObject
+ (void)pushMethodCall:(ORMethodImplementation *)imp instance:(MFValue *)instance;
+ (void)pushFunctionCall:(ORFunctionImp *)imp scope:(MFScopeChain *)scope;
+ (void)pop;
+ (instancetype)threadStack;
+ (NSString *)history;
@end

@interface ORArgsStack : NSObject
+ (void)push:(NSMutableArray <MFValue *> *)value;
+ (NSMutableArray <MFValue *> *)pop;
+ (BOOL)isEmpty;
+ (NSUInteger)size;
+ (instancetype)threadStack;
@end

@class ORNode;
@interface ORExecuteState: NSObject
@property (nonatomic, strong)ORNode *executingNode;
@end

@interface ORThreadContext : NSObject
@property (nonatomic, strong)ORArgsStack *argsStack;
@property (nonatomic, strong)ORCallFrameStack *callFrameStack;
+ (instancetype)threadContext;
@end

NS_ASSUME_NONNULL_END
