//
//  ORCoreFunction.h
//  OCRunner
//
//  Created by Jiang on 2020/7/14.
//  Copyright © 2020 SilverFruity. All rights reserved.
//

#ifndef ORCoreFunction_h
#define ORCoreFunction_h
# if __has_feature(ptrauth_calls)
#  define HAVE_PTRAUTH 1
# endif

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

typedef struct {
    char *r_typeEncode;
    char **arg_typeEncodes;
    unsigned nargs;
    unsigned flags;
    unsigned nfixedargs; //可变参数需要的个数
} ffi_cif;

NSUInteger floatPointFlagsWithTypeEncode(const char *typeEncode);
NSUInteger resultFlagsForTypeEncode(const char *retTypeEncode, char **argTypeEncodes, int narg);

@class NSArray;
@class MFValue;

void invoke_functionPointer(void *funptr, NSArray<MFValue *> *argValues, MFValue *returnValue);

void *register_function(void (*fun)(ffi_cif *,void *,void **, void*),
                         unsigned nargs,
                         char **argTypeEncodes,
                         char *retTypeEncode);
#endif /* ORCoreFunction_h */
