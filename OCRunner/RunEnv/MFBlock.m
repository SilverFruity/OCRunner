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
    if (dst->wrapper) {
        CFRetain(dst->wrapper);
    }
}

void dispose_helper(struct MFSimulateBlock *src)
{
    if (src->descriptor->signature) {
        free((void *)src->descriptor->signature);
    }
    if (src->descriptor) {
        free(src->descriptor);
    }
    if (src->wrapper) {
        CFRelease(src->wrapper);
    }
}
void *simulateNSBlock(const char* typeEncoding, void *imp, void *userdata){
    struct MFGOSimulateBlockDescriptor descriptor = {
        0,
        sizeof(struct MFSimulateBlock),
        (void (*)(void *dst, const void *src))copy_helper,
        (void (*)(const void *src))dispose_helper,
        typeEncoding
    };
    struct MFGOSimulateBlockDescriptor *_descriptor = (struct MFGOSimulateBlockDescriptor *)malloc(sizeof(struct MFGOSimulateBlockDescriptor));
    memcpy(_descriptor, &descriptor, sizeof(struct MFGOSimulateBlockDescriptor));
    struct MFSimulateBlock simulateBlock = {
        &_NSConcreteStackBlock,
        (BLOCK_HAS_COPY_DISPOSE | BLOCK_CREATED_FROM_MFGO),
        0,
        imp,
        _descriptor,
        userdata
    };
    if (typeEncoding != NULL) {
        simulateBlock.flags |= BLOCK_HAS_SIGNATURE;
    }
    return Block_copy(&simulateBlock);
}
const char *NSBlockGetSignature(void * block){
    struct MFSimulateBlock *blockRef = (struct MFSimulateBlock *)block;
    int flags = blockRef->flags;
    if (flags & BLOCK_HAS_SIGNATURE) {
        char *signatureLocation = (char *)blockRef->descriptor;
        signatureLocation += sizeof(size_t);
        signatureLocation += sizeof(size_t);
        
        if (flags & BLOCK_HAS_COPY_DISPOSE) {
            signatureLocation += sizeof(void(*)(void *dst, void *src));
            signatureLocation += sizeof(void (*)(void *src));
        }
        
        const char *signature = (*(const char **)signatureLocation);
        return signature;
    }
    return NULL;
}
BOOL NSBlockHasSignature(void *block){
    struct MFSimulateBlock *blockRef = (struct MFSimulateBlock *)block;
    int flags = blockRef->flags;
    return flags & BLOCK_HAS_SIGNATURE;
}
void NSBlockSetSignature(void * block, const char *typeencode){
    struct MFSimulateBlock *blockRef = (struct MFSimulateBlock *)block;
    char *signatureLocation = (char *)blockRef->descriptor;
    signatureLocation += sizeof(size_t);
    signatureLocation += sizeof(size_t);
    int flags = blockRef->flags;
    if (flags & BLOCK_HAS_COPY_DISPOSE) {
        signatureLocation += sizeof(void(*)(void *dst, void *src));
        signatureLocation += sizeof(void (*)(void *src));
    }
    char *copied = strdup(typeencode);
    *(char **)signatureLocation = copied;
    blockRef->flags |= BLOCK_HAS_SIGNATURE;
}

@implementation MFBlock{
    void *_blockPtr;
    or_ffi_result *_ffi_result;
}
- (instancetype)init
{
    self = [super init];
    if (self) {
        _blockPtr = NULL;
        _ffi_result = NULL;
    }
    return self;
}
- (id)ocBlock{
    return (__bridge id)[self blockPtr];
}
- (void)setParamTypes:(NSMutableArray<ORDeclaratorNode *> *)paramTypes{
    NSMutableArray *types = [@[[ocDecl declWithTypeEncode:OCTypeStringBlock]] mutableCopy];
    [types addObjectsFromArray:paramTypes];
    _paramTypes = types;
    
}
- (void *)blockPtr{
    if (_blockPtr != NULL) {
        return _blockPtr;
    }
    const char *typeEncoding = self.retType.symbol.decl.typeEncode;
    for (ORDeclaratorNode *param in self.paramTypes) {
        const char *paramTypeEncoding = param.symbol.decl.typeEncode;
        typeEncoding = mf_str_append(typeEncoding, paramTypeEncoding);
    }
    _ffi_result = register_function(&blockInter, (NSArray <ocDecl *>*)self.paramTypes, self.retType.symbol.decl);
    _blockPtr = simulateNSBlock(typeEncoding, _ffi_result->function_imp, (__bridge  void *)self);
    return _blockPtr;
}

-(void)dealloc{
    if (_ffi_result != NULL) {
        or_ffi_result_free(_ffi_result);
    }
    return;
}

@end
