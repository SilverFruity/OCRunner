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
#import "ORTypeVarPair+TypeEncode.h"

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
- (void)setParamTypes:(NSMutableArray<ORTypeVarPair *> *)paramTypes{
    NSMutableArray *types = [@[[ORTypeVarPair typePairWithTypeKind:TypeBlock]] mutableCopy];
    [types addObjectsFromArray:paramTypes];
    _paramTypes = types;
}
- (void *)blockPtr{
    if (_generatedPtr) {
        return _blockPtr;
    }
    const char *typeEncoding = self.retType.typeEncode;
    for (ORTypeVarPair *param in self.paramTypes) {
        const char *paramTypeEncoding = param.typeEncode;
        typeEncoding = mf_str_append(typeEncoding, paramTypeEncoding);
    }
    _generatedPtr = YES;
    struct MFGOSimulateBlockDescriptor descriptor = {
        0,
        sizeof(struct MFSimulateBlock),
        (void (*)(void *dst, const void *src))copy_helper,
        (void (*)(const void *src))dispose_helper,
        typeEncoding
    };
    void *blockImp = register_function(&blockInter, self.paramTypes, self.retType);
    _descriptor = malloc(sizeof(struct MFGOSimulateBlockDescriptor));
    memcpy(_descriptor, &descriptor, sizeof(struct MFGOSimulateBlockDescriptor));
    struct MFSimulateBlock simulateBlock = {
        &_NSConcreteStackBlock,
        (BLOCK_HAS_COPY_DISPOSE | BLOCK_HAS_SIGNATURE | BLOCK_CREATED_FROM_MFGO),
        0,
        blockImp,
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
BOOL NSBlockHasSignature(id block){
    struct MFSimulateBlock *blockRef = (__bridge struct MFSimulateBlock *)block;
    int flags = blockRef->flags;
    return flags & BLOCK_HAS_SIGNATURE;
}
void NSBlockSetSignature(id block, const char *typeencode){
    struct MFSimulateBlock *blockRef = (__bridge struct MFSimulateBlock *)block;
    void *signatureLocation = blockRef->descriptor;
    signatureLocation += sizeof(unsigned long int);
    signatureLocation += sizeof(unsigned long int);
    int flags = blockRef->flags;
    if (flags & BLOCK_HAS_COPY_DISPOSE) {
        signatureLocation += sizeof(void(*)(void *dst, void *src));
        signatureLocation += sizeof(void (*)(void *src));
    }
    char *copied = strdup(typeencode);
    *(char **)signatureLocation = copied;
    blockRef->flags |= BLOCK_HAS_SIGNATURE;
}
