//
//  ORMultiArgsMethodCall-arm64.s
//  OCDevApp
//
//  Created by Jiang on 2020/6/4.
//  Copyright © 2020 SilverFruity. All rights reserved.
//
/*
 void ORMultiArgsMethodCall(id target,SEL sel,void **args, NSUInteger count, void *funcPtr){
     NSUInteger latest = count - 1;
     while (latest > 0) {
         NSUInteger index = count - latest;
         void *element = *(void **)args[index];
         NSUInteger offset = (index - 1) * 8;
         // str %[element] [sp, offset]
         latest--;
     }
     mov x0 *(void **)*args
     memcpy(sp,*(void **)*(args + 1), (count - 1) * 8)
     // funcPtr -> &objc_msgSend
     objc_msgSend(target,sel,*(void **)*args, sp)
 }
 */

#ifdef __arm64__
.text
.global _ORMultiArgsMethodCall
ORMultiArgsMethodImp:
ldr    x8, [sp, #0x10]          ; args[0]
ldr    x8, [x8]
ldr    x8, [x8]
mov    x2, x8
ldr    x0, [sp, #0x20]           ; target
ldr    x1, [sp, #0x18]           ; sel
ldr    x8, [sp]                  ; funcPtr
mov    sp, x3
blr    x8                        ; call funcPtr
add    sp, sp, #0xf0
ldp    x29, x30, [sp, #0x70]
add    sp, sp, #0x80             ; =0x80
ret

ORMultiArgsMethodLoop:
ldr    x8, [sp, #0x8]
ldr    x9, [x29, -0x8]
sub    x8, x8, x9
str    x8, [x29, #-0x10]
ldr    x8, [sp, #0x10]
ldr    x9, [x29, #-0x10]
mov    x10, #0x8
mul    x9, x9, x10
add    x8, x8, x9
ldr    x8, [x8]
ldr    x8, [x8]
str    x8, [x29, #-0x18]
ldr    x8, [x29, #-0x10]
sub    x8, x8, #0x1
lsl    x8, x8, #3
ldr    x9, [x29, #-0x18]
str    x9, [x3, x8]              ; store %[element] [sp, x8]
ldr    x8, [x29, -0x8]
sub    x8, x8, #0x1
str    x8, [x29, -0x8]
cmp    x8, #0x0
b.gt   ORMultiArgsMethodLoop
b.le   ORMultiArgsMethodImp

_ORMultiArgsMethodCall:
sub    sp, sp, #0x80             ; =0x80
stp    x29, x30, [sp, #0x70]
add    x29, sp, #0x70            ; =0x70
str    x0, [sp, #0x20]           ; target
str    x1, [sp, #0x18]           ; sel
str    x2, [sp, #0x10]           ; args
str    x3, [sp, #0x8]            ; count
str    x4, [sp]                  ; funcPtr
ldr    x8, [sp, #0x8]
sub    x8, x8, #0x1
str    x8, [x29, -0x8]           ; [x29, -0x8] latest
sub    x3, sp, #0xf0  ; max count 32 args
cmp    x8, #0x0
b.gt   ORMultiArgsMethodLoop
b.eq   ORMultiArgsMethodImp
#endif
