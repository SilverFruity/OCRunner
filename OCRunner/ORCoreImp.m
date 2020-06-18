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
#import "MFWeakPropertyBox.h"
#import "MFMethodMapTable.h"
#import "MFPropertyMapTable.h"
#import "ORTypeVarPair+TypeEncode.h"
#import "util.h"

void methodIMP(void){
    void *args[8];
    __asm__ volatile
    (
     "str x0, [%[args]]\n"
     "str x1, [%[args], #0x8]\n"
     "str x2, [%[args], #0x10]\n"
     "str x3, [%[args], #0x18]\n"
     "str x4, [%[args], #0x20]\n"
     "str x5, [%[args], #0x28]\n"
     "str x6, [%[args], #0x30]\n"
     "str x7, [%[args], #0x38]\n"
     :
     : [args]"r"(args)
     );
    MFScopeChain *scope = [MFScopeChain topScope];
    id target = (__bridge id) args[0];
    SEL sel = (SEL)args[1];
    BOOL classMethod = object_isClass(target);
    Class class;
    if (classMethod) {
        [scope setValue:[MFValue valueWithClass:target] withIndentifier:@"self"];
        class = objc_getMetaClass(NSStringFromClass(target).UTF8String);
    }else{
        [scope setValue:[MFValue valueWithObject:target] withIndentifier:@"self"];
        class = [target class];
    }
    MFMethodMapTableItem *map = [[MFMethodMapTable shareInstance] getMethodMapTableItemWith:class classMethod:classMethod sel:sel];
    NSMethodSignature *methodSignature = [target methodSignatureForSelector:sel];
    NSMutableArray<MFValue *> *argValues = [NSMutableArray array];
    NSUInteger numberOfArguments = [methodSignature numberOfArguments];
    // 在OC中，传入值都为原数值并非MFValue，需要转换
    for (NSUInteger i = 2; i < numberOfArguments; i++) {
        void *arg = args[i];
        MFValue *argValue = [[MFValue alloc] initTypeEncode:[methodSignature getArgumentTypeAtIndex:i] pointer:&arg];
        [argValues addObject:argValue];
    }
    [[MFStack argsStack] push:argValues];
    MFValue *value = [map.methodImp execute:scope];
    __autoreleasing MFValue *retValue = [MFValue defaultValueWithTypeEncoding:[methodSignature methodReturnType]];
    for (MFValue *value in argValues) {
        [value release];
    }
    if (retValue.type == TypeVoid){
        return;
    }
    retValue.pointer = value.pointer;
    void *result = *(void **)retValue.pointer;
    __asm__ volatile
    (
     "mov x0, %[ret]\n"
     :
     : [ret]"r"(result)
     );
}

void blockInter(struct MFSimulateBlock *block){
    void *args[8];
    __asm__ volatile
    (
     "str x0, [%[args]]\n"
     "str x1, [%[args], #0x8]\n"
     "str x2, [%[args], #0x10]\n"
     "str x3, [%[args], #0x18]\n"
     "str x4, [%[args], #0x20]\n"
     "str x5, [%[args], #0x28]\n"
     "str x6, [%[args], #0x30]\n"
     "str x7, [%[args], #0x38]\n"
     :
     : [args]"r"(args)
     );
    NSMethodSignature *sig = [NSMethodSignature signatureWithObjCTypes:block->descriptor->signature];
    NSUInteger numberOfArguments = [sig numberOfArguments];
    MFBlock *mangoBlock =  (__bridge MFBlock *)(block->wrapper);
    // 在OC中，传入值都为原数值并非MFValue，需要转换
    NSMutableArray *argValues = [NSMutableArray array];
    for (NSUInteger i = 1; i < numberOfArguments ; i++) {
        void *arg = args[i];
        MFValue *argValue = [[MFValue alloc] initTypeEncode:[sig getArgumentTypeAtIndex:i] pointer:&arg];
        [argValues addObject:argValue];
    }
    [[MFStack argsStack] push:argValues];
    MFValue *value = [mangoBlock.func execute:mangoBlock.outScope];
    __autoreleasing MFValue *retValue = [MFValue defaultValueWithTypeEncoding:[sig methodReturnType]];
    for (MFValue *value in argValues) {
        [value release];
    }
    if (retValue.type == TypeVoid){
        return;
    }
    retValue.pointer = value.pointer;
    void *result = *(void **)retValue.pointer;
    __asm__ volatile
    (
     "mov x0, %[ret]\n"
     :
     : [ret]"r"(result)
     );
}


void getterImp(id target, SEL sel){
    NSString *propName = NSStringFromSelector(sel);
    ORPropertyDeclare *propDef = [[MFPropertyMapTable shareInstance] getPropertyMapTableItemWith:[target class] name:propName].property;
    const char *type = propDef.var.typeEncode;
    __autoreleasing MFValue *propValue = objc_getAssociatedObject(target, mf_propKey(propName));
    if (!propValue) {
        propValue = [MFValue defaultValueWithTypeEncoding:type];
    }
    if (propValue.type == TypeVoid){
        return;
    }
    void *result = *(void **)propValue.pointer;
    __asm__ volatile
    (
     "mov x0, %[ret]\n"
     :
     : [ret]"r"(result)
     );
}

void setterImp(id target, SEL sel, void *newValue){
    NSMethodSignature *sign = [target methodSignatureForSelector:sel];
    const char *type = [sign getArgumentTypeAtIndex:2];
    MFValue *value = [MFValue defaultValueWithTypeEncoding:type];
    value.pointer = &newValue;
    NSString *setter = NSStringFromSelector(sel);
    NSString *name = [setter substringWithRange:NSMakeRange(3, setter.length - 4)];
    NSString *first = [name substringWithRange:NSMakeRange(0, 1)].lowercaseString;
    NSString *propName = [NSString stringWithFormat:@"%@%@",first,[name substringFromIndex:1]];
    ORPropertyDeclare *propDef = [[MFPropertyMapTable shareInstance] getPropertyMapTableItemWith:[target class] name:propName].property;
    MFPropertyModifier modifier = propDef.modifier;
    if (modifier & MFPropertyModifierMemWeak) {
        value.modifier = ORDeclarationModifierWeak;
    }
    objc_AssociationPolicy associationPolicy = mf_AssociationPolicy_with_PropertyModifier(modifier);
    objc_setAssociatedObject(target, mf_propKey(propName), value, associationPolicy);
}


MFValue *invoke_sueper_values(id instance, SEL sel, NSArray<MFValue *> *argValues){
    BOOL isClassMethod = object_isClass(instance);
    Class superClass;
    if (isClassMethod) {
        superClass = class_getSuperclass(instance);
    }else{
        superClass = class_getSuperclass([instance class]);
    }
    struct objc_super *superPtr = &(struct objc_super){instance,superClass};
    void *args[8] = { superPtr, sel, 0, 0, 0, 0, 0, 0};
    for (int i = 0 ; i < argValues.count; i++) {
        args[i + 2] = *(void **)argValues[i].pointer;
    }
    NSMethodSignature *sig = [instance methodSignatureForSelector:sel];
    __autoreleasing MFValue *retValue = [MFValue defaultValueWithTypeEncoding:sig.methodReturnType];
    void *result = NULL;
    __asm__ volatile
    (
     "ldr x0, [%[args]]\n"
     "ldr x1, [%[args], #0x8]\n"
     "ldr x2, [%[args], #0x10]\n"
     "ldr x3, [%[args], #0x18]\n"
     "ldr x4, [%[args], #0x20]\n"
     "ldr x5, [%[args], #0x28]\n"
     "ldr x6, [%[args], #0x30]\n"
     "ldr x7, [%[args], #0x38]\n"
     :
     : [args]"r"(args)
     );
    objc_msgSendSuper();
    __asm__ volatile
    (
     "mov %[result], x0\n"
     : [result]"=r"(result)
     :
     );
    retValue.pointer = &result;
    return retValue;
}

void *invoke_functionPointer(void *funptr, NSArray<MFValue *> *argValues, MFValue * returnValue){
    if (returnValue.isStruct) {
        return NULL;
    }
    for (MFValue *arg in argValues) {
        if (arg.isStruct) return NULL;
    }
    NSMutableArray <MFValue *>*intValues = [NSMutableArray array];
    NSMutableArray <MFValue *>*floatValues = [NSMutableArray array];
    [argValues enumerateObjectsUsingBlock:^(MFValue * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.isFloat) {
            [floatValues addObject:obj];
        }else{
            [intValues addObject:obj];
        }
    }];
    void *intArgs[8] = { 0, 0, 0, 0, 0, 0, 0, 0};
    void *floatArgs[8] = { 0, 0, 0, 0, 0, 0, 0, 0};
    for (int i = 0 ; i < intValues.count; i++) {
        intArgs[i] = *(void **)intValues[i].pointer;
    }
    for (int i = 0 ; i < floatValues.count; i++) {
        floatArgs[i] = *(void **)floatValues[i].pointer;
    }
    void *result = returnValue.pointer;
    __asm__ volatile
    (
     "ldp x0, x1, [%[iargs]]\n"
     "ldp x2, x3, [%[iargs], 16]\n"
     "ldp x4, x5, [%[iargs], 32]\n"
     "ldp x6, x7, [%[iargs], 48]\n"
     "ldp q0, q1, [%[fargs]]\n"
     "ldp q2, q3, [%[fargs], 16]\n"
     "ldp q4, q5, [%[fargs], 32]\n"
     "ldp q6, q7, [%[fargs], 48]\n"
     "blr x0\n"
     :
     : [iargs]"r"(intArgs), [fargs]"r"(floatArgs)
     );
    __asm__ volatile
    (
     "mov %[result], x0\n"
     : [result]"=r"(result)
     :
     );
    return result;
}
