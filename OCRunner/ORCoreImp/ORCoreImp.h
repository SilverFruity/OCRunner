//
//  ORImp.h
//  OCRunner
//
//  Created by Jiang on 2020/6/8.
//  Copyright © 2020 SilverFruity. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MFBlock.h"
#import "ORCoreFunction.h"
@class MFValue;
FOUNDATION_EXPORT void blockInter(ffi_cif *cfi,void *ret,void **args, void*userdata);
FOUNDATION_EXPORT void methodIMP(ffi_cif *cfi,void *ret,void **args, void*userdata);
FOUNDATION_EXPORT void getterImp(ffi_cif *cfi,void *ret,void **args, void*userdata);
FOUNDATION_EXPORT void setterImp(ffi_cif *cfi,void *ret,void **args, void*userdata);
FOUNDATION_EXPORT MFValue *invoke_sueper_values(id instance, SEL sel, Class classNode, NSArray<MFValue *> *argValues);
