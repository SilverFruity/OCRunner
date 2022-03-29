//
//  ORCoreFunctionRegister.m
//  OCRunner
//
//  Created by Jiang on 2020/7/14.
//  Copyright © 2020 SilverFruity. All rights reserved.
//

#import "ORCoreFunctionRegister.h"
#import <Foundation/Foundation.h>
#import "ORCoreFunction.h"
#import "ORCoreFunctionCall.h"
#import "ORHandleTypeEncode.h"
#include <mach/mach.h>
#include <pthread.h>

#ifndef __libffi__

#ifdef HAVE_PTRAUTH
#include <ptrauth.h>
#endif



extern void *ffi_closure_trampoline_table_page;

typedef struct ffi_trampoline_table ffi_trampoline_table;
typedef struct ffi_trampoline_table_entry ffi_trampoline_table_entry;

struct ffi_trampoline_table
{
    /* contiguous writable and executable pages */
    vm_address_t config_page;
    vm_address_t trampoline_page;
    
    /* free list tracking */
    uint16_t free_count;
    ffi_trampoline_table_entry *free_list;
    ffi_trampoline_table_entry *free_list_pool;
    
    ffi_trampoline_table *prev;
    ffi_trampoline_table *next;
};

struct ffi_trampoline_table_entry
{
    void *(*trampoline)(void);
    ffi_trampoline_table_entry *next;
};

/* Total number of trampolines that fit in one trampoline table */
#define FFI_TRAMPOLINE_COUNT (PAGE_MAX_SIZE / FFI_TRAMPOLINE_SIZE)

static pthread_mutex_t ffi_trampoline_lock = PTHREAD_MUTEX_INITIALIZER;
static ffi_trampoline_table *ffi_trampoline_tables = NULL;

static ffi_trampoline_table *
ffi_trampoline_table_alloc(void)
{
    ffi_trampoline_table *table;
    vm_address_t config_page;
    vm_address_t trampoline_page;
    vm_address_t trampoline_page_template;
    vm_prot_t cur_prot;
    vm_prot_t max_prot;
    kern_return_t kt;
    uint16_t i;
    
    /* Allocate two pages -- a config page and a placeholder page */
    config_page = 0x0;
    kt = vm_allocate(mach_task_self(), &config_page, PAGE_MAX_SIZE * 2,
                     VM_FLAGS_ANYWHERE);
    if (kt != KERN_SUCCESS)
        return NULL;
    
    /* Remap the trampoline table on top of the placeholder page */
    trampoline_page = config_page + PAGE_MAX_SIZE;
    trampoline_page_template = (vm_address_t)&ffi_closure_trampoline_table_page;
#ifdef __arm__
    /* ffi_closure_trampoline_table_page can be thumb-biased on some ARM archs */
    trampoline_page_template &= ~1UL;
#endif
    kt = vm_remap(mach_task_self(), &trampoline_page, PAGE_MAX_SIZE, 0x0,
                  VM_FLAGS_OVERWRITE, mach_task_self(), trampoline_page_template,
                  FALSE, &cur_prot, &max_prot, VM_INHERIT_SHARE);
    if (kt != KERN_SUCCESS)
    {
        vm_deallocate(mach_task_self(), config_page, PAGE_MAX_SIZE * 2);
        return NULL;
    }
    
    /* We have valid trampoline and config pages */
    table = calloc(1, sizeof(ffi_trampoline_table));
    table->free_count = FFI_TRAMPOLINE_COUNT;
    table->config_page = config_page;
    table->trampoline_page = trampoline_page;
    
    /* Create and initialize the free list */
    table->free_list_pool =
    calloc(FFI_TRAMPOLINE_COUNT, sizeof(ffi_trampoline_table_entry));
    
    for (i = 0; i < table->free_count; i++)
    {
        ffi_trampoline_table_entry *entry = &table->free_list_pool[i];
        entry->trampoline =
        (void *)(table->trampoline_page + (i * FFI_TRAMPOLINE_SIZE));
        
        if (i < table->free_count - 1)
            entry->next = &table->free_list_pool[i + 1];
    }
    
    table->free_list = table->free_list_pool;
    
    return table;
}

static void
ffi_trampoline_table_free(ffi_trampoline_table *table)
{
    /* Remove from the list */
    if (table->prev != NULL)
        table->prev->next = table->next;
    
    if (table->next != NULL)
        table->next->prev = table->prev;
    
    /* Deallocate pages */
    vm_deallocate(mach_task_self(), table->config_page, PAGE_MAX_SIZE * 2);
    
    /* Deallocate free list */
    free(table->free_list_pool);
    free(table);
}

void *
ffi_closure_alloc(size_t size, void **code)
{
    /* Create the closure */
    ffi_closure *closure = malloc(size);
    if (closure == NULL)
        return NULL;
    
    pthread_mutex_lock(&ffi_trampoline_lock);
    
    /* Check for an active trampoline table with available entries. */
    ffi_trampoline_table *table = ffi_trampoline_tables;
    if (table == NULL || table->free_list == NULL)
    {
        table = ffi_trampoline_table_alloc();
        if (table == NULL)
        {
            pthread_mutex_unlock(&ffi_trampoline_lock);
            free(closure);
            return NULL;
        }
        
        /* Insert the new table at the top of the list */
        table->next = ffi_trampoline_tables;
        if (table->next != NULL)
            table->next->prev = table;
        
        ffi_trampoline_tables = table;
    }
    
    /* Claim the free entry */
    ffi_trampoline_table_entry *entry = ffi_trampoline_tables->free_list;
    ffi_trampoline_tables->free_list = entry->next;
    ffi_trampoline_tables->free_count--;
    entry->next = NULL;
    
    pthread_mutex_unlock(&ffi_trampoline_lock);
    
    /* Initialize the return values */
    *code = entry->trampoline;
#ifdef HAVE_PTRAUTH
    *code = ptrauth_sign_unauthenticated(*code, ptrauth_key_asia, 0);
#endif
    closure->trampoline_table = table;
    closure->trampoline_table_entry = entry;
    
    return closure;
}

void ffi_closure_free(void *ptr)
{
    ffi_closure *closure = ptr;
    
    pthread_mutex_lock(&ffi_trampoline_lock);
    
    /* Fetch the table and entry references */
    ffi_trampoline_table *table = closure->trampoline_table;
    ffi_trampoline_table_entry *entry = closure->trampoline_table_entry;
    
    /* Return the entry to the free list */
    entry->next = table->free_list;
    table->free_list = entry;
    table->free_count++;
    
    /* If all trampolines within this table are free, and at least one other table exists, deallocate
     * the table */
    if (table->free_count == FFI_TRAMPOLINE_COUNT && ffi_trampoline_tables != table)
    {
        ffi_trampoline_table_free(table);
    }
    else if (ffi_trampoline_tables != table)
    {
        /* Otherwise, bump this table to the top of the list */
        table->prev = NULL;
        table->next = ffi_trampoline_tables;
        if (ffi_trampoline_tables != NULL)
            ffi_trampoline_tables->prev = table;
        
        ffi_trampoline_tables = table;
    }
    
    pthread_mutex_unlock(&ffi_trampoline_lock);
    
    /* Free the closure */
    free(closure);
}

extern void ffi_closure_SYSV(void);
extern void ffi_closure_SYSV_V(void);
ffi_status
ffi_prep_closure_loc(ffi_closure *closure,
                     ffi_cif* cif,
                     void (*fun)(ffi_cif*,void*,void**,void*),
                     void *user_data,
                     void *codeloc)
{
    void (*start)(void);
    if (cif->flags & AARCH64_FLAG_ARG_V)
        start = ffi_closure_SYSV_V;
    else
        start = ffi_closure_SYSV;
#ifdef HAVE_PTRAUTH
    codeloc = ptrauth_strip(codeloc, ptrauth_key_asia);
#endif
    // use asm function:  ffi_closure_trampoline_table_page
    // save `closure` in x17 and call `start`
    void **config = (void **)((uint8_t *)codeloc - PAGE_MAX_SIZE);
    config[0] = closure;
    config[1] = start;
    closure->cif = cif;
    closure->fun = fun;
    closure->user_data = user_data;
    
    return FFI_OK;
}

or_ffi_result *core_register_function(void (*func)(ffi_cif *,void *,void **, void*),
                             unsigned nargs,
                             char **argTypeEncodes,
                             char *retTypeEncode,
                             void *userdata){
    ffi_cif *cif = malloc(sizeof(ffi_cif));
    cif->arg_typeEncodes = argTypeEncodes;
    cif->nargs = nargs;
    cif->r_typeEncode = retTypeEncode;
    cif->flags = (unsigned) resultFlagsForTypeEncode(retTypeEncode, argTypeEncodes, nargs);
    void *imp = NULL;
    ffi_closure *closure = ffi_closure_alloc(sizeof(ffi_closure), &imp);
    ffi_prep_closure_loc(closure, cif, func, userdata, imp);
    
    or_ffi_result *result = malloc(sizeof(or_ffi_result));
    result->cif = cif;
    result->closure = closure;
    result->function_imp = imp;
    return result;
}

void *allocate_to_stack(CallContext ctx, size_t size)
{
    CallRegisterState *state = ctx.state;
    char *stack = ctx.stackMemeries;
    size_t nsaa = state->NSAA;
    nsaa = OR_ALIGN(nsaa, 8);
    state->NSAA = nsaa + size;
    return stack + nsaa;
}
void *allocate_int_to_reg_or_stack(CallContext ctx,size_t size)
{
    CallRegisterState *state = ctx.state;
    if (state->NGRN < N_G_ARG_REG){
        return &ctx.generalRegister[state->NGRN++];
    }
    state->NGRN = N_G_ARG_REG;
    return allocate_to_stack(ctx, size);
}
static void * compress_hfa_type (void *dest, void *reg, int h)
{
    switch (h)
    {
        case AARCH64_RET_S1:
            if (dest == reg)
            {
#ifdef __AARCH64EB__
                dest += 12;
#endif
            }
            else
                *(float *)dest = *(float *)reg;
            break;
        case AARCH64_RET_S2:
            asm ("ldp q16, q17, [%1]\n\t"
                 "st2 { v16.s, v17.s }[0], [%0]"
                 : : "r"(dest), "r"(reg) : "memory", "v16", "v17");
            break;
        case AARCH64_RET_S3:
            asm ("ldp q16, q17, [%1]\n\t"
                 "ldr q18, [%1, #32]\n\t"
                 "st3 { v16.s, v17.s, v18.s }[0], [%0]"
                 : : "r"(dest), "r"(reg) : "memory", "v16", "v17", "v18");
            break;
        case AARCH64_RET_S4:
            asm ("ldp q16, q17, [%1]\n\t"
                 "ldp q18, q19, [%1, #32]\n\t"
                 "st4 { v16.s, v17.s, v18.s, v19.s }[0], [%0]"
                 : : "r"(dest), "r"(reg) : "memory", "v16", "v17", "v18", "v19");
            break;
            
        case AARCH64_RET_D1:
            if (dest == reg)
            {
#ifdef __AARCH64EB__
                dest += 8;
#endif
            }
            else
                *(double *)dest = *(double *)reg;
            break;
        case AARCH64_RET_D2:
            asm ("ldp q16, q17, [%1]\n\t"
                 "st2 { v16.d, v17.d }[0], [%0]"
                 : : "r"(dest), "r"(reg) : "memory", "v16", "v17");
            break;
        case AARCH64_RET_D3:
            asm ("ldp q16, q17, [%1]\n\t"
                 "ldr q18, [%1, #32]\n\t"
                 "st3 { v16.d, v17.d, v18.d }[0], [%0]"
                 : : "r"(dest), "r"(reg) : "memory", "v16", "v17", "v18");
            break;
        case AARCH64_RET_D4:
            asm ("ldp q16, q17, [%1]\n\t"
                 "ldp q18, q19, [%1, #32]\n\t"
                 "st4 { v16.d, v17.d, v18.d, v19.d }[0], [%0]"
                 : : "r"(dest), "r"(reg) : "memory", "v16", "v17", "v18", "v19");
            break;
            
        default:
            if (dest != reg)
                return memcpy (dest, reg, 16 * (4 - (h & 3)));
            break;
    }
    return dest;
}
int
ffi_closure_SYSV_inner(ffi_cif *cif,
                       void (*fun)(ffi_cif*,void*,void**,void*),
                       void *user_data,
                       void *context,
                       void *stack, void *rvalue, void *struct_rvalue)
{
    void **avalue = (void**)alloca(cif->nargs * sizeof (void*));
    CallRegisterState state = {0, 0, 0};
    CallContext ctx;
    ctx.state = &state;
    ctx.floatRegister = context;
    ctx.generalRegister = context+V_REG_TOTAL_SIZE;
    ctx.stackMemeries = stack;
    for (int i = 0; i < cif->nargs; i++)
    {
        const char *typeencode = cif->arg_typeEncodes[i];
        NSUInteger memerySize = sizeOfTypeEncode(typeencode);
        
        if (isIntegerWithTypeEncode(typeencode)
            || isPointerWithTypeEncode(typeencode)
            || isObjectWithTypeEncode(typeencode)) {
            
            avalue[i] = allocate_int_to_reg_or_stack(ctx, memerySize);
            
        }else if (isFloatWithTypeEncode(typeencode)
                  || isStructWithTypeEncode(typeencode)){
            NSUInteger flags = floatPointFlagsWithTypeEncode(typeencode);
            if (flags) {
                NSUInteger argCount = totalFieldCountWithTypeEncode(typeencode);
                if (argCount > 4) {
                    avalue[i] = *(void **)allocate_int_to_reg_or_stack(ctx, memerySize);
                }else if (state.NSRN + argCount <= N_V_ARG_REG) {
                    //compress_hfa_type
                    void *reg = ctx.floatRegister + state.NSRN * V_REG_SIZE;
                    state.NSRN += argCount;
                    avalue[i] = compress_hfa_type(reg, reg, (int)flags);
                }else{
                    state.NSRN = N_V_ARG_REG;
                    avalue[i] = allocate_to_stack(ctx, memerySize);
                }
            }else if (memerySize > 16){
                avalue[i] = *(void **)allocate_int_to_reg_or_stack(ctx, memerySize);
            }else{
                NSUInteger needGRN = (memerySize + 7) / OR_ALIGNMENT;
                if (8 - state.NGRN >= needGRN) {
                    avalue[i] = &ctx.generalRegister[state.NGRN];
                    state.NGRN += (unsigned int)needGRN;
                }else{
                    state.NGRN = N_V_ARG_REG;
                    avalue[i] = allocate_to_stack(ctx, memerySize);
                }
            }
        }
    }
    if (cif->flags & AARCH64_RET_IN_MEM)
        rvalue = struct_rvalue;
    fun(cif, rvalue, avalue, user_data);
    return cif->flags;
    
}
#import "ORTypeVarPair+TypeEncode.h"
char *mallocCopyStr(const char *source){
    NSUInteger sLen = strlen(source);
    char *result = malloc(sLen + 1);
    memcpy(result, source, sLen);
    result[sLen] = '\0';
    return result;
}

or_ffi_result *register_function(void (*fun)(ffi_cif *,void *,void **, void*),
                        NSArray <ORTypeVarPair *>*args,
                        ORTypeVarPair *ret) __attribute__((overloadable))
{
    return register_function(fun, args, ret, NULL);
}

or_ffi_result *register_function(void (*fun)(ffi_cif *,void *,void **, void*),
                        NSArray <ORTypeVarPair *>*args,
                        ORTypeVarPair *ret,
                        void *userdata)
{
    char **argTypes = malloc(args.count * sizeof(char *));
    for (int i = 0; i < args.count; i++) {
        argTypes[i] = mallocCopyStr(args[i].typeEncode);
    }
    char *retTyep = mallocCopyStr(ret.typeEncode);
    return core_register_function(fun, (int)args.count, argTypes, retTyep, userdata);
}
or_ffi_result *register_method(void (*fun)(ffi_cif *,void *,void **, void*),
                      NSArray <ORTypeVarPair *>*args,
                      ORTypeVarPair *ret) __attribute__((overloadable))
{
    return register_method(fun, args, ret, NULL);
}
or_ffi_result *register_method(void (*fun)(ffi_cif *,void *,void **, void*),
                      NSArray <ORTypeVarPair *>*args,
                      ORTypeVarPair *ret, void *userdata)
{
    NSMutableArray *argTypes = [NSMutableArray array];
    [argTypes addObject:[ORTypeVarPair typePairWithTypeKind:TypeObject]];
    [argTypes addObject:[ORTypeVarPair typePairWithTypeKind:TypeSEL]];
    [argTypes addObjectsFromArray:args];
    return register_function(fun, argTypes, ret, userdata);
}

#else
#import "ORTypeVarPair+libffi.h"
#import "ORTypeVarPair+TypeEncode.h"
char *mallocCopyStr(const char *source){
    NSUInteger sLen = strlen(source);
    char *result = malloc(sLen + 1);
    memcpy(result, source, sLen);
    result[sLen] = '\0';
    return result;
}
or_ffi_result *register_function(void (*fun)(ffi_cif *,void *,void **, void*),
                        NSArray <ORTypeVarPair *>*args,
                        ORTypeVarPair *ret)  __attribute__((overloadable))
{
    return register_function(fun, args, ret, NULL);
}


or_ffi_result *register_function(void (*fun)(ffi_cif *,void *,void **, void*),
                        NSArray <ORTypeVarPair *>*args,
                        ORTypeVarPair *ret,
                        void *userdata)
{
    void *imp = NULL;
    ffi_cif *cif = malloc(sizeof(ffi_cif));//不可以free
    ffi_closure *closure = ffi_closure_alloc(sizeof(ffi_closure), (void **)&imp);
    
    ffi_type *returnType = typeEncode2ffi_type(ret.typeEncode);
    ffi_type **arg_types = malloc(sizeof(ffi_type *) * args.count);
    for (int  i = 0 ; i < args.count; i++) {
        arg_types[i] = typeEncode2ffi_type(args[i].typeEncode);
    }
    if(ffi_prep_cif(cif, FFI_DEFAULT_ABI, (unsigned int)args.count, returnType, arg_types) == FFI_OK)
    {
        ffi_prep_closure_loc(closure, cif, fun, userdata, imp);
    }
    or_ffi_result *result = malloc(sizeof(or_ffi_result));
    result->cif = cif;
    result->arg_types = arg_types;
    result->closure = closure;
    result->function_imp = imp;
    return result;
}

or_ffi_result *register_method(void (*fun)(ffi_cif *,void *,void **, void*),
                      NSArray <ORTypeVarPair *>*args,
                      ORTypeVarPair *ret) __attribute__((overloadable))
{
    return register_method(fun, args, ret, NULL);
}
or_ffi_result *register_method(void (*fun)(ffi_cif *,void *,void **, void*),
                      NSArray <ORTypeVarPair *>*args,
                      ORTypeVarPair *ret,
                      void *userdata)
{
    NSMutableArray *argTypes = [NSMutableArray array];
    [argTypes addObject:[ORTypeVarPair typePairWithTypeKind:TypeObject]];
    [argTypes addObject:[ORTypeVarPair typePairWithTypeKind:TypeSEL]];
    [argTypes addObjectsFromArray:args];
    return register_function(fun, argTypes, ret, userdata);
}
#endif/* __libffi__ */

void or_ffi_result_free(or_ffi_result *result){
#ifdef __libffi__
    free(result->arg_types);
#else
    for (int i = 0; i < result->cif->nargs; i++) {
        free(result->cif->arg_typeEncodes[i]);
    }
    free(result->cif->arg_typeEncodes);
    free(result->cif->r_typeEncode);
#endif
    free(result->cif);
    ffi_closure_free(result->closure);
    free(result);
}
