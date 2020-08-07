//
//  ORCoreCall.s
//  OCRunner
//
//  Created by Jiang on 2020/7/7.
//  Copyright © 2020 SilverFruity. All rights reserved.
//
#import "ORCoreFunctionCall.h"
/**
 *  void ORMultiArgsCFunCall
 *  x0 void *stack
 *  x1 void *frame: save x29, x30, sp, ret, flag
 *  x2 void (*func)(void)
 *  x3 void *ret
 *  x4 uint  retFlag
 */
#if !__has_include("ffi.h")
.text
.global _ORCoreFunctionCall
_ORCoreFunctionCall:
    stp x29, x30, [x1]
    stp x3, x4, [x1, 0x10]
    mov x29, sp
    str x29, [x1, 0x20]
    mov x29, x1
    mov x9, x2
    mov x8, x3 // install struct return
    mov sp, x0
    ldp q0, q1, [sp]
    ldp q2, q3, [sp, 0x20]
    ldp q4, q5, [sp, 0x40]
    ldp q6, q7, [sp, 0x60]
    ldp x0, x1, [sp, 0x80] //128: N_V_ARG_REG*V_REG_SIZE
    ldp x2, x3, [sp, 0x80 + 0x10]
    ldp x4, x5, [sp, 0x80 + 0x20]
    ldp x6, x7, [sp, 0x80 + 0x30]
    add sp, sp, 0xc0 //0x80+0x40: ARGS_SIZE+FUNC_POINT
    blr x9
    ldp x3, x4, [x29, 0x10]
    ldr x9, [x29, 0x20]
    mov sp, x9
    ldp x29, x30, [x29]

	/* Save the return value as directed.  */
	adr	x5, 0f
	and	w4, w4, #AARCH64_RET_MASK
	add	x5, x5, x4, lsl #3
	br	x5
	/* Note that each table entry is 2 insns, and thus 8 bytes.
	   For integer data, note that we're storing into ffi_arg
	   and therefore we want to extend to 64 bits; these types
	   have two consecutive entries allocated for them.  */
	.align	4
0:	ret				/* VOID */
	nop
1:	str	x0, [x3]		/* INT64 */
	ret
2:	stp	x0, x1, [x3]		/* INT128 */
	ret
3:	brk	#1000			/* UNUSED */
	ret
4:	brk	#1000			/* UNUSED */
	ret
5:	brk	#1000			/* UNUSED */
	ret
6:	brk	#1000			/* UNUSED */
	ret
7:	brk	#1000			/* UNUSED */
	ret
8:	st4	{ v0.s, v1.s, v2.s, v3.s }[0], [x3]	/* S4 */
	ret
9:	st3	{ v0.s, v1.s, v2.s }[0], [x3]	/* S3 */
	ret
10:	stp	s0, s1, [x3]		/* S2 */
	ret
11:	str	s0, [x3]		/* S1 */
	ret
12:	st4	{ v0.d, v1.d, v2.d, v3.d }[0], [x3]	/* D4 */
	ret
13:	st3	{ v0.d, v1.d, v2.d }[0], [x3]	/* D3 */
	ret
14:	stp	d0, d1, [x3]		/* D2 */
	ret
15:	str	d0, [x3]		/* D1 */
	ret
16:	str	q3, [x3, #48]		/* Q4 */
	nop
17:	str	q2, [x3, #32]		/* Q3 */
	nop
18:	stp	q0, q1, [x3]		/* Q2 */
	ret
19:	str	q0, [x3]		/* Q1 */
	ret
20:	uxtb	w0, w0			/* UINT8 */
	str	x0, [x3]
21:	ret				/* reserved */
	nop
22:	uxth	w0, w0			/* UINT16 */
	str	x0, [x3]
23:	ret				/* reserved */
	nop
24:	mov	w0, w0			/* UINT32 */
	str	x0, [x3]
25:	ret				/* reserved */
	nop
26:	sxtb	x0, w0			/* SINT8 */
	str	x0, [x3]
27:	ret				/* reserved */
	nop
28:	sxth	x0, w0			/* SINT16 */
	str	x0, [x3]
29:	ret				/* reserved */
	nop
30:	sxtw	x0, w0			/* SINT32 */
	str	x0, [x3]
31:	ret				/* reserved */
	nop
ret
#endif
