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
#import "ORTypeVarPair+TypeEncode.h"
#import "util.h"
#import "ORInterpreter.h"
#import "ORCoreFunctionCall.h"
void methodIMP(ffi_cif *cfi,void *ret,void **args, void*userdata){
    MFScopeChain *scope = [MFScopeChain scopeChainWithNext:[MFScopeChain topScope]];
    ORMethodNode *methodImp = (__bridge ORMethodNode *)userdata;
    __unsafe_unretained id target = *(__unsafe_unretained id *)args[0];
    SEL sel = *(SEL *)args[1];
    BOOL classMethod = object_isClass(target);
    ORThreadContext *ctx = [ORThreadContext current];
    NSMethodSignature *sig = [target methodSignatureForSelector:sel];
    NSMutableArray<MFValue *> *argValues = [NSMutableArray array];
    
    [ctx enter];
    [ctx pushLocalVar:args size:sizeof(void *)];
    [ctx pushLocalVar:args + 1 size:sizeof(SEL)];
    
    for (NSUInteger i = 2; i < sig.numberOfArguments; i++) {
        or_value argValue = or_value_create([sig getArgumentTypeAtIndex:i], args[i]);
        //针对系统传入的block，检查一次签名，如果没有，将在结构体中添加签名信息.
        
        if (isObjectWithTypeEncode(argValue.typeencode)
            && isBlockWithTypeEncode(argValue.typeencode)
            && *argValue.pointer != NULL) {
            struct MFSimulateBlock *bb = (void *)argValue.box.pointerValue;
            // 针对传入的block，如果为全局block或栈block，使用copy转换为堆block
            if (bb->isa == &_NSConcreteGlobalBlock || bb->isa == &_NSConcreteStackBlock){
                id copied = (__bridge id)Block_copy(argValue.box.pointerValue);
                or_value_set_pointer(&argValue, &copied);
            }
            
            if (NSBlockHasSignature(*argValue.pointer) == NO) {
                ORDeclaratorNode *blockdecl = methodImp.declare.parameters[i - 2];
                if ([blockdecl isKindOfClass:[ORFunctionDeclNode class]]) {
                    NSBlockSetSignature(*argValue.pointer, blockdecl.blockSignature);
                }
            }
        }
//        [argValues addObject:argValue];
    }
    if (classMethod) {
        or_Class_value(target);
//        scope.instance = [MFValue valueWithClass:target];
    }else{
        // 方法调用时不应该增加引用计数
        or_Object_value(target);
//        scope.instance = [MFValue valueWithUnownedObject:target];
    }
    or_value value;
    [ORArgsStack push:argValues];
    
    eval([ORInterpreter shared], ctx, scope, methodImp);
    value = *[ctx opStackPop];
    
    if (sel == NSSelectorFromString(@"dealloc")) {
        Method deallocMethod = class_getInstanceMethod(object_getClass(target), NSSelectorFromString(@"ORGdealloc"));
        void (*originalDealloc)(__unsafe_unretained id, SEL) = (__typeof__(originalDealloc))method_getImplementation(deallocMethod);
        originalDealloc(target, NSSelectorFromString(@"dealloc"));
    }
    if (isVoidWithTypeEncode(value.typeencode) && *value.pointer != NULL){
        // 类型转换
        or_value_write_to(value, ret, [sig methodReturnType]);
    }
}

void blockInter(ffi_cif *cfi,void *ret,void **args, void*userdata){
    ORThreadContext *ctx = [ORThreadContext current];
    struct MFSimulateBlock *block = *(void **)args[0];
    MFBlock *mangoBlock =  (__bridge MFBlock *)(block->wrapper);
    NSMethodSignature *sig = [NSMethodSignature signatureWithObjCTypes:NSBlockGetSignature((__bridge  void *)mangoBlock.ocBlock)];
    NSMutableArray<MFValue *> *argValues = [NSMutableArray array];
    for (NSUInteger i = 1; i < cfi->nargs; i++) {
        or_value arg = or_value_create([sig getArgumentTypeAtIndex:i], args[i]);
//        [argValues addObject:argValue];
    }
    or_value value;
    [ORArgsStack push:argValues];
    eval([ORInterpreter shared], [ORThreadContext current], mangoBlock.outScope, mangoBlock.func);
    value = *[ctx opStackPop];
    if (isVoidWithTypeEncode(value.typeencode) && *value.pointer != NULL){
        // 类型转换
        or_value_write_to(value, ret, [sig methodReturnType]);
    }
}


//void getterImp(ffi_cif *cfi,void *ret,void **args, void*userdata){
//    id target = *(__strong id *)args[0];
//    SEL sel = *(SEL *)args[1];
//    ORPropertyNode *propDef = (__bridge ORPropertyNode *)userdata;
//    NSString *propName = propDef.var.var.varname;
//    NSMethodSignature *sig = [target methodSignatureForSelector:sel];
//    __autoreleasing MFValue *propValue = objc_getAssociatedObject(target, mf_propKey(propName));
//    if (!propValue) {
//        propValue = [MFValue defaultValueWithTypeEncoding:propDef.var.typeEncode];
//    }
//    if (propValue.type != OCTypeVoid && propValue.pointer != NULL){
//        [propValue writePointer:ret typeEncode:sig.methodReturnType];
//    }
//}

//void setterImp(ffi_cif *cfi,void *ret,void **args, void*userdata){
//    id target = *(__strong id *)args[0];
//    SEL sel = *(SEL *)args[1];
//    const char *argTypeEncode = [[target methodSignatureForSelector:sel] getArgumentTypeAtIndex:2];
//    MFValue *value = [MFValue valueWithTypeEncode:argTypeEncode pointer:args[2]];
//    ORPropertyNode *propDef = (__bridge ORPropertyNode *)userdata;
//    NSString *propName = propDef.var.var.varname;
//    MFPropertyModifier modifier = propDef.modifier;
//    if (modifier & MFPropertyModifierMemWeak) {
//        value.modifier = DeclarationModifierWeak;
//    }
//    objc_AssociationPolicy associationPolicy = mf_AssociationPolicy_with_PropertyModifier(modifier);
//    objc_setAssociatedObject(target, mf_propKey(propName), value, associationPolicy);
//}


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
