//
//  MFStructDeclare.m
//  MangoFix
//
//  Created by jerry.yong on 2017/11/16.
//  Copyright © 2017年 yongpengliang. All rights reserved.
//

#import "ORStructDeclare.h"
void removePointerOfTypeEncode(char chr, NSString *content, NSMutableString *buffer){
    if (chr != '^') {
        [buffer appendFormat:@"%c%@",chr,content];
        return;
    }
    removePointerOfTypeEncode(content.UTF8String[0], [content substringWithRange:NSMakeRange(1, content.length - 1)], buffer);
}

NSString *startRemovePointerOfTypeEncode(const char *typeEncode){
    NSString *content = [NSString stringWithUTF8String:typeEncode];
    NSMutableString *buffer = [NSMutableString string];
    removePointerOfTypeEncode(content.UTF8String[0], [content substringWithRange:NSMakeRange(1, content.length - 1)], buffer);
    return buffer;
}
void detectPointerCount(char chr, NSString *content, NSUInteger *count){
    if (chr == '^') {
        (*count)++;
        detectPointerCount(content.UTF8String[0],[content substringWithRange:NSMakeRange(1, content.length - 1)],count);
    }else{
        return;
    }
}
NSUInteger startDetectPointerCount(const char *typeEncode){
    NSUInteger ptCount = 0;
    NSString *content = [NSString stringWithUTF8String:typeEncode];
    detectPointerCount(content.UTF8String[0], [content substringWithRange:NSMakeRange(1, content.length - 1)], &ptCount);
    return ptCount;
}
void structNameDetect(char chr, NSString *content, NSMutableString *buffer){
    if (chr == '=' || chr == '}') {
        return;
    }
    if (chr != '{' && chr != '^') {
        [buffer appendFormat:@"%c",chr];
    }
    structNameDetect(content.UTF8String[0], [content substringWithRange:NSMakeRange(1, content.length - 1)], buffer);
}
NSString *startStructNameDetect(const char *typeEncode){
    NSString *content = [NSString stringWithUTF8String:typeEncode];
    NSMutableString *buffer = [NSMutableString string];
    structNameDetect(content.UTF8String[0],[content substringWithRange:NSMakeRange(1, content.length - 1)],buffer);
    return buffer;
}
void structDetect(char chr, NSString *content, NSMutableString *buffer, NSMutableArray *results, NSUInteger lf, NSUInteger rt, BOOL needfirstAssign){
    [buffer appendFormat:@"%c",chr];
    if (needfirstAssign) {
        if (chr == '=') {
            needfirstAssign = NO;
            [results addObject:buffer];
            buffer = [NSMutableString string];
        }
        structDetect(content.UTF8String[0],[content substringWithRange:NSMakeRange(1, content.length - 1)],buffer, results, lf, rt, needfirstAssign);
        return;
    }
    if (chr == '{'){
        lf++;
    }
    if (chr == '}'){
        rt++;
    }
    if (lf == rt && chr != '^') {
        [results addObject:buffer];
        buffer = [NSMutableString string];
        lf = 0;
        rt = 0;
    }
    if (content.length == 0) {
        return;
    }
    structDetect(content.UTF8String[0],[content substringWithRange:NSMakeRange(1, content.length - 1)],buffer, results, lf, rt, needfirstAssign);
}
NSMutableArray * startStructDetect(const char *typeEncode){
    NSMutableString *buffer = [NSMutableString string];
    NSString *content = [NSString stringWithUTF8String:typeEncode];
    NSMutableArray *results = [NSMutableArray array];
    if ([content hasPrefix:@"{"]) {
        content = [content substringWithRange:NSMakeRange(1, content.length - 2)];
    }
    structDetect(content.UTF8String[0],[content substringWithRange:NSMakeRange(1, content.length - 1)],buffer, results, 0, 0, YES);
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

@implementation ORStructDeclare
+ (instancetype)structDecalre:(const char *)encode keys:(NSArray *)keys{
    return [[self alloc] initWithTypeEncode:encode keys:keys];
}
- (instancetype)initWithTypeEncode:(const char *)typeEncoding keys:(NSArray<NSString *> *)keys{
    self = [super init];
    self.typeEncoding = typeEncoding;
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
    NSMutableDictionary *keyOffsets = [NSMutableDictionary dictionary];
    for (NSString *key in self.keys){
        NSUInteger offset = 0;
        for (NSString *current in self.keys) {
            if ([current isEqualToString:key]){
                break;
            }
            offset += self.keySizes[current].unsignedIntegerValue;
        }
        keyOffsets[key] = @(offset);
    }
    self.keyOffsets = keyOffsets;
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
- (void)addAlias:(NSString *)alias forTypeEncode:(const char *)typeEncode{
    [_lock lock];
    NSString *structName = startStructNameDetect(typeEncode);
    if (_dic[structName]) {
        _dic[alias] = _dic[structName];
    }
    [_lock unlock];
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
