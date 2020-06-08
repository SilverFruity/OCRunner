//
//  MFBlock.m
//  MangoFix
//
//  Created by jerry.yong on 2017/12/26.
//  Copyright © 2017年 yongpengliang. All rights reserved.
//

#import "MFBlock.h"
#import "util.h"
#import "RunnerClasses+Execute.h"
#import "MFValue.h"
#import "ORCoreImp.h"

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
