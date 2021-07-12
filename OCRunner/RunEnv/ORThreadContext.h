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

@interface ORThreadContext : NSObject
{
    @public
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
}
- (machine_mem)pushLocalVar:(void *)var size:(size_t)size;
- (void *)seekLocalVar:(mem_cursor)offset;
- (void)enter;
- (void)exit;
- (BOOL)isEmpty;

//- (void)opStackPop;
//- (or_value_box *)opStackTopVar;
//- (void)writeOpStackTop:(or_value_box)var;
//- (void)pushOpStack:(or_value_box)var typeencode:(const char *)typeencode;
//- (or_value_box *)seekOpStack:(mem_cursor)beforeTop typeencode:(const char *)typeencode;

- (void)tempStackPop;
- (or_value_box *)tempStackWriteTop:(or_value_box *)var;
- (or_value_box *)tempStackPush:(or_value_box *)var;
- (or_value_box *)tempStackTopVar;
- (or_value_box *)tempStackSeek:(mem_cursor)beforeTop;

- (or_value *)opStackPop;
- (void)opStackWriteTop:(or_value)var;
- (void)opStackPush:(or_value)var;
- (or_value *)opStackTopVar;
- (or_value *)opStackSeek:(mem_cursor)beforeTop;

@property (nonatomic, strong)ORCallFrameStack *callFrameStack;
+ (instancetype)current;
@end

NS_ASSUME_NONNULL_END
