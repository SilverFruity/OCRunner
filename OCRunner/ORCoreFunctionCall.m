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
#import "ORStructDeclare.h"

typedef struct{
    NSUInteger NGRN;
    NSUInteger NSRN;
    NSUInteger NSAA;
}CallRegisterState;

typedef struct {
    CallRegisterState *state;
    void **generalRegister;
    void *floatRegister;
    void *frame;
    char *stackMemeries;
    void *retPointer;
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
void flatMapArgument(MFValue *arg, CallContext ctx){
    CallRegisterState *state = ctx.state;
    if (arg.isInteger || arg.isPointer || arg.isObject) {
        if (state->NGRN < N_G_ARG_REG) {
            void *pointer = arg.pointer;
            ctx.generalRegister[state->NGRN] = *(void **)pointer;
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
            memcpy((char *)ctx.floatRegister + state->NSRN * V_REG_SIZE, pointer, arg.memerySize);
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
            if (arg.structLayoutFieldCount > 4) {
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
extern void ORCoreFunctionCall(void *stack, void *frame, void *fn, void *ret, NSUInteger flag);;
void invoke_functionPointer(void *funptr, NSArray<MFValue *> *argValues, MFValue *returnValue){
    if (funptr == NULL) {
        return;
    }
    NSUInteger flag = 0;
    do {
        if (returnValue.pointerCount > 0) {
            flag = AARCH64_RET_INT64; break;
        }
        switch (returnValue.type) {
            case TypeSEL:
            case TypeClass:
            case TypeObject:
            case TypeBlock:
            case TypeId:
            case TypeUnKnown: flag = AARCH64_RET_INT64; break;
            case TypeVoid:   flag = AARCH64_RET_VOID; break;
            case TypeUChar:  flag = AARCH64_RET_UINT8; break;
            case TypeUShort: flag = AARCH64_RET_UINT16; break;
            case TypeUInt:   flag = AARCH64_RET_UINT32; break;
            case TypeULong:  flag = AARCH64_RET_INT64; break;
            case TypeULongLong: flag = AARCH64_RET_INT64; break;
            case TypeBOOL:   flag = AARCH64_RET_UINT8; break;
            case TypeChar:   flag = AARCH64_RET_SINT8; break;
            case TypeShort:  flag = AARCH64_RET_SINT16; break;
            case TypeInt:    flag = AARCH64_RET_SINT32; break;
            case TypeLong:   flag = AARCH64_RET_SINT32; break;
            case TypeLongLong: flag = AARCH64_RET_INT64; break;
            case TypeFloat:
            case TypeDouble:
            case TypeStruct:{
                NSUInteger s = returnValue.memerySize;
                
                if (!returnValue.isHFAStruct) {
                    if (s > 16)
                        flag = AARCH64_RET_VOID | AARCH64_RET_IN_MEM;
                    else if (s == 16)
                        flag = AARCH64_RET_INT128;
                    else if (s == 8)
                        flag = AARCH64_RET_INT64;
                    else
                        flag = AARCH64_RET_INT128 | AARCH64_RET_NEED_COPY;
                }else{
                    NSUInteger fieldCount = returnValue.structLayoutFieldCount;
                    if (fieldCount <= 4) {
                        const char *fieldEncode = detectStructMemeryLayoutEncodeCode(returnValue.typeEncode).UTF8String;
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
                        //iOS没有LONGDOUBLE
                        //Note that FFI_TYPE_FLOAT == 2, _DOUBLE == 3, _LONGDOUBLE == 4
                        //#define AARCH64_RET_S4        8
                        //#define AARCH64_RET_D4        12
                        flag = offset * 4 + (4 - fieldCount);
                    }
                }
                break;
            }
            default:
                break;
        }
        for (NSUInteger i = 0 ; i < argValues.count; i++)
            if (argValues[i].isHFAStruct)
                flag |= AARCH64_FLAG_ARG_V; break;
        break;
    }while (0);
    
    NSMutableArray *args = [argValues mutableCopy];
    CallRegisterState prepareState = { 0 , 0 , 0};
    for (MFValue *arg in args) {
        prepareForStackSize(arg, &prepareState);
    }
    NSUInteger stackSize = prepareState.NSAA;
    NSUInteger floatRegistersSize = N_V_ARG_REG*V_REG_SIZE;
    NSUInteger generalRegistersSize = N_G_ARG_REG*G_REG_SIZE;
    NSUInteger retSize = 0;
    if (flag & AARCH64_RET_NEED_COPY) {
        retSize = 16;
    }else{
        retSize = returnValue.memerySize;
    }
    char *stack = malloc(floatRegistersSize + generalRegistersSize + stackSize + 40 + retSize);
    memset(stack, 0, floatRegistersSize + generalRegistersSize + stackSize + 40 + retSize);
    CallRegisterState state = { 0 , 0 , 0};;
    CallContext context;
    context.state = &state;
    context.floatRegister = (void *)stack;
    context.generalRegister = (char *)context.floatRegister + floatRegistersSize;
    context.stackMemeries = (char *)context.generalRegister + generalRegistersSize;
    context.frame = (char *)context.stackMemeries + + stackSize;
    context.retPointer = (char *)context.frame + 40;
    for (MFValue *arg in args) {
        flatMapArgument(arg, context);
    }
    ORCoreFunctionCall(stack, context.frame, funptr, context.retPointer, flag);
    void *pointer = context.retPointer;
    returnValue.pointer = pointer;
    free(stack);
}


