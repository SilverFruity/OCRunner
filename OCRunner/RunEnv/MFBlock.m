//
//  MFBlock.m
//  MangoFix
//
//  Created by jerry.yong on 2017/12/26.
//  Copyright © 2017年 yongpengliang. All rights reserved.
//

#import "MFBlock.h"
#import "ffi.h"
#import "util.h"
#import "RunnerClasses+Execute.h"
#import "MFValue.h"

void copy_helper(struct MFSimulateBlock *dst, struct MFSimulateBlock *src)
{
    // do not copy anything is this funcion! just retain if need.
    CFRetain(dst->wrapper);
}

void dispose_helper(struct MFSimulateBlock *src)
{
    free((void *)src->descriptor->signature);
    CFRelease(src->wrapper);
}


static void blockInter(struct MFSimulateBlock *block){
    void *args[8];
    __asm__ volatile
    (
     "str x0, [%[args]]\n"
     "str x1, [%[args], #0x8]\n"
     "str x2, [%[args], #0x10]\n"
     "str x3, [%[args], #0x18]\n"
     "str x4, [%[args], #0x20]\n"
     "str x5, [%[args], #0x28]\n"
     "str x6, [%[args], #0x30]\n"
     "str x7, [%[args], #0x38]\n"
     :
     : [args]"r"(args)
     );
    NSMethodSignature *sig = [NSMethodSignature signatureWithObjCTypes:block->descriptor->signature];
    NSUInteger numberOfArguments = [sig numberOfArguments];
    MFBlock *mangoBlock =  (__bridge MFBlock *)(block->wrapper);
    // 在OC中，传入值都为原数值并非MFValue，需要转换
    NSMutableArray *argValues = [NSMutableArray array];
    for (NSUInteger i = 1; i < numberOfArguments ; i++) {
        void *arg = args[i];
        MFValue *argValue = [[MFValue alloc] initTypeEncode:[sig getArgumentTypeAtIndex:i] pointer:&arg];
        [argValues addObject:argValue];
    }
    [[MFStack argsStack] push:argValues];
    MFValue *value = [mangoBlock.func execute:mangoBlock.outScope];
    __autoreleasing MFValue *retValue = [MFValue defaultValueWithTypeEncoding:[sig methodReturnType]];
    if (retValue.type == TypeVoid){
        return;
    }
    retValue.pointer = value.pointer;
    __asm__ volatile
    (
     "mov x0, %[ret]\n"
     :
     : [ret]"r"(retValue.pointer)
     );
}

@implementation MFBlock{
    BOOL _generatedPtr;
    void *_blockPtr;
    struct MFGOSimulateBlockDescriptor *_descriptor;
}

+ (const char *)typeEncodingForBlock:(id)block{
    struct MFSimulateBlock *blockRef = (__bridge struct MFSimulateBlock *)block;
    int flags = blockRef->flags;
    
    if (flags & BLOCK_HAS_SIGNATURE) {
        void *signatureLocation = blockRef->descriptor;
        signatureLocation += sizeof(unsigned long int);
        signatureLocation += sizeof(unsigned long int);
        
        if (flags & BLOCK_HAS_COPY_DISPOSE) {
            signatureLocation += sizeof(void(*)(void *dst, void *src));
            signatureLocation += sizeof(void (*)(void *src));
        }
        
        const char *signature = (*(const char **)signatureLocation);
        return signature;
    }
    return NULL;
}

- (id)ocBlock{
    return [self blockPtr];
}

- (void *)blockPtr{
    
    if (_generatedPtr) {
        return _blockPtr;
    }
    _generatedPtr = YES;
    const char *typeEncoding = self.typeEncoding;
    struct MFGOSimulateBlockDescriptor descriptor = {
        0,
        sizeof(struct MFSimulateBlock),
        (void (*)(void *dst, const void *src))copy_helper,
        (void (*)(const void *src))dispose_helper,
        typeEncoding
    };
    _descriptor = malloc(sizeof(struct MFGOSimulateBlockDescriptor));
    memcpy(_descriptor, &descriptor, sizeof(struct MFGOSimulateBlockDescriptor));
    
    struct MFSimulateBlock simulateBlock = {
        &_NSConcreteStackBlock,
        (BLOCK_HAS_COPY_DISPOSE | BLOCK_HAS_SIGNATURE | BLOCK_CREATED_FROM_MFGO),
        0,
        &blockInter,
        _descriptor,
        (__bridge void*)self
    };
    _blockPtr = Block_copy(&simulateBlock);
    return _blockPtr;
}

-(void)dealloc{
    free(_descriptor);
    return;
}

@end
