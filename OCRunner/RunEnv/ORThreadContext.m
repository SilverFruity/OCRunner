//
//  ORThreadContext.m
//  OCRunner
//
//  Created by Jiang on 2021/6/4.
//

#import "ORThreadContext.h"
#import "MFValue.h"
#import "MFScopeChain.h"
@interface ORCallFrameStack()
@property(nonatomic, strong) NSMutableArray<NSArray *> *array;
@end
@implementation ORCallFrameStack
- (instancetype)init
{
    self = [super init];
    if (self) {
        self.array = [NSMutableArray array];
    }
    return self;
}
+ (void)pushMethodCall:(ORMethodNode *)imp instance:(MFValue *)instance{
    [[ORCallFrameStack threadStack].array addObject:@[instance, imp]];
}
+ (void)pushFunctionCall:(ORFunctionNode *)imp scope:(MFScopeChain *)scope{
    [[ORCallFrameStack threadStack].array addObject:@[scope, imp]];
}
+ (void)pop{
    [[ORCallFrameStack threadStack].array removeLastObject];
}

+ (NSString *)history{
    NSMutableArray *frames = [ORCallFrameStack threadStack].array;
    NSMutableString *log = [@"OCRunner Frames:\n\n" mutableCopy];
//    for (int i = 0; i < frames.count; i++) {
//        NSArray *frame = frames[i];
//        if ([frame.firstObject isKindOfClass:[MFValue class]]) {
//            MFValue *instance = frame.firstObject;
//            ORMethodNode *imp = frame.lastObject;
//            
//            [log appendFormat:@"%@ %@ %@\n", imp.declare.isClassMethod ? @"+" : @"-", instance.objectValue, imp.declare.selectorName];
//        }else{
//            MFScopeChain *scope = frame.firstObject;
//            ORFunctionNode *imp = frame.lastObject;
//            if (imp.declare.var.varname == nil){
//                [log appendFormat:@"Block Call: Captured external variables '%@' \n",[scope.vars.allKeys componentsJoinedByString:@","]];
//                // 比如dispatch_after中的block，此时只会孤零零的提醒你一个Block Call
//                // 异步调用时，此时通过语法树回溯，可以定位到 block 所在的类以及方法名
//                if (i == 0) {
//                    ORNode *parent = imp.parentNode;
//                    while (parent != nil ) {
//                        if ([parent isKindOfClass:[ORClassNode class]]) {
//                            [log appendFormat:@"Block Code in Class: %@\n", [(ORClassNode *)parent className]];
//                        }else if ([parent isKindOfClass:[ORMethodNode class]]){
//                            ORMethodNode *imp = (ORMethodNode *)parent;
//                            [log appendFormat:@"Block Code in Method: %@%@\n", imp.declare.isClassMethod ? @"+" : @"-", imp.declare.selectorName];
//                        }else if ([parent isKindOfClass:[ORFunctionCall class]]){
//                            ORFunctionCall *imp = (ORFunctionCall *)parent;
//                            [log appendFormat:@"Block Code in Function call: %@\n", [(ORValueNode *)imp.caller value]];
//                        }else if ([parent isKindOfClass:[ORMethodCall class]]){
//                            ORMethodCall *imp = (ORMethodCall *)parent;
//                            [log appendFormat:@"Block Code in Method call: %@\n", imp.selectorName];
//                        }else if ([parent isKindOfClass:[ORInitDeclaratorNode class]]){
//                            ORInitDeclaratorNode *imp = (ORInitDeclaratorNode *)parent;
//                            [log appendFormat:@"Block Code in Decl: %@ %@\n", imp.declarator.type.name, imp.declarator.var.varname];
//                        }
//                        parent = parent.parentNode;
//                    }
//                }
//            }else{
//                [log appendFormat:@" CFunction: %@\n", imp.declare.var.varname];
//            }
//        }
//    }
    return log;
}
@end

@interface ORArgsStack()
@property(nonatomic, strong) NSMutableArray<NSMutableArray *> *array;
@end
@implementation ORArgsStack
- (instancetype)init{
    if (self = [super init]) {
        _array = [NSMutableArray array];
    }
    return self;
}

+ (void)push:(NSMutableArray <MFValue *> *)value{
    NSAssert(value, @"value can not be nil");
    [ORArgsStack.threadStack.array addObject:value];
}

+ (NSMutableArray <MFValue *> *)pop{
    NSMutableArray *value = [ORArgsStack.threadStack.array  lastObject];
    NSAssert(value, @"stack is empty");
    [ORArgsStack.threadStack.array removeLastObject];
    return value;
}
+ (BOOL)isEmpty{
    return [ORArgsStack.threadStack.array count] == 0;
}
+ (NSUInteger)size{
    return ORArgsStack.threadStack.array.count;
}
@end
ORThreadContext *thread_ctx_create(void){
    ORThreadContext *ctx = malloc(sizeof(ORThreadContext));
    ctx->sp = 0;
    ctx->lr = 0;
    ctx->cursor = 0;
    size_t mem_size = 1024 * sizeof(machine_mem);
    ctx->mem = malloc(mem_size);
    ctx->mem_end = ctx->mem + mem_size;
    ctx->op_mem = malloc(mem_size);
    ctx->op_mem_end = (or_value *)((char *)ctx->op_mem + mem_size);
    ctx->op_mem_top = 0;
    ctx->op_temp_mem = malloc(mem_size);
    ctx->op_temp_mem_end = (or_value_box *)((char *)ctx->op_temp_mem + mem_size);
    ctx->op_temp_mem_top = 0;
    return ctx;
}
ORThreadContext *current_thread_context(void){
    //每一个线程拥有一个独立的上下文
    NSMutableDictionary *threadInfo = [[NSThread currentThread] threadDictionary];
    ORThreadContext *ctx = [threadInfo[@"ORThreadContext"] pointerValue];
    if (!ctx) {
        ctx = thread_ctx_create();
        threadInfo[@"ORThreadContext"] = [NSValue valueWithPointer:ctx];
    }
    return ctx;
}
machine_mem thread_ctx_push_localvar(ORThreadContext *ctx, void *var, size_t size){
    machine_mem dst = ctx->mem + ctx->sp + ctx->cursor;
    assert(dst < ctx->mem_end);
    assert(var != NULL);
    if (*(void **)var != NULL) {
        memcpy(dst, var , size);
    }else{
        memset(dst, 0, size);
    }
    ctx->cursor += MAX(size, 8);
    return dst;
}
void *thread_ctx_seek_localvar(ORThreadContext *ctx, mem_cursor offset){
    return ctx->mem + ctx->sp + offset;
}
void thread_ctx_enter_call(ORThreadContext *ctx){
    ctx->lr = ctx->sp + ctx->cursor;
    assert(ctx->mem + ctx->lr < ctx->mem_end);
    memcpy(ctx->mem + ctx->lr, &ctx->sp, sizeof(mem_cursor));
    ctx->sp = ctx->lr + sizeof(mem_cursor);
    ctx->cursor = 0;
}
void thread_ctx_exit_call(ORThreadContext *ctx){
    mem_cursor before = ctx->lr;
    memcpy(&ctx->sp, ctx->mem + ctx->lr, sizeof(mem_cursor));
    if (ctx->sp == 0) {
        ctx->lr = 0;
        ctx->cursor = 0;
    }else{
        ctx->lr = ctx->sp - sizeof(mem_cursor);
    }
    ctx->cursor = before - ctx->sp;
}
bool thread_ctx_is_calling(ORThreadContext *ctx){
    if (ctx->lr == ctx->sp) return false;
    return true;
}

void thread_ctx_temp_mem_pop(ORThreadContext *ctx){
    ctx->op_temp_mem_top--;
}
or_value_box *thread_ctx_tempmem_write_top(ORThreadContext *ctx, or_value_box *var){
    ctx->op_temp_mem[ctx->op_temp_mem_top] = *var;
    return ctx->op_temp_mem + ctx->op_temp_mem_top;
}
or_value_box *thread_ctx_tempmem_push(ORThreadContext *ctx, or_value_box *var){
    ctx->op_temp_mem[ctx->op_temp_mem_top++] = *var;
    assert(ctx->op_mem + ctx->op_temp_mem_top < ctx->op_mem_end);
    return ctx->op_temp_mem + ctx->op_temp_mem_top - 1;
}
or_value_box *thread_ctx_tempmem_top_var(ORThreadContext *ctx){
    return ctx->op_temp_mem + ctx->op_temp_mem_top;
}
or_value_box *thread_ctx_tempmem_seek(ORThreadContext *ctx, mem_cursor beforeTop){
    return ctx->op_temp_mem + ctx->op_temp_mem_top - beforeTop;
}

or_value * thread_ctx_op_stack_pop(ORThreadContext *ctx){
    thread_ctx_temp_mem_pop(ctx);
    ctx->op_mem_top--;
    return ctx->op_mem + ctx->op_mem_top;
}
void thread_ctx_op_stack_write_top(ORThreadContext *ctx, or_value var){
    var.pointer = (void *)thread_ctx_tempmem_write_top(ctx, &var.box);
    ctx->op_mem[ctx->op_mem_top] = var;
}
void thread_ctx_op_stack_push(ORThreadContext *ctx, or_value var){
    var.pointer = (void *)thread_ctx_tempmem_push(ctx, &var.box);
    ctx->op_mem[ctx->op_mem_top++] = var;
    assert(ctx->op_mem + ctx->op_mem_top < ctx->op_mem_end);
}
or_value * thread_ctx_op_stack_top_var(ORThreadContext *ctx){
    return ctx->op_mem + ctx->op_mem_top;
}
or_value * thread_ctx_op_stack_seek(ORThreadContext *ctx, mem_cursor beforeTop){
    return ctx->op_mem + ctx->op_mem_top - 1 - beforeTop;
}

