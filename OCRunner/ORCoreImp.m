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
#import "ORStructDeclare.h"

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
    void *intArgs[8];
    void *floatArgs[8];
    __asm__ volatile
    (
     "stp x0, x1, [%[iargs]]\n"
     "stp x2, x3, [%[iargs], 16]\n"
     "stp x4, x5, [%[iargs], 32]\n"
     "stp x6, x7, [%[iargs], 48]\n"
     "stp d0, d1, [%[fargs]]\n"
     "stp d2, d3, [%[fargs], 16]\n"
     "stp d4, d5, [%[fargs], 32]\n"
     "stp d6, d7, [%[fargs], 48]\n"
     :
     : [iargs]"r"(intArgs), [fargs]"r"(floatArgs)
     );
    NSMethodSignature *sig = [NSMethodSignature signatureWithObjCTypes:block->descriptor->signature];
    NSUInteger numberOfArguments = [sig numberOfArguments];
    MFBlock *mangoBlock =  (__bridge MFBlock *)(block->wrapper);
    // 在OC中，传入值都为原数值并非MFValue，需要转换
    NSMutableArray *argValues = [NSMutableArray array];
    for (NSUInteger i = 1; i < numberOfArguments ; i++) {
        void *arg = intArgs[i];
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
//NOTE: https://developer.arm.com/documentation/100986/0000 #Procedure Call Standard for the ARM 64-bit Architecture
//NOTE: https://juejin.im/post/5d14623ef265da1bb47d7635#heading-12
#define G_REG_SIZE 8
#define V_REG_SIZE 8
#define N_G_ARG_REG 8 // The Number Of General Register
#define N_V_ARG_REG 8 // The Number Of Float-Point Register
#define ARGS_SIZE N_V_ARG_REG*V_REG_SIZE+N_G_ARG_REG*G_REG_SIZE
typedef struct{
    NSUInteger NGRN;
    NSUInteger NSRN;
    NSUInteger NSAA;
}CallRegisterState;

typedef struct {
    CallRegisterState *state;
    void *generalRegister;
    void *floatRegister;
    char *stackMemeries;
}CallContext;

void prepareForStackSize(MFValue *arg, CallRegisterState *state){
    if (arg.isInteger || arg.isPointer || arg.isObject) {
        if (state->NGRN < N_G_ARG_REG) {
            state->NGRN++;
            return;
        }
        state->NGRN = N_G_ARG_REG;
        state->NSAA += (arg.memerySize + 7) / 8;
    }else if (arg.isFloat) {
        if (state->NSRN < N_V_ARG_REG) {
            state->NSRN++;
            return;
        }
        state->NSRN = N_V_ARG_REG;
        state->NSAA += (arg.memerySize + 7) / 8;
    // Composite Types
    // aggregate: struct and array
    }else if (arg.isStruct) {
        if (arg.isHFAStruct) {
            //FIXME: only in iOS ???
            if (arg.memerySize > 32) {
                MFValue *copied = [MFValue valueWithPointer:arg.pointer];
                prepareForStackSize(copied, state);
                return;
            }
            NSUInteger argCount = arg.structLayoutFieldCount;
            if (state->NSRN + argCount <= N_V_ARG_REG) {
                //set args to float register
                state->NSRN += argCount;
                return;
            }
            state->NSRN = N_V_ARG_REG;
            state->NSAA += (arg.memerySize + 7) / 8;
        }else if (arg.memerySize > 16){
            MFValue *copied = [MFValue valueWithPointer:arg.pointer];
            prepareForStackSize(copied, state);
        }else{
            NSUInteger memsize = arg.memerySize;
            NSUInteger needGRN = (memsize + 7) / 8;
            if (8 - state->NGRN >= needGRN) {
                //set args to general register
                state->NGRN += needGRN;
                return;
            }
            state->NGRN = N_V_ARG_REG;
            state->NSAA += (arg.memerySize + 7) / 8;
        }
    }
}

void structStoeInRegister(BOOL isHFA, MFValue *aggregate, CallContext ctx){
    [aggregate enumerateStructFieldsUsingBlock:^(MFValue * _Nonnull field, NSUInteger idx, BOOL *stop) {
        if (field.isStruct) {
            structStoeInRegister(isHFA, field, ctx);
            *stop = YES;
        }
        CallRegisterState *state = ctx.state;
        void *pointer = field.pointer;
        if (isHFA) {
            memcpy(ctx.floatRegister+state->NSRN, pointer, field.memerySize);
            state->NSRN++;
        }else{
            memcpy(ctx.generalRegister+state->NGRN, pointer, field.memerySize);
            state->NGRN++;
        }
    }];
}
void flatMapArgument(MFValue *arg, CallContext ctx){
    CallRegisterState *state = ctx.state;
    if (arg.isInteger || arg.isPointer || arg.isObject) {
        if (state->NGRN < N_G_ARG_REG) {
            void *pointer = arg.pointer;
            memcpy(ctx.generalRegister + state->NGRN, pointer, arg.memerySize);
            state->NGRN++;
            return;
        }else{
            state->NGRN = N_G_ARG_REG;
            void *pointer = arg.pointer;
            memcpy(ctx.stackMemeries + state->NSAA, pointer, arg.memerySize);
            state->NSAA += (arg.memerySize + 7) / 8;
            return;
        }
    }else if (arg.isFloat) {
        if (state->NSRN < N_V_ARG_REG) {
            void *pointer = arg.pointer;
            memcpy(ctx.floatRegister+state->NSRN, pointer, arg.memerySize);
            state->NSRN++;
            return;
        }else{
            state->NSRN = N_V_ARG_REG;
            void *pointer = arg.pointer;
            memcpy(ctx.stackMemeries + state->NSAA, pointer, arg.memerySize);
            state->NSAA += (arg.memerySize + 7) / 8;
            return;
        }
    // Composite Types
    // aggregate: struct and array
    }else if (arg.isStruct) {
        if (arg.isHFAStruct) {
            //FIXME: only in iOS ???
            if (arg.memerySize > 32) {
                MFValue *copied = [MFValue valueWithPointer:arg.pointer];
                flatMapArgument(copied, ctx);
                return;
            }
            NSUInteger argCount = arg.structLayoutFieldCount;
            if (state->NSRN + argCount <= N_V_ARG_REG) {
                //set args to float register
                structStoeInRegister(YES, arg, ctx);
                return;
            }else{
                state->NSRN = N_V_ARG_REG;
                void *pointer = arg.pointer;
                memcpy(ctx.stackMemeries + state->NSAA, pointer, arg.memerySize);
                state->NSAA += (arg.memerySize + 7) / 8;
                return;
            }
        }else if (arg.memerySize > 16){
            MFValue *copied = [MFValue valueWithPointer:arg.pointer];
            flatMapArgument(copied, ctx);
        }else{
            NSUInteger memsize = arg.memerySize;
            NSUInteger needGRN = (memsize + 7) / 8;
            if (8 - state->NGRN >= needGRN) {
                //set args to general register
                structStoeInRegister(NO, arg, ctx);
                return;
            }else{
                state->NGRN = N_V_ARG_REG;
                void *pointer = arg.pointer;
                memcpy(ctx.stackMemeries + state->NSAA, pointer, arg.memerySize);
                state->NSAA += (arg.memerySize + 7) / 8;
                return;
            }
        }
    }
}
void invoke_functionPointer(void *funptr, NSArray<MFValue *> *argValues, void **ret){
    if (funptr == NULL) {
        return;
    }
    void *CSP = NULL;
    __asm__ volatile
    (
    "mov %[csp], sp\n"
    : [csp]"=r"(CSP)
    :
    );
    NSMutableArray *args = [argValues mutableCopy];
    CallRegisterState prepareState = { 0 , 0 , 0};
    for (MFValue *arg in args) {
        prepareForStackSize(arg, &prepareState);
    }
    NSUInteger stackSize = prepareState.NSAA;
    NSUInteger floatRegistersSize = N_V_ARG_REG*V_REG_SIZE;
    NSUInteger generalRegistersSize = N_G_ARG_REG*G_REG_SIZE;
    char *stack = alloca(floatRegistersSize + generalRegistersSize + stackSize);
    memset(stack, 0, floatRegistersSize + generalRegistersSize + stackSize);
    CallRegisterState state = { 0 , 0 , 0};;
    CallContext context;
    context.state = &state;
    context.floatRegister = (void *)stack;
    context.generalRegister = stack + floatRegistersSize;
    context.stackMemeries = stack + floatRegistersSize + generalRegistersSize;
    for (MFValue *arg in args) {
        flatMapArgument(arg, context);
    }
    void *result = NULL;
    __asm__ volatile
    (
     "mov sp, %[stack]\n"
     "ldp d0, d1, [sp]\n"
     "ldp d2, d3, [sp, 16]\n"
     "ldp d4, d5, [sp, 32]\n"
     "ldp d6, d7, [sp, 48]\n"
     "ldp x0, x1, [sp, 64 + 0]\n"  // 64: N_V_ARG_REG*V_REG_SIZE
     "ldp x2, x3, [sp, 64 + 16]\n" // 64: N_V_ARG_REG*V_REG_SIZE
     "ldp x4, x5, [sp, 64 + 32]\n" // 64: N_V_ARG_REG*V_REG_SIZE
     "ldp x6, x7, [sp, 64 + 48]\n" // 64: N_V_ARG_REG*V_REG_SIZE
     "add sp, sp, 128\n" // 128: ARGS_SIZE
     "blr %[func]\n"
     "mov %[result], x8\n"
     "mov sp, %[csp]\n"
     : [result]"=r"(result)
     : [func]"r"(funptr), [stack]"r"(stack), [csp]"r"(CSP)
     );
    if (ret != NULL) {
        *ret = result;
    }
}
