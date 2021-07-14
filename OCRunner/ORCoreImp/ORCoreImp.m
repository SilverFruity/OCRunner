//
//  ORImp.m
//  OCRunner
//
//  Created by Jiang on 2020/6/8.
//  Copyright © 2020 SilverFruity. All rights reserved.
//

#import "ORCoreImp.h"
#import "MFValue.h"
#import <objc/message.h>
#import "RunnerClasses+Execute.h"
#import "MFMethodMapTable.h"
#import "MFPropertyMapTable.h"

#import "util.h"
#import "ORInterpreter.h"
#import "ORCoreFunctionCall.h"
#import "ThreadContext.hpp"

void methodIMP(ffi_cif *cfi,void *ret,void **args, void*userdata){
    MFScopeChain *scope = [MFScopeChain scopeChainWithNext:[MFScopeChain topScope]];
    ORMethodNode *methodImp = (__bridge ORMethodNode *)userdata;
    __unsafe_unretained id target = *(__unsafe_unretained id *)args[0];
    SEL sel = *(SEL *)args[1];
    ORInterpreter *inter = [ORInterpreter shared];
    NSMethodSignature *sig = [target methodSignatureForSelector:sel];
    
    ThreadContext *ctx = (ThreadContext *)thread_current_context();
    ctx->enter_call();
    ctx->push_localvar(*args, sizeof(void *));
    ctx->push_localvar(*(args + 1), sizeof(SEL));
    for (NSUInteger i = 2; i < sig.numberOfArguments; i++) {
        const char *typeencode = [sig getArgumentTypeAtIndex:i];
        void *arg = args[i];
        //针对系统传入的block，检查一次签名，如果没有，将在结构体中添加签名信息.
        if (isObjectWithTypeEncode(typeencode)
            && isBlockWithTypeEncode(typeencode)
            && arg != NULL) {
            struct MFSimulateBlock *bb = (struct MFSimulateBlock *)arg;
            // 针对传入的block，如果为全局block或栈block，使用copy转换为堆block
            if (bb->isa == &_NSConcreteGlobalBlock || bb->isa == &_NSConcreteStackBlock){
                arg = Block_copy(arg);
            }
            if (NSBlockHasSignature(arg) == NO) {
                ORDeclaratorNode *blockdecl = methodImp.declare.parameters[i - 2];
                if ([blockdecl isKindOfClass:[ORFunctionDeclNode class]]) {
                    NSBlockSetSignature(arg, blockdecl.symbol.decl.typeEncode);
                }
            }
        }
        ctx->push_localvar(arg, sizeof(void *));
    }
    eval(inter, ctx, scope, methodImp);
    ctx->exit_call();
    
    or_value value = *ctx->op_stack_pop();
    
    if (sel == NSSelectorFromString(@"dealloc")) {
        Method deallocMethod = class_getInstanceMethod(object_getClass(target), NSSelectorFromString(@"ORGdealloc"));
        void (*originalDealloc)(__unsafe_unretained id, SEL) = (__typeof__(originalDealloc))method_getImplementation(deallocMethod);
        originalDealloc(target, NSSelectorFromString(@"dealloc"));
    }
    if (isVoidWithTypeEncode(value.typeencode) == NO && *value.pointer != NULL){
        // 类型转换
        or_value_write_to(value, ret, [sig methodReturnType]);
    }
}

void blockInter(ffi_cif *cfi,void *ret,void **args, void*userdata){
    ThreadContext *ctx = (ThreadContext *)thread_current_context();
    struct MFSimulateBlock *block = *(struct MFSimulateBlock **)args[0];
    MFBlock *mangoBlock =  (__bridge MFBlock *)(block->wrapper);
    NSMethodSignature *sig = [NSMethodSignature signatureWithObjCTypes:NSBlockGetSignature((__bridge  void *)mangoBlock.ocBlock)];
    NSMutableArray<MFValue *> *argValues = [NSMutableArray array];
    for (NSUInteger i = 1; i < cfi->nargs; i++) {
        or_value arg = or_value_create([sig getArgumentTypeAtIndex:i], args[i]);
//        [argValues addObject:argValue];
    }
    eval([ORInterpreter shared], ctx, mangoBlock.outScope, mangoBlock.func);
    or_value value = *ctx->op_stack_pop();
    if (isVoidWithTypeEncode(value.typeencode) && *value.pointer != NULL){
        // 类型转换
        or_value_write_to(value, ret, [sig methodReturnType]);
    }
}


void getterImp(ffi_cif *cfi,void *ret,void **args, void*userdata){
    id target = *(__strong id *)args[0];
    SEL sel = *(SEL *)args[1];
    ORPropertyNode *propDef = (__bridge ORPropertyNode *)userdata;
    NSString *propName = propDef.var.var.varname;
    NSMethodSignature *sig = [target methodSignatureForSelector:sel];
    __autoreleasing MFValue *propValue = objc_getAssociatedObject(target, mf_propKey(propName));
    or_value value = or_value_create(propValue.typeEncode, propValue.pointer);
    if (propValue.type != OCTypeVoid && propValue.pointer != NULL){
        or_value_write_to(value, ret, sig.methodReturnType);
    }
}

void setterImp(ffi_cif *cfi,void *ret,void **args, void*userdata){
    id target = *(__strong id *)args[0];
    SEL sel = *(SEL *)args[1];
    const char *argTypeEncode = [[target methodSignatureForSelector:sel] getArgumentTypeAtIndex:2];
    or_value orvalue = or_value_create(argTypeEncode, args[2]);
    MFValue *value = [MFValue valueWithORValue:&orvalue];
    ORPropertyNode *propDef = (__bridge ORPropertyNode *)userdata;
    MFPropertyModifier modifier = propDef.symbol.decl.propModifer;
    if (modifier & MFPropertyModifierMemWeak) {
        value.modifier = DeclarationModifierWeak;
    }
    objc_AssociationPolicy associationPolicy = mf_AssociationPolicy_with_PropertyModifier(modifier);
    objc_setAssociatedObject(target, mf_propKey(propDef.var.var.varname), value, associationPolicy);
}


//MFValue *invoke_sueper_values(id instance, SEL sel, NSArray<MFValue *> *argValues){
//    BOOL isClassMethod = object_isClass(instance);
//    Class superClass;
//    if (isClassMethod) {
//        superClass = class_getSuperclass(instance);
//    }else{
//        superClass = class_getSuperclass([instance class]);
//    }
//    struct objc_super *superPtr = &(struct objc_super){instance,superClass};
//    NSMutableArray *args = [@[[MFValue valueWithPointer:(void *)superPtr],[MFValue valueWithSEL:sel]] mutableCopy];
//    [args addObjectsFromArray:argValues];
//    NSMethodSignature *sig = [instance methodSignatureForSelector:sel];
//    MFValue *retValue = [MFValue defaultValueWithTypeEncoding:sig.methodReturnType];
//    void *funcptr = &objc_msgSendSuper;
//    invoke_functionPointer(funcptr, args, retValue);
//    return retValue;
//}
