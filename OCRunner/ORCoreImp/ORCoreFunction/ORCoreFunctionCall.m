//
//  ORCoreFunctionCall.m
//  OCRunner
//
//  Created by Jiang on 2020/7/9.
//  Copyright © 2020 SilverFruity. All rights reserved.
//

#import "ORCoreFunctionCall.h"
#import <Foundation/Foundation.h>
#import "MFValue.h"

#import <oc2mangoLib/ocHandleTypeEncode.h>
#import "ptrauth.h"
#import "ORCoreFunction.h"
#ifndef __libffi__
NSUInteger floatPointFlagsWithTypeEncode(const char * typeEncode){
    NSUInteger fieldCount = totalFieldCountWithTypeEncode(typeEncode);;
    if (fieldCount <= 4) {
        const char *fieldEncode;
        if (isStructWithTypeEncode(typeEncode)) {
             fieldEncode = detectStructMemeryLayoutEncodeCode(typeEncode).UTF8String;
        }else{
             fieldEncode = typeEncode;
        }
        NSUInteger offset = 0;
        switch (*fieldEncode) {
            case 'f':
                offset = 2;
                break;
            case 'd':
                offset = 3;
                break;
            default:
                break;
        }
        if (fieldEncode == typeEncode && offset == 0) {
            return 0;
        }
        //iOS没有LONGDOUBLE
        //Note that FFI_TYPE_FLOAT == 2, _DOUBLE == 3, _LONGDOUBLE == 4
        //#define AARCH64_RET_S4        8
        //#define AARCH64_RET_D4        12
        return offset * 4 + (4 - fieldCount);
    }
    return 0;
    
}
NSUInteger resultFlagsForTypeEncode(const char * retTypeEncode, char **argTypeEncodes, int narg){
    NSUInteger flag = 0;
    switch (*retTypeEncode) {
        case ':':
        case '*':
        case '#':
        case '^':
        case '@': flag = AARCH64_RET_INT64; break;
        case 'v': flag = AARCH64_RET_VOID; break;
        case 'C': flag = AARCH64_RET_UINT8; break;
        case 'S': flag = AARCH64_RET_UINT16; break;
        case 'I': flag = AARCH64_RET_UINT32; break;
        case 'L': flag = AARCH64_RET_INT64; break;
        case 'Q': flag = AARCH64_RET_INT64; break;
        case 'B': flag = AARCH64_RET_UINT8; break;
        case 'c': flag = AARCH64_RET_SINT8; break;
        case 's': flag = AARCH64_RET_SINT16; break;
        case 'i': flag = AARCH64_RET_SINT32; break;
        case 'l': flag = AARCH64_RET_SINT32; break;
        case 'q': flag = AARCH64_RET_INT64; break;
        case 'f':
        case 'd':
        case '{':{
            flag = floatPointFlagsWithTypeEncode(retTypeEncode);
            NSUInteger s = sizeOfTypeEncode(retTypeEncode);
            if (flag == 0) {
                if (s > 16)
                    flag = AARCH64_RET_VOID | AARCH64_RET_IN_MEM;
                else if (s == 16)
                    flag = AARCH64_RET_INT128;
                else if (s == 8)
                    flag = AARCH64_RET_INT64;
                else
                    flag = AARCH64_RET_INT128 | AARCH64_RET_NEED_COPY;
            }
            break;
        }
        default:
            break;
    }
    for (int i = 0; i < narg; i++) {
        if (isHFAStructWithTypeEncode(argTypeEncodes[i]) || isFloatWithTypeEncode(argTypeEncodes[i])) {
            flag |= AARCH64_FLAG_ARG_V; break;
        }
    }
    return flag;
}
void prepareForStackSize(const char *typeencode, CallRegisterState *state){
    NSUInteger memerySize = sizeOfTypeEncode(typeencode);
    if (isIntegerWithTypeEncode(typeencode)
        || isPointerWithTypeEncode(typeencode)
        || isObjectWithTypeEncode(typeencode)) {
        if (state->NGRN < N_G_ARG_REG) {
            state->NGRN++;
            return;
        }
        state->NGRN = N_G_ARG_REG;
        state->NSAA += memerySize;
    }else if (isFloatWithTypeEncode(typeencode)) {
        if (state->NSRN < N_V_ARG_REG) {
            state->NSRN++;
            return;
        }
        state->NSRN = N_V_ARG_REG;
        state->NSAA += memerySize;
    }else if (isStructWithTypeEncode(typeencode)) {
        if (isHFAStructWithTypeEncode(typeencode)) {
            NSUInteger argCount = totalFieldCountWithTypeEncode(typeencode);
            if (argCount > 4) {
                // 转为指针
                prepareForStackSize("^", state);
                return;
            }
            if (state->NSRN + argCount <= N_V_ARG_REG) {
                state->NSRN += argCount;
                return;
            }
            state->NSRN = N_V_ARG_REG;
            state->NSAA += memerySize;
        }else if (memerySize > 16){
            // 转为指针
            prepareForStackSize("^", state);
        }else{
            //如果不是HFA，存储到通用寄存器
            NSUInteger needGRN = (memerySize + 7) / OR_ALIGNMENT;
            if (8 - state->NGRN >= needGRN) {
                state->NGRN += needGRN;
                return;
            }
            state->NGRN = N_V_ARG_REG;
            state->NSAA += memerySize;
        }
    }
}
//涉及struct内存布局问题，内存布局信息存储在 ORStructDeclare中
void structStoeInRegister(BOOL isHFA, MFValue *aggregate, CallContext ctx){
    [aggregate enumerateStructFieldsUsingBlock:^(MFValue * _Nonnull field, NSUInteger idx, BOOL *stop) {
        if (field.isStruct) {
            structStoeInRegister(isHFA, field, ctx);
            return;
        }
        CallRegisterState *state = ctx.state;
        void *pointer = field.pointer;
        if (isHFA) {
            memcpy((char *)ctx.floatRegister + state->NSRN * 16, pointer, field.memerySize);
            state->NSRN++;
        }else{
            ctx.generalRegister[state->NGRN] = *(void **)pointer;
            state->NGRN++;
        }
    }];
}
void flatMapArgument(const char *typeencode, void *arg, CallContext ctx){
    CallRegisterState *state = ctx.state;
    NSUInteger memerySize = sizeOfTypeEncode(typeencode);
    if (isIntegerWithTypeEncode(typeencode)
        || isPointerWithTypeEncode(typeencode)
        || isObjectWithTypeEncode(typeencode)){
        if (state->NGRN < N_G_ARG_REG) {
            ctx.generalRegister[state->NGRN] = *(void **)arg;
            state->NGRN++;
            return;
        }else{
            state->NGRN = N_G_ARG_REG;
            memcpy(ctx.stackMemeries + state->NSAA, arg, memerySize);
            state->NSAA += memerySize;
            return;
        }
    }else if (isFloatWithTypeEncode(typeencode)) {
        if (state->NSRN < N_V_ARG_REG) {
            memcpy((char *)ctx.floatRegister + state->NSRN * V_REG_SIZE, arg, memerySize);
            state->NSRN++;
            return;
        }else{
            state->NSRN = N_V_ARG_REG;
            memcpy(ctx.stackMemeries + state->NSAA, arg, memerySize);
            state->NSAA += memerySize;
            return;
        }
        // Composite Types
        // aggregate: struct and array
    }else if (isStructWithTypeEncode(typeencode)) {
        if (isHFAStructWithTypeEncode(typeencode)) {
            NSUInteger argCount = totalFieldCountWithTypeEncode(typeencode);
            if (argCount > 4) {
                flatMapArgument("^", &arg, ctx);
                return;
            }
            if (state->NSRN + argCount <= N_V_ARG_REG) {
                //set args to float register
                MFValue *aggregate = [[MFValue alloc] initTypeEncode:typeencode pointer:arg];
                structStoeInRegister(YES, aggregate, ctx);
                return;
            }else{
                state->NSRN = N_V_ARG_REG;
                memcpy(ctx.stackMemeries + state->NSAA, arg, memerySize);
                state->NSAA += memerySize;
                return;
            }
        }else if (memerySize > 16){
            flatMapArgument("^", &arg, ctx);
        }else{
            NSUInteger needGRN = (memerySize + 7) / OR_ALIGNMENT;
            if (8 - state->NGRN >= needGRN) {
                //set args to general register
                MFValue *aggregate = [[MFValue alloc] initTypeEncode:typeencode pointer:arg];
                structStoeInRegister(NO, aggregate, ctx);
                return;
            }else{
                state->NGRN = N_V_ARG_REG;
                memcpy(ctx.stackMemeries + state->NSAA, arg, memerySize);
                state->NSAA += memerySize;
                return;
            }
        }
    }
}
extern void ORCoreFunctionCall(void *stack, void *frame, void *fn, void *ret, NSUInteger flag);;
void core_invoke_function_pointer(ffi_cif *cif, void *funcptr, void **args, void *ret){
    CallRegisterState prepareState = { 0 , 0 , 0};
    for (int i = 0; i < cif->nargs; i++) {
        prepareForStackSize(cif->arg_typeEncodes[i], &prepareState);
        if (i + 1 >= cif->nfixedargs) {
            prepareState.NGRN = N_G_ARG_REG;
            prepareState.NSRN = N_V_ARG_REG;
        }
    }
    NSUInteger stackSize = prepareState.NSAA;
    NSUInteger retSize = sizeOfTypeEncode(cif->r_typeEncode);
    char *stack = alloca(CALL_CONTEXT_SIZE + stackSize + 40 + retSize);
    memset(stack, 0, CALL_CONTEXT_SIZE + stackSize + 40 + retSize);
    CallRegisterState state = { 0 , 0 , 0};;
    CallContext context;
    context.state = &state;
    context.floatRegister = (void *)stack;
    context.generalRegister = (char *)context.floatRegister + V_REG_TOTAL_SIZE;
    context.stackMemeries = (char *)context.generalRegister + G_REG_TOTAL_SIZE;
    context.frame = (char *)context.stackMemeries + stackSize;
    context.retPointer = (char *)context.frame + 40;
    for (int i = 0; i < cif->nargs; i++) {
        flatMapArgument(cif->arg_typeEncodes[i], args[i], context);
        if (i + 1 >= cif->nfixedargs) {
            context.state->NGRN = N_G_ARG_REG;
            context.state->NSRN = N_V_ARG_REG;
        }
    }
    ORCoreFunctionCall(stack, context.frame, funcptr, context.retPointer, cif->flags);
    void *pointer = context.retPointer;
    if (pointer != NULL) {
        memcpy(ret, pointer, sizeOfTypeEncode(cif->r_typeEncode));
    }
}
void invoke_functionPointer(void *funptr, NSArray<MFValue *> *argValues, MFValue *returnValue){
    invoke_functionPointer(funptr, argValues, returnValue, argValues.count);
}
__attribute__((overloadable))
void invoke_functionPointer(void *funptr, NSArray<MFValue *> *argValues, MFValue *returnValue, NSUInteger needArgs){
    ffi_cif cif;
    const char *types[argValues.count];
    void *argvs[argValues.count];
    for (int i = 0; i < argValues.count; i++) {
        types[i] = argValues[i].typeEncode;
        argvs[i] = argValues[i].pointer;
    }
    cif.arg_typeEncodes = (char **)types;
    cif.r_typeEncode = (char *)returnValue.typeEncode;
    cif.nargs = (unsigned)argValues.count;
    cif.nfixedargs = (unsigned)needArgs;
    cif.flags =  (unsigned)resultFlagsForTypeEncode(cif.r_typeEncode, cif.arg_typeEncodes, cif.nargs);
    
    void *ret = alloca(returnValue.memerySize);
    core_invoke_function_pointer(&cif, funptr, argvs, ret);
    returnValue.pointer = ret;
}
#else
#import "ORTypeVarPair+libffi.h"

void invoke_functionPointer(void *funptr, NSArray<MFValue *> *argValues, MFValue *returnValue){
    invoke_functionPointer(funptr, argValues, returnValue, argValues.count);
}
__attribute__((overloadable))
void invoke_functionPointer(void *funptr, NSArray<MFValue *> *argValues, MFValue *returnValue, NSUInteger needArgs){
//    ffi_cif cif;
//    ffi_type *types[argCount];
//    void *argvs[argCount];
//    for (int i = 0; i < argCount; i++) {
////        types[i] = typeEncode2ffi_type();
//        argvs[i] = argValues[i]->pointer;
//    }
//    ffi_type *retType;// = typeEncode2ffi_type(returnValue.typeEncode);
//    ffi_status ffi_status = ffi_prep_cif(&cif, FFI_DEFAULT_ABI, (unsigned int)argCount, retType, types);
//    #ifdef __arm64__
//        cif.aarch64_nfixedargs = (unsigned)signArgCount;
//    #endif
//    void *ret = alloca(or_value_mem_size(returnValue));
//    if (ffi_status == FFI_OK) {
//        ffi_call(&cif, funptr, ret, argvs);
//    }
//    // 触发 setPointer
//    or_value_set_pointer(returnValue, ret);
}

#endif/* __libffi__ */
