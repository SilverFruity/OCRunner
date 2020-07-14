//
//  ORCoreFunctionRegister.s
//  OCRunner
//
//  Created by Jiang on 2020/7/14.
//  Copyright © 2020 SilverFruity. All rights reserved.
//
#import <mach/machine/vm_param.h>
#import "ORCoreFunctionRegister.h"

.align PAGE_MAX_SHIFT
.text
.global _ffi_closure_trampoline_table_page
_ffi_closure_trampoline_table_page:
.rept PAGE_MAX_SIZE / FFI_TRAMPOLINE_SIZE
adr x16, -PAGE_MAX_SIZE
ldp x17, x16, [x16]
blr x16
nop        /* each entry in the trampoline config page is 2*sizeof(void*) so the trampoline itself cannot be smaller that 16 bytes */
.endr
