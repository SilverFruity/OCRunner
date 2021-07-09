//
//  ORThreadContext.h
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
typedef unichar * local_var_mem;
typedef or_value_box * op_stack_mem;

typedef struct {
    mem_cursor lr;
    __unsafe_unretained ORNode *node;
}or_vm_function_frame;

typedef enum {
    ORControlFlowFlagNormal = 0x00,
    ORControlFlowFlagBreak = 0x01,
    ORControlFlowFlagContinue = 0x02,
    ORControlFlowFlagReturn = 0x10 << 1,
}ORControlFlowFlag;

@interface ORThreadContext : NSObject
{
    @public
    mem_cursor lr;
    mem_cursor sp;
    mem_cursor cursor;
    
    local_var_mem mem;
    local_var_mem mem_end;
    
    op_stack_mem op_mem;
    op_stack_mem op_mem_end;
    mem_cursor op_mem_top;

    ORControlFlowFlag flow_flag;
}
- (void)push:(void *)var size:(size_t)size;
- (void *)seek:(mem_cursor)offset size:(size_t)size;
- (void)enter;
- (void)exit;
- (BOOL)isEmpty;

@property (nonatomic, strong)ORArgsStack *argsStack;
@property (nonatomic, strong)ORCallFrameStack *callFrameStack;
+ (instancetype)current;
@end

NS_ASSUME_NONNULL_END
