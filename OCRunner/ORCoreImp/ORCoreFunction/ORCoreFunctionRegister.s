//
//  ORCoreFunctionRegister.s
//  OCRunner
//
//  Created by Jiang on 2020/7/14.
//  Copyright © 2020 SilverFruity. All rights reserved.
//
#import <mach/machine/vm_param.h>
#import "ORCoreFunctionCall.h"
#import "ORCoreFunctionRegister.h"
#if !__has_include("ffi.h")
#ifdef __AARCH64EB__
# define BE(X)    X
#else
# define BE(X)    0
#endif

#ifdef __ILP32__
#define PTR_REG(n)      w##n
#else
#define PTR_REG(n)      x##n
#endif

#ifdef __ILP32__
#define PTR_SIZE    4
#else
#define PTR_SIZE    8
#endif

#define ffi_closure_SYSV_FS (8*2 + CALL_CONTEXT_SIZE + 64)
    .align 4
    .global _ffi_closure_SYSV_V
_ffi_closure_SYSV_V:
    stp     x29, x30, [sp, #-ffi_closure_SYSV_FS]!
    /* Save the argument passing vector registers.  */
    stp     q0, q1, [sp, #16 + 0]
    stp     q2, q3, [sp, #16 + 32]
    stp     q4, q5, [sp, #16 + 64]
    stp     q6, q7, [sp, #16 + 96]
    b    0f

    .align    4
    .global _ffi_closure_SYSV
_ffi_closure_SYSV:
    stp     x29, x30, [sp, #-ffi_closure_SYSV_FS]!
0:
    mov     x29, sp

    /* Save the argument passing core registers.  */
    stp     x0, x1, [sp, #16 + 16*N_V_ARG_REG + 0]
    stp     x2, x3, [sp, #16 + 16*N_V_ARG_REG + 16]
    stp     x4, x5, [sp, #16 + 16*N_V_ARG_REG + 32]
    stp     x6, x7, [sp, #16 + 16*N_V_ARG_REG + 48]

    /* Load ffi_closure_inner arguments.  */
    ldp    PTR_REG(0), PTR_REG(1), [x17, #FFI_TRAMPOLINE_CLOSURE_OFFSET]    /* load cif, fn */
    ldr    PTR_REG(2), [x17, #FFI_TRAMPOLINE_CLOSURE_OFFSET+PTR_SIZE*2]    /* load user_data */
.Ldo_closure:
    add    x3, sp, #16                /* load context */
    add    x4, sp, #ffi_closure_SYSV_FS        /* load stack */
    add    x5, sp, #16+CALL_CONTEXT_SIZE        /* load rvalue */
    mov    x6, x8                    /* load struct_rval */
    bl      _ffi_closure_SYSV_inner

    /* Load the return value as directed.  */
#if defined(HAVE_PTRAUTH)
    autiza    x1
#endif
    adr    x1, 0f
    and    w0, w0, #AARCH64_RET_MASK
    add    x1, x1, x0, lsl #3
    add    x3, sp, #16+CALL_CONTEXT_SIZE
    br    x1

    /* Note that each table entry is 2 insns, and thus 8 bytes.  */
    .align    4
0:    b    99f            /* VOID */
    nop
1:    ldr    x0, [x3]        /* INT64 */
    b    99f
2:    ldp    x0, x1, [x3]        /* INT128 */
    b    99f
3:    brk    #1000            /* UNUSED */
    nop
4:    brk    #1000            /* UNUSED */
    nop
5:    brk    #1000            /* UNUSED */
    nop
6:    brk    #1000            /* UNUSED */
    nop
7:    brk    #1000            /* UNUSED */
    nop
8:    ldr    s3, [x3, #12]        /* S4 */
    nop
9:    ldr    s2, [x3, #8]        /* S3 */
    nop
10:    ldp    s0, s1, [x3]        /* S2 */
    b    99f
11:    ldr    s0, [x3]        /* S1 */
    b    99f
12:    ldr    d3, [x3, #24]        /* D4 */
    nop
13:    ldr    d2, [x3, #16]        /* D3 */
    nop
14:    ldp    d0, d1, [x3]        /* D2 */
    b    99f
15:    ldr    d0, [x3]        /* D1 */
    b    99f
16:    ldr    q3, [x3, #48]        /* Q4 */
    nop
17:    ldr    q2, [x3, #32]        /* Q3 */
    nop
18:    ldp    q0, q1, [x3]        /* Q2 */
    b    99f
19:    ldr    q0, [x3]        /* Q1 */
    b    99f
20:    ldrb    w0, [x3, #BE(7)]    /* UINT8 */
    b    99f
21:    brk    #1000            /* reserved */
    nop
22:    ldrh    w0, [x3, #BE(6)]    /* UINT16 */
    b    99f
23:    brk    #1000            /* reserved */
    nop
24:    ldr    w0, [x3, #BE(4)]    /* UINT32 */
    b    99f
25:    brk    #1000            /* reserved */
    nop
26:    ldrsb    x0, [x3, #BE(7)]    /* SINT8 */
    b    99f
27:    brk    #1000            /* reserved */
    nop
28:    ldrsh    x0, [x3, #BE(6)]    /* SINT16 */
    b    99f
29:    brk    #1000            /* reserved */
    nop
30:    ldrsw    x0, [x3, #BE(4)]    /* SINT32 */
    nop
31:                    /* reserved */
99:    ldp     x29, x30, [sp], #ffi_closure_SYSV_FS
    ret


// ffi_closure_trampoline_table_page
.align PAGE_MAX_SHIFT
.text
.global _ffi_closure_trampoline_table_page
_ffi_closure_trampoline_table_page:
.rept PAGE_MAX_SIZE / FFI_TRAMPOLINE_SIZE
adr x16, -PAGE_MAX_SIZE
ldp x17, x16, [x16]
br x16
nop        /* each entry in the trampoline config page is 2*sizeof(void*) so the trampoline itself cannot be smaller that 16 bytes */
.endr
#endif
