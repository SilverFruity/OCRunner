//
//  MFStructDeclare.m
//  MangoFix
//
//  Created by jerry.yong on 2017/11/16.
//  Copyright © 2017年 yongpengliang. All rights reserved.
//

#import "ORStructDeclare.h"
void removePointerOfTypeEncode(const char *chr, NSMutableString *buffer){
    if (strlen(chr) == 0) return;
    if (*chr != '^') {
        [buffer appendFormat:@"%s",chr];
        return;
    }
    removePointerOfTypeEncode(++chr, buffer);
}

NSString *startRemovePointerOfTypeEncode(const char *typeEncode){
    NSMutableString *buffer = [NSMutableString string];
    removePointerOfTypeEncode(typeEncode, buffer);
    return buffer;
}
void detectPointerCount(const char *chr, NSUInteger *count){
    if (*chr == '^') {
        (*count)++;
        if (strlen(chr) == 0) return;
        detectPointerCount(++chr,count);
    }else{
        return;
    }
}
NSUInteger startDetectPointerCount(const char *typeEncode){
    NSUInteger ptCount = 0;
    detectPointerCount(typeEncode, &ptCount);
    return ptCount;
}
void structNameDetect(const char *chr, NSMutableString *buffer){
    if (strlen(chr) == 0) return;
    if (*chr == '=' || *chr == '}') {
        return;
    }
    if (*chr != '{' && *chr != '^') {
        [buffer appendFormat:@"%c",*chr];
    }
    structNameDetect(++chr, buffer);
}
NSString *startStructNameDetect(const char *typeEncode){
    NSMutableString *buffer = [NSMutableString string];
    structNameDetect(typeEncode,buffer);
    return buffer;
}
void structDetect(const char *chr, NSMutableString *buffer, NSMutableArray *results, NSUInteger lf, NSUInteger rt, BOOL needfirstAssign){
    if (strlen(chr) == 0) return;
    [buffer appendFormat:@"%c",*chr];
    if (needfirstAssign) {
        if (*chr == '=') {
            needfirstAssign = NO;
            [results addObject:buffer];
            buffer = [NSMutableString string];
        }
        structDetect(++chr,buffer, results, lf, rt, needfirstAssign);
        return;
    }
    if (*chr == '{'){
        lf++;
    }
    if (*chr == '}'){
        rt++;
    }
    if (lf == rt && *chr != '^') {
        [results addObject:buffer];
        buffer = [NSMutableString string];
        lf = 0;
        rt = 0;
    }
    structDetect(++chr,buffer, results, lf, rt, needfirstAssign);
}
NSMutableArray * startStructDetect(const char *typeEncode){
    NSMutableString *buffer = [NSMutableString string];
    NSMutableArray *results = [NSMutableArray array];
    size_t length = strlen(typeEncode);
    char content[length + 1];
    if (*typeEncode == '{') {
        // remove '{' '}'
        strlcpy(content, typeEncode + 1, length - 1);
    }else{
        strlcpy(content, typeEncode, length);
    }
    structDetect(content,buffer, results, 0, 0, YES);
    return results;
}

void detectTypeEncodes(char chr, NSString *content, NSMutableString *buffer, NSMutableArray *types){
    [buffer appendFormat:@"%c",chr];
    if (chr != '^') {
        [types addObject:buffer];
        buffer = [NSMutableString string];
    }
    if (content.length != 0) {
        detectTypeEncodes(content.UTF8String[0],[content substringWithRange:NSMakeRange(1, content.length - 1)],buffer,types);
    }
}
NSMutableArray * startDetectTypeEncodes(NSString *content){
    NSMutableString *buffer = [NSMutableString string];
    NSMutableArray *results = [NSMutableArray array];
    detectTypeEncodes(content.UTF8String[0],[content substringWithRange:NSMakeRange(1, content.length - 1)],buffer, results);
    return results;
}

// {CGRect={CGPoint={CGPoint=dd}{CGSize=dd}} -> dddd
NSString * detectStructMemeryLayoutEncodeCode(const char *typeEncode){
    NSMutableString *result = [NSMutableString string];
    BOOL startLayout = NO;
    while (typeEncode != NULL && *typeEncode != '\0') {
        if (*typeEncode == '=') {
            startLayout = YES;
            typeEncode++;
            continue;
        }
        if (*typeEncode == '}' || *typeEncode == '{') {
            startLayout = NO;
        }
        if (startLayout) {
            [result appendFormat:@"%c",*typeEncode];
        }
        typeEncode++;
    }
    return [result copy];
}
BOOL isHomogeneousFloatingPointAggregate(const char *typeEncode){
    while (typeEncode != NULL && *typeEncode != '\0') {
        if (*typeEncode != 'f' && *typeEncode != 'd') {
            return NO;
        }
        typeEncode++;
    }
    return YES;
}
NSUInteger fieldCountInStructMemeryLayoutEncode(const char *typeEncode){
    NSUInteger count = 0;
    while (typeEncode != NULL && *typeEncode != '\0') {
        if (*typeEncode != '^') {
            count++;
        }
        typeEncode++;
    }
    return count;
}

@implementation ORStructDeclare
+ (instancetype)structDecalre:(const char *)encode keys:(NSArray *)keys{
    return [[self alloc] initWithTypeEncode:encode keys:keys];
}
- (instancetype)initWithTypeEncode:(const char *)typeEncoding keys:(NSArray<NSString *> *)keys{
    self = [super init];
    char *encode = malloc(sizeof(char) * (strlen(typeEncoding) + 1) );
    strcpy(encode, typeEncoding);
    self.typeEncoding = encode;
    NSMutableArray *results = startStructDetect(typeEncoding);
    NSString *nameElement = results[0];
    NSString *structName = [nameElement substringWithRange:NSMakeRange(0, nameElement.length - 1)];
    [results removeObjectAtIndex:0];
    self.name = structName;
    self.keys = keys;
    [self initialWithFieldTypeEncodes:[results copy]];
    return self;
}
- (void)initialWithFieldTypeEncodes:(NSArray *)fieldEncodes{
    NSMutableDictionary *keySizes = [NSMutableDictionary dictionary];
    NSMutableDictionary *keyTyeps = [NSMutableDictionary dictionary];
    NSCAssert(self.keys.count == fieldEncodes.count, @"");
    [fieldEncodes enumerateObjectsUsingBlock:^(NSString *elementEncode, NSUInteger idx, BOOL * _Nonnull stop) {
        NSUInteger size;
        NSGetSizeAndAlignment(elementEncode.UTF8String, &size, NULL);
        keySizes[self.keys[idx]] = @(size);
        keyTyeps[self.keys[idx]] = elementEncode;
    }];
    self.keySizes = keySizes;
    self.keyTypeEncodes = keyTyeps;
    // 内存对齐
    // 第一个变量的偏移量为0，其余变量的偏移量需要是变量内存大小的的整数倍
    NSMutableDictionary <NSString *,NSNumber *>*keyOffsets = [NSMutableDictionary dictionary];
    for (int i = 0; i < self.keys.count; i++) {
        if (i == 0) {
            keyOffsets[self.keys[i]] = @(0);
            continue;
        }
        NSString *lastKey = self.keys[i - 1];
        NSUInteger lastSize = self.keySizes[lastKey].unsignedIntValue;
        NSUInteger lastOffset = keyOffsets[lastKey].unsignedIntValue;
        NSUInteger offset = lastOffset + lastSize;
        NSUInteger size = self.keySizes[self.keys[i]].unsignedIntegerValue;
        size = MIN(size, 8); // 在参数对齐数和默认对齐数8取小
        if (offset % size != 0) {
            offset = ((offset + size - 1) / size) * size;
        }
        keyOffsets[self.keys[i]] = @(offset);
    }
    self.keyOffsets = keyOffsets;
}
- (void)dealloc
{
    if (self.typeEncoding != NULL) {
        void *encode = (void *)self.typeEncoding;
        free(encode);
    }
}
@end


@implementation ORStructDeclareTable{
    NSMutableDictionary<NSString *, ORStructDeclare *> *_dic;
    NSLock *_lock;
}

- (instancetype)init{
    if (self = [super init]) {
        _dic = [NSMutableDictionary dictionary];
        _lock = [[NSLock alloc] init];
    }
    return self;
}
+ (instancetype)shareInstance{
    static id st_instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        st_instance = [[ORStructDeclareTable alloc] init];
    });
    return st_instance;
}
- (void)addAlias:(NSString *)alias forTypeName:(NSString *)name{
    [_lock lock];
    if (_dic[name]) {
        _dic[alias] = _dic[name];
    }
    [_lock unlock];
}
- (void)addAlias:(NSString *)alias forStructTypeEncode:(const char *)typeEncode{
    NSString *structName = startStructNameDetect(typeEncode);
    [self addAlias:alias forTypeName:structName];
}
- (void)addStructDeclare:(ORStructDeclare *)structDeclare{
    [_lock lock];
    _dic[structDeclare.name] = structDeclare;
    [_lock unlock];
}

- (ORStructDeclare *)getStructDeclareWithName:(NSString *)name{
    [_lock lock];
    ORStructDeclare *declare = _dic[name];
    [_lock unlock];
    return declare;
}
@end


@implementation ORTypeVarPair (Struct)
- (ORStructDeclare *)strcutDeclare{
    NSCAssert(self.type.type == TypeStruct, @"must be TypeStruct");
    return [[ORStructDeclareTable shareInstance] getStructDeclareWithName:self.type.name];
}
@end
@implementation ORTypeSymbolTable{
    NSMutableDictionary<NSString *, ORTypeVarPair *> *_table;
    NSLock *_lock;
}

- (instancetype)init{
    if (self = [super init]) {
        _table = [NSMutableDictionary dictionary];
        _lock = [[NSLock alloc] init];
    }
    return self;
}
+ (instancetype)shareInstance{
    static id st_instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        st_instance = [[ORTypeSymbolTable alloc] init];
    });
    return st_instance;
}
- (void)addTypePair:(ORTypeVarPair *)typePair{
    NSCAssert(typePair.var.varname != nil, @"");
    [self addTypePair:typePair forName:typePair.var.varname];
}
- (void)addTypePair:(ORTypeVarPair *)typePair forName:(NSString *)typeName{
    [_lock lock];
    _table[typeName] = typePair;
    [_lock unlock];
}
- (ORTypeVarPair *)typePairForTypeName:(NSString *)typeName{
    [_lock lock];
    ORTypeVarPair *typePair = _table[typeName];
    [_lock unlock];
    return typePair;
}
@end
