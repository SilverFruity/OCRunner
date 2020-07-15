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
#include <mach/mach.h>
#include <pthread.h>
# if __has_feature(ptrauth_calls)
#  define HAVE_PTRAUTH 1
# endif

#ifdef HAVE_PTRAUTH
#include <ptrauth.h>
#endif

typedef enum {
    FFI_OK = 0,
    FFI_BAD_TYPEDEF,
    FFI_BAD_ABI
} ffi_status;

typedef struct {
    unsigned nargs;
    const char **arg_typeEncodes;
    const char *r_typeEncode;
    unsigned flags;
} ffi_cif;

typedef struct {
    void *trampoline_table;
    void *trampoline_table_entry;
    ffi_cif   *cif;
    void     (*fun)(ffi_cif*,void*,void**,void*);
    void  *user_data;
} ffi_closure;

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

ffi_status
ffi_prep_closure_loc(ffi_closure *closure,
                     ffi_cif* ffi,
                     void (*fun)(ffi_cif*,void*,void**,void*),
                     void *user_data,
                     void *codeloc)
{
    void (*start)(void);
    //    if (cif->flags & AARCH64_FLAG_ARG_V)
    //        start = ffi_closure_SYSV_V;
    //    else
    //        start = ffi_closure_SYSV;
#ifdef HAVE_PTRAUTH
    codeloc = ptrauth_strip(codeloc, ptrauth_key_asia);
#endif
    void **config = (void **)((uint8_t *)codeloc - PAGE_MAX_SIZE);
    config[0] = closure;
    config[1] = start;
    closure->cif = ffi;
    closure->fun = fun;
    closure->user_data = user_data;
    
    return FFI_OK;
}
