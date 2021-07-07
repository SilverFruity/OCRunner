//
//  ORThreadContext.h
//  OCRunner
//
//  Created by Jiang on 2021/6/4.
//

#import <Foundation/Foundation.h>

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

typedef UInt64 mem_cursor;
typedef UInt64 * local_var_mem;
@interface ORThreadContext : NSObject
{
    mem_cursor sp;
    mem_cursor fp;
    mem_cursor cursor;
    local_var_mem mem;
    local_var_mem mem_end;
}
- (void)push:(NSArray *)vars;
- (id)seek:(mem_cursor)offset;
- (void)enter;
- (void)exit;

@property (nonatomic, strong)ORArgsStack *argsStack;
@property (nonatomic, strong)ORCallFrameStack *callFrameStack;
+ (instancetype)threadContext;
@end

NS_ASSUME_NONNULL_END
