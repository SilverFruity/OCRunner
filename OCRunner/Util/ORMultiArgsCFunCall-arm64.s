//
//  MultiArgsCFunCall-arm64.s
//  OCDevApp
//
//  Created by Jiang on 2020/6/4.
//  Copyright © 2020 SilverFruity. All rights reserved.
//

/*
 void ORMultiArgsCFunCall(void **args, NSUInteger count, void *funcPt){
     NSUInteger latest = count - 1;
     while (latest > 0) {
         NSUInteger index = count - latest;
         void *element = *(void **)args[index];
         NSUInteger offset = (index - 1) * 8;
         // str %[element] [sp, offset]
         latest--;
     }
     //mov x0 *(void **)*args
     //memcpy(sp,*(void **)*(args + 1), (count - 1) * 8)
     funcPt(*(void **)*args, sp)
 }
 */
#ifdef __arm64__
.text
.global _ORMultiArgsCFunCall

ORMultiCallFuncImp:
ldr    x8, [sp, #0x38]
ldr    x8, [x8]
ldr    x8, [x8]
mov    x0, x8
mov    sp, x3
blr    x2                        ; call funcPtr
add    sp, sp, #0xf0
ldp    x29, lr, [sp, #0x40]
add    sp, sp, #0x50
ret

ORMultiArgsCFuncLoop:
ldr    x8, [sp, #0x30]
ldr    x9, [sp, #0x20]
sub    x8, x8, x9
str    x8, [sp, #0x18]
ldr    x8, [sp, #0x38]
ldr    x9, [sp, #0x18]
mov    x10, #0x8
mul    x9, x9, x10
add    x8, x8, x9
ldr    x8, [x8]
ldr    x8, [x8]
str    x8, [sp, #0x10]
ldr    x8, [sp, #0x18]
sub    x8, x8, #0x1
lsl    x8, x8, #3                ; offset
ldr    x9, [sp, #0x10]
str    x9, [x3, x8]              ; store %[element] [sp, x8]
ldr    x8, [sp, #0x20]
sub    x8, x8, #0x1
str    x8, [sp, #0x20]
cmp    x8, #0x0
b.gt   ORMultiArgsCFuncLoop
b.le   ORMultiCallFuncImp


_ORMultiArgsCFunCall:
sub    sp, sp, #0x50
stp    x29, lr, [sp, #0x40]
str    x0, [sp, #0x38] ; args
str    x1, [sp, #0x30] ; count
str    x2, [sp, #0x28] ; funcPtr
ldr    x8, [sp, #0x30]
sub    x8, x8, #0x1
str    x8, [sp, #0x20]
sub    x3, sp, #0xf0  ; max count 32 args
cmp    x8, #0x0
b.gt   ORMultiArgsCFuncLoop
ret

#endif
