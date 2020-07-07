//
//  ORCoreCall.s
//  OCRunner
//
//  Created by Jiang on 2020/7/7.
//  Copyright © 2020 SilverFruity. All rights reserved.
//

/**
 *  void ORMultiArgsCFunCall
 *  x0 void *stack
 *  x1 void *frame: save x29, x30
 *  x2 void (*func)(void)
 *  x3 void *ret
 */
#ifdef __arm64__
.text
.global _ORCoreFunctionCall
_ORCoreFunctionCall:
stp x29, x30, [x1]
mov x29, x1
mov x9, x2
mov x8, x3
mov sp, x0
ldp q0, q1, [sp]
ldp q2, q3, [sp, 0x20]
ldp q4, q5, [sp, 0x40]
ldp q6, q7, [sp, 0x60]
ldp x0, x1, [sp, 0x80 + 0] //128: N_V_ARG_REG*V_REG_SIZE
ldp x2, x3, [sp, 0x80 + 0x10]
ldp x4, x5, [sp, 0x80 + 0x20]
ldp x6, x7, [sp, 0x80 + 0x30]
add sp, sp, 0xc8 //0x80+0x40+8: ARGS_SIZE+FUNC_POINT
blr x9
mov sp, x29
ldp x29, x30, [x29]
ret
#endif

