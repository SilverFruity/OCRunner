//
//  MFStructDeclare.m
//  MangoFix
//
//  Created by jerry.yong on 2017/11/16.
//  Copyright © 2017年 yongpengliang. All rights reserved.
//

#import "ORStructDeclare.h"
void structDetect(char chr, NSString *content, NSMutableString *buffer, NSUInteger lf, NSMutableArray *results){
    [buffer appendFormat:@"%c",chr];
    if (chr == '{'){
        lf++;
        if (lf == 2) {
            buffer = [buffer substringWithRange:NSMakeRange(0, buffer.length - 1)].mutableCopy;
            [results addObject:buffer];
            buffer = [NSMutableString string];
            [buffer appendFormat:@"%c",chr];
            lf = 1;
        }
        structDetect(content.UTF8String[0],[content substringWithRange:NSMakeRange(1, content.length - 1)],buffer, lf, results);
        return;
    }
    if (content.length == 0) {
        [results addObject:buffer];
        return;
    }
    if (chr == '}'){
        [results addObject:buffer];
        buffer = [NSMutableString string];
        lf--;
    }
    structDetect(content.UTF8String[0],[content substringWithRange:NSMakeRange(1, content.length - 1)],buffer, lf, results);
}
NSMutableArray * startStructDetect(const char *typeEncode){
    NSMutableString *buffer = [NSMutableString string];
    NSString *content = [NSString stringWithUTF8String:typeEncode];
    NSMutableArray *results = [NSMutableArray array];
    structDetect(content.UTF8String[0],[content substringWithRange:NSMakeRange(1, content.length - 1)],buffer, 0, results);
    return results;
}

void detectTypeEncode(char chr, NSString *content, NSMutableString *buffer, NSMutableArray *types){
    [buffer appendFormat:@"%c",chr];
    if (chr != '^') {
        [types addObject:buffer];
        buffer = [NSMutableString string];
    }
    if (content.length != 0) {
        detectTypeEncode(content.UTF8String[0],[content substringWithRange:NSMakeRange(1, content.length - 1)],buffer,types);
    }
}
NSMutableArray * startDetectTypeEncode(NSString *content){
    NSMutableString *buffer = [NSMutableString string];
    NSMutableArray *results = [NSMutableArray array];
    detectTypeEncode(content.UTF8String[0],[content substringWithRange:NSMakeRange(1, content.length - 1)],buffer, results);
    return results;
}

@implementation ORStructDeclare
+ (instancetype)structDecalre:(const char *)encode keys:(NSArray *)keys{
    return [[self alloc] initWithTypeEncode:encode keys:keys];
}
- (instancetype)initWithTypeEncode:(const char *)typeEncoding keys:(NSArray<NSString *> *)keys{
    self = [super init];
    NSMutableArray *results = startStructDetect(typeEncoding);
    if (results.count > 1) {
        NSString *nameElement = results[0];
        NSString *structName = [nameElement substringWithRange:NSMakeRange(1, nameElement.length - 2)];
        if ([structName hasPrefix:@"_"]) {
            structName = [structName substringWithRange:NSMakeRange(1, structName.length - 1)];
        }
        [results removeObjectAtIndex:0];
        [results removeLastObject]; //remove "}"
        self.name = structName;
        self.keys = keys;
        [self initialWithFieldTypeEncodes:[results copy]];
    }else{
        NSString *structEncode = results[0];
        structEncode = [structEncode substringWithRange:NSMakeRange(1, structEncode.length - 2)];
        NSArray *comps = [structEncode componentsSeparatedByString:@"="];
        NSString *structName = comps.firstObject;
        if ([structName hasPrefix:@"_"]) {
            structName = [structName substringWithRange:NSMakeRange(1, structName.length - 1)];
        }
        self.name = structName;
        self.keys = keys;
        NSArray *elementEncodes = startDetectTypeEncode(comps.lastObject);
        [self initialWithFieldTypeEncodes:[elementEncodes copy]];
    }
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
