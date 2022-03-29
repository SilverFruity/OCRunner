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
    if (typeEncoding != NULL) {
        typeEncoding = strdup(typeEncoding);
    }
    struct MFGOSimulateBlockDescriptor descriptor = {
        0,
        sizeof(struct MFSimulateBlock),
        (void (*)(void *dst, const void *src))copy_helper,
        (void (*)(const void *src))dispose_helper,
        typeEncoding
    };
    struct MFGOSimulateBlockDescriptor *_descriptor = malloc(sizeof(struct MFGOSimulateBlockDescriptor));
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
const char *NSBlockGetSignature(id block){
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
BOOL NSBlockHasSignature(id block){
    struct MFSimulateBlock *blockRef = (__bridge struct MFSimulateBlock *)block;
    int flags = blockRef->flags;
    return flags & BLOCK_HAS_SIGNATURE;
}

static void fixedBlockDispose(struct MFSimulateBlock *src) {
    struct ORFixedBlockDescriptor *descriptor = (void *)src->descriptor;
    if (src->descriptor->signature) {
        free((void *)src->descriptor->signature);
    }
    if (src->descriptor) {
        free(src->descriptor);
    }
    if (descriptor->orignalDispose) {
        descriptor->orignalDispose(src);
    }
}
void NSBlockSetSignature(id block, const char *typeencode){
    struct MFSimulateBlock *blockRef = (__bridge struct MFSimulateBlock *)block;
    // ---- 2021.9.24 TODO:
    // 针对 WKWebView 的 navigationDelegate 的 block:
    // decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
    // ios 15 下直接写入 signatureLocation 内存会导致 EXC_BAD_ACCESS 错误，同时此 block 是一个堆 block，使用内存地址直接写入按理说应该是没有问题。不知是对此内存做了内存保护🤔？可是当在调试的时候，使用 lldb 调试器写入该地址，却完全没有问题。
    // 目前为了规避崩溃问题，既然不能操作 signature 的地址内存，那就直接覆盖 descriptor 的内存
    // ⚠️ 此处存在的问题为：使用 malloc 开辟的内存空间，存在内存泄漏的问题。
    
    // NOTE: 2021.11.25
    // 如果 BLOCK_HAS_SIGNATURE 为 false，descriptor 中是不会有 signature 字段的
    bool isFixedBlock = false;
    if (NSBlockHasSignature(block) == false) {
        struct ORFixedBlockDescriptor *des = malloc(sizeof(struct ORFixedBlockDescriptor));
        memcpy(des, blockRef->descriptor, sizeof(struct MFGOSimulateBlockDescriptor));
        blockRef->descriptor = (void *)des;
        isFixedBlock = true;
    }

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
    if (isFixedBlock) {
        struct ORFixedBlockDescriptor *descriptor = (void *)blockRef->descriptor;
        descriptor->orignalDispose = blockRef->descriptor->dispose;
        blockRef->descriptor->dispose = (void *)&fixedBlockDispose;
    }
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
    return [self blockPtr];
}
- (void)setParamTypes:(NSMutableArray<ORTypeVarPair *> *)paramTypes{
    NSMutableArray *types = [@[[ORTypeVarPair typePairWithTypeKind:TypeBlock]] mutableCopy];
    [types addObjectsFromArray:paramTypes];
    _paramTypes = types;
}
- (void *)blockPtr{
    if (_blockPtr != NULL) {
        return _blockPtr;
    }
    const char *typeEncoding = self.retType.typeEncode;
    char typeEncodeBuffer[256] = {0};
    strcat(typeEncodeBuffer, typeEncoding);
    for (ORTypeVarPair *param in self.paramTypes) {
        const char *paramTypeEncoding = param.typeEncode;
        strcat(typeEncodeBuffer, paramTypeEncoding);
    }
    _ffi_result = register_function(&blockInter, self.paramTypes, self.retType);
    _blockPtr = simulateNSBlock(typeEncodeBuffer, _ffi_result->function_imp, (__bridge  void *)self);
    return _blockPtr;
}

-(void)dealloc{
    if (_ffi_result != NULL) {
        or_ffi_result_free(_ffi_result);
    }
    return;
}

@end
