//
//  MFStructDeclare.m
//  MangoFix
//
//  Created by jerry.yong on 2017/11/16.
//  Copyright © 2017年 yongpengliang. All rights reserved.
//

#import "ORStructDeclare.h"
#import "ORHandleTypeEncode.h"

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

#import "ORTypeVarPair+TypeEncode.h"
@implementation ORSymbolItem
- (NSString *)description{
    return [NSString stringWithFormat:@"ORSymbolItem:{ encode:%@ type: %@ }",self.typeEncode,self.typeName];
}
@end
@implementation ORTypeSymbolTable{
    NSMutableDictionary<NSString *, ORSymbolItem *> *_table;
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
    [self addTypePair:typePair forAlias:typePair.var.varname];
}
- (void)addTypePair:(ORTypeVarPair *)typePair forAlias:(NSString *)alias{
    ORSymbolItem *item = [self symbolItemForTypeName:alias];
    if (item == nil) {
        item = [[ORSymbolItem alloc] init];
        item.typeEncode = [NSString stringWithUTF8String:typePair.typeEncode];
        item.typeName = typePair.type.name;
    }
    [self addSybolItem:item forAlias:alias];
}
- (void)addSybolItem:(ORSymbolItem *)item forAlias:(NSString *)alias{
    NSAssert(alias != nil, @"");
    if (alias.length == 0) {
        return;
    }
    [_lock lock];
    _table[alias] = item;
    [_lock unlock];
}
- (ORSymbolItem *)symbolItemForTypeName:(NSString *)typeName{
    [_lock lock];
    ORSymbolItem *item = _table[typeName];
    [_lock unlock];
    return item;
}
@end
