//
//  ORCoreFunction.h
//  OCRunner
//
//  Created by Jiang on 2020/7/14.
//  Copyright © 2020 SilverFruity. All rights reserved.
//

#ifndef ORCoreFunction_h
#define ORCoreFunction_h

#if __has_include("ffi.h")

#define __libffi__
#import "ffi.h"

#else

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
void *core_register_function(void (*fun)(ffi_cif *,void *,void **, void*),
                             unsigned nargs,
                             char **argTypeEncodes,
                             char *retTypeEncode,
                             void *userdata);

#endif /* __has_include  */


@class NSArray;
@class MFValue;
@class ORTypeVarPair;

void core_invoke_function_pointer(ffi_cif *cif, void *funcptr, void **args, void *ret);
__attribute__((overloadable))
void invoke_functionPointer(void *funptr, NSArray<MFValue *> *argValues, MFValue *returnValue, NSUInteger needArgs);
void invoke_functionPointer(void *funptr, NSArray<MFValue *> *argValues, MFValue *returnValue);




void *register_function(void (*fun)(ffi_cif *,void *,void **, void*),
                        NSArray <ORTypeVarPair *>*args,
                        ORTypeVarPair *ret)  __attribute__((overloadable));

void *register_function(void (*fun)(ffi_cif *,void *,void **, void*),
                        NSArray <ORTypeVarPair *>*args,
                        ORTypeVarPair *ret,
                        void *userdata);

void *register_method(void (*fun)(ffi_cif *,void *,void **, void*),
                      NSArray <ORTypeVarPair *>*args,
                      ORTypeVarPair *ret) __attribute__((overloadable));

void *register_method(void (*fun)(ffi_cif *,void *,void **, void*),
                      NSArray <ORTypeVarPair *>*args,
                      ORTypeVarPair *ret,
                      void *userdata);

#endif /* ORCoreFunction_h */
