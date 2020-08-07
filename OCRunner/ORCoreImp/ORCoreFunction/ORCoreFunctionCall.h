//
//  ORCoreFunctionCall.h
//  OCRunner
//
//  Created by Jiang on 2020/7/7.
//  Copyright © 2020 SilverFruity. All rights reserved.
//
#ifndef __libffi__

#define AARCH64_RET_VOID    0
#define AARCH64_RET_INT64    1
#define AARCH64_RET_INT128    2

#define AARCH64_RET_UNUSED3    3
#define AARCH64_RET_UNUSED4    4
#define AARCH64_RET_UNUSED5    5
#define AARCH64_RET_UNUSED6    6
#define AARCH64_RET_UNUSED7    7

/* Note that FFI_TYPE_FLOAT == 2, _DOUBLE == 3, _LONGDOUBLE == 4,
   so _S4 through _Q1 are layed out as (TYPE * 4) + (4 - COUNT).  */
#define AARCH64_RET_S4        8
#define AARCH64_RET_S3        9
#define AARCH64_RET_S2        10
#define AARCH64_RET_S1        11

#define AARCH64_RET_D4        12
#define AARCH64_RET_D3        13
#define AARCH64_RET_D2        14
#define AARCH64_RET_D1        15

#define AARCH64_RET_Q4        16
#define AARCH64_RET_Q3        17
#define AARCH64_RET_Q2        18
#define AARCH64_RET_Q1        19

/* Note that each of the sub-64-bit integers gets two entries.  */
#define AARCH64_RET_UINT8    20
#define AARCH64_RET_UINT16    22
#define AARCH64_RET_UINT32    24

#define AARCH64_RET_SINT8    26
#define AARCH64_RET_SINT16    28
#define AARCH64_RET_SINT32    30

#define AARCH64_RET_MASK    31

#define AARCH64_RET_IN_MEM    (1 << 5)
#define AARCH64_RET_NEED_COPY    (1 << 6)

#define AARCH64_FLAG_ARG_V_BIT    7
#define AARCH64_FLAG_ARG_V    (1 << AARCH64_FLAG_ARG_V_BIT)

//NOTE: https://developer.arm.com/documentation/100986/0000 #Procedure Call Standard for the ARM 64-bit Architecture
//NOTE: https://juejin.im/post/5d14623ef265da1bb47d7635#heading-12
#define G_REG_SIZE 8
#define V_REG_SIZE 16
#define N_G_ARG_REG 8 // The Number Of General Register
#define N_V_ARG_REG 8 // The Number Of Float-Point Register
#define V_REG_TOTAL_SIZE (N_V_ARG_REG * V_REG_SIZE)
#define G_REG_TOTAL_SIZE (N_G_ARG_REG * G_REG_SIZE)
#define CALL_CONTEXT_SIZE    (V_REG_TOTAL_SIZE + G_REG_TOTAL_SIZE)

#define ARGS_SIZE N_V_ARG_REG*V_REG_SIZE+N_G_ARG_REG*G_REG_SIZE

#define OR_ALIGNMENT 8
// 字节对齐
#define OR_ALIGN(v,a) (v + (a - 1)) / (a);

#endif
