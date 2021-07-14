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



//typedef struct {
//    mem_cursor lr;
//    __unsafe_unretained ORNode *node;
//}or_vm_function_frame;

typedef enum {
    ORControlFlowFlagNormal = 0x00,
    ORControlFlowFlagBreak = 0x01,
    ORControlFlowFlagContinue = 0x02,
    ORControlFlowFlagReturn = 0x10 << 1,
}ORControlFlowFlag;


typedef UInt64 mem_cursor;
typedef UInt8 * machine_mem;
typedef or_value *op_stack_mem;
typedef or_value_box *op_temp_value_mem;

typedef struct {
    mem_cursor lr;
    mem_cursor sp;
    mem_cursor cursor;
    
    machine_mem mem;
    machine_mem mem_end;
    
    op_stack_mem op_mem;
    op_stack_mem op_mem_end;
    mem_cursor op_mem_top;
    
    op_temp_value_mem op_temp_mem;
    op_temp_value_mem op_temp_mem_end;
    mem_cursor op_temp_mem_top;

    ORControlFlowFlag flow_flag;
}ORThreadContext;

ORThreadContext *thread_ctx_create(void);
ORThreadContext *current_thread_context(void);

machine_mem thread_ctx_push_localvar(ORThreadContext *ctx, void *var, size_t size);
void *thread_ctx_seek_localvar(ORThreadContext *ctx, mem_cursor offset);
void thread_ctx_enter_call(ORThreadContext *ctx);
void thread_ctx_exit_call(ORThreadContext *ctx);
bool thread_ctx_is_calling(ORThreadContext *ctx);

void thread_ctx_temp_mem_pop(ORThreadContext *ctx);
or_value_box *thread_ctx_tempmem_write_top(ORThreadContext *ctx, or_value_box *var);
or_value_box *thread_ctx_tempmem_push(ORThreadContext *ctx, or_value_box *var);
or_value_box *thread_ctx_tempmem_top_var(ORThreadContext *ctx);
or_value_box *thread_ctx_tempmem_seek(ORThreadContext *ctx, mem_cursor beforeTop);

or_value * thread_ctx_op_stack_pop(ORThreadContext *ctx);
void thread_ctx_op_stack_write_top(ORThreadContext *ctx, or_value var);
void thread_ctx_op_stack_push(ORThreadContext *ctx, or_value var);
or_value * thread_ctx_op_stack_top_var(ORThreadContext *ctx);
or_value * thread_ctx_op_stack_seek(ORThreadContext *ctx, mem_cursor beforeTop);


NS_ASSUME_NONNULL_END
