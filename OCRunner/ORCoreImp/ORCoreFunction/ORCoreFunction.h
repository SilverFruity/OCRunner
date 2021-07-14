//
//  ORCoreFunction.h
//  OCRunner
//
//  Created by Jiang on 2020/7/14.
//  Copyright © 2020 SilverFruity. All rights reserved.
//

#ifndef ORCoreFunction_h
#define ORCoreFunction_h
#import <oc2mangoLib/InitialSymbolTableVisitor.h>

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

typedef enum {
    FFI_OK = 0,
    FFI_BAD_TYPEDEF,
    FFI_BAD_ABI
} ffi_status;

typedef struct {
    void *trampoline_table;
    void *trampoline_table_entry;
    ffi_cif   *cif;
    void     (*fun)(ffi_cif*,void*,void**,void*);
    void  *user_data;
} ffi_closure;

NSUInteger floatPointFlagsWithTypeEncode(const char *typeEncode);
NSUInteger resultFlagsForTypeEncode(const char *retTypeEncode, char **argTypeEncodes, int narg);
void ffi_closure_free(void *ptr);
#endif /* __has_include  */

#ifdef __cplusplus
extern "C" {
#endif //__cplusplus

typedef struct {
    ffi_cif *cif;
    ffi_closure *closure;
#ifdef __libffi__
    ffi_type **arg_types;
#endif
    void *function_imp;
}or_ffi_result;
void or_ffi_result_free(or_ffi_result *result);

@class NSArray;
@class MFValue;
@class ORDeclaratorNode;

void core_invoke_function_pointer(ffi_cif *cif, void *funcptr, void **args, void *ret);
__attribute__((overloadable))
void invoke_functionPointer(void *funptr, NSArray<MFValue *> *argValues, MFValue *returnValue, NSUInteger needArgs);
void invoke_functionPointer(void *funptr, NSArray<MFValue *> *argValues, MFValue *returnValue);




or_ffi_result *register_function(void (*fun)(ffi_cif *,void *,void **, void*),
                        NSArray <ocDecl *>*args,
                                 ocDecl *ret)  __attribute__((overloadable));

or_ffi_result *register_function(void (*fun)(ffi_cif *,void *,void **, void*),
                        NSArray <ocDecl *>*args,
                                 ocDecl *ret,
                        void *userdata);

or_ffi_result *register_method(void (*fun)(ffi_cif *,void *,void **, void*),
                      NSArray <ocDecl *>*args,
                               ocDecl *ret) __attribute__((overloadable));

or_ffi_result *register_method(void (*fun)(ffi_cif *,void *,void **, void*),
                      NSArray <ocDecl *>*args,
                               ocDecl *ret,
                      void *userdata);

#ifdef __cplusplus
}
#endif //__cplusplus

#endif /* ORCoreFunction_h */
