//
//  ORHandleTypeEncode.m
//  OCRunner
//
//  Created by Jiang on 2020/7/15.
//  Copyright © 2020 SilverFruity. All rights reserved.
//

#import "ORHandleTypeEncode.h"
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
void structNameDetect(const char *chr, char lf_chr, char rt_chr, NSMutableString *buffer){
    if (strlen(chr) == 0) return;
    if (*chr == '=' || *chr == rt_chr) {
        return;
    }
    if (*chr != lf_chr && *chr != '^') {
        [buffer appendFormat:@"%c",*chr];
    }
    structNameDetect(++chr, lf_chr, rt_chr, buffer);
}
NSString *startStructNameDetect(const char *typeEncode){
    NSMutableString *buffer = [NSMutableString string];
    structNameDetect(typeEncode, '{', '}', buffer);
    return buffer;
}
NSString *startUnionNameDetect(const char *typeEncode){
    NSMutableString *buffer = [NSMutableString string];
    structNameDetect(typeEncode, '(', ')', buffer);
    return buffer;
}
typedef struct{
    const char *chr;
    BOOL isDetectName;
    BOOL isNumberTogether;
    char lf_chr;
    char rt_chr;
    char embed1_lf_chr;
    char embed1_rt_chr;
    char embed2_lf_chr;
    char embed2_rt_chr;
    int lf;
    int rt;
    int embed1_lf_count;
    int embed1_rt_count;
    int embed2_lf_count;
    int embed2_rt_count;
}StructDetectState;

void structDetect(StructDetectState state, NSMutableString *buffer, NSMutableArray *results){
    if (strlen(state.chr) == 0) return;
    char chr = *state.chr;
    char nextChr = *(state.chr + 1);
    if (state.isDetectName) {
        if (chr == '=') {
            state.isDetectName = NO;
            [results addObject:buffer];
            buffer = [NSMutableString string];
        }else{
            [buffer appendFormat:@"%c",chr];
        }
        state.chr++;
        structDetect(state, buffer, results);
        return;
    }
    [buffer appendFormat:@"%c",chr];
    if (chr == state.lf_chr) {
        state.lf++;
    }else if (chr == state.rt_chr){
        state.rt++;
    }else if (chr == state.embed1_lf_chr){
        state.embed1_lf_count = 1;
        state.chr++;
        while (state.embed1_lf_count != state.embed1_rt_count) {
            chr = *state.chr;
            [buffer appendFormat:@"%c",chr];
            if (chr == state.embed1_lf_chr) {
                state.embed1_lf_count++;
            }else if (chr == state.embed1_rt_chr){
                state.embed1_rt_count++;
            }
            state.chr++;
        }
        state.chr--;
        state.embed1_lf_count = 0;
        state.embed1_rt_count = 0;
    }else if (chr == state.embed2_lf_chr){
        state.embed2_lf_count = 1;
        state.chr++;
        while (state.embed2_lf_count != state.embed2_rt_count) {
            chr = *state.chr;
            [buffer appendFormat:@"%c",chr];
            if (chr == state.embed2_lf_chr) {
                state.embed2_lf_count++;
            }else if (chr == state.embed2_rt_chr){
                state.embed2_rt_count++;
            }
            state.chr++;
        }
        state.chr--;
        state.embed2_lf_count = 0;
        state.embed2_rt_count = 0;
    }
    
    BOOL isNumber = chr >= '0' && chr <= '9';
    BOOL nextIsNumber = nextChr >= '0' && nextChr <= '9';
    BOOL seekNumber = state.isNumberTogether && isNumber && nextIsNumber;
    if (state.lf == state.rt && chr != '^' && seekNumber == NO) {
        [results addObject:buffer];
        buffer = [NSMutableString string];
        state.lf = 0;
        state.rt = 0;
    }
    if (strlen(state.chr) == 0) {
        return;
    }
    state.chr++;
    structDetect(state, buffer, results);
}

void structFindMaxFieldSize(const char *typeEncode, int *max) {
    if (!isStructWithTypeEncode(typeEncode)) {
        NSUInteger size = 0;
        NSGetSizeAndAlignment(typeEncode, &size, NULL);
        *max = MAX(*max, (int)size);
        return;
    }
    NSMutableArray *list = startStructDetect(typeEncode);
    [list removeObjectAtIndex:0];
    for (NSString *element in list) {
        const char *cstr = element.UTF8String;
        if (isStructWithTypeEncode(cstr)) {
            structFindMaxFieldSize(cstr, max);
        } else {
            structFindMaxFieldSize(cstr, max);
        }
    }
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
    StructDetectState state;
    memset(&state, 0, sizeof(StructDetectState));
    state.chr = content;
    state.isDetectName = YES;
    state.lf_chr = '{';
    state.rt_chr = '}';
    state.embed1_lf_chr = '(';
    state.embed1_rt_chr = ')';
    state.embed2_lf_chr = '[';
    state.embed2_rt_chr = ']';
    structDetect(state, buffer, results);
    return results;
}

NSMutableArray * startUnionDetect(const char *typeEncode){
    NSMutableString *buffer = [NSMutableString string];
    NSMutableArray *results = [NSMutableArray array];
    size_t length = strlen(typeEncode);
    char content[length + 1];
    if (*typeEncode == '(') {
        // remove '{' '}'
        strlcpy(content, typeEncode + 1, length - 1);
    }else{
        strlcpy(content, typeEncode, length);
    }
    StructDetectState state;
    memset(&state, 0, sizeof(StructDetectState));
    state.chr = content;
    state.isDetectName = YES;
    state.lf_chr = '(';
    state.rt_chr = ')';
    state.embed1_lf_chr = '{';
    state.embed1_rt_chr = '}';
    state.embed2_lf_chr = '[';
    state.embed2_rt_chr = ']';
    structDetect(state, buffer, results);
    return results;
}

NSMutableArray * startArrayDetect(const char *typeEncode){
    NSMutableString *buffer = [NSMutableString string];
    NSMutableArray *results = [NSMutableArray array];
    size_t length = strlen(typeEncode);
    char content[length + 1];
    if (*typeEncode == '[') {
        // remove '{' '}'
        strlcpy(content, typeEncode + 1, length - 1);
    }else{
        strlcpy(content, typeEncode, length);
    }
    StructDetectState state;
    memset(&state, 0, sizeof(StructDetectState));
    state.chr = content;
    state.isDetectName = NO;
    state.isNumberTogether = YES;
    state.lf_chr = '[';
    state.rt_chr = ']';
    state.embed1_lf_chr = '{';
    state.embed1_rt_chr = '}';
    state.embed2_lf_chr = '(';
    state.embed2_rt_chr = ')';
    structDetect(state, buffer, results);
    return results;
}



// {CGRect={CGPoint={CGPoint=dd}{CGSize=dd}} -> dddd
/*
  typeEncode: {ContainerStruct={Element1Struct=^^i^id}^{Element1Struct}{Element2Struct=ddd{Element1Struct=^^i^id}}^{Element2Struct}}
  result: ^^i^id^{Element1Struct}ddd^^i^id^{Element2Struct}
 */
NSString * detectStructMemeryLayoutEncodeCode(const char *typeEncode){
    NSMutableString *result = [NSMutableString string];
    BOOL startLayout = NO;
    // for ^{CGRect}, struct pointer
    BOOL isStructPointer = NO;
    while (typeEncode != NULL && *typeEncode != '\0') {
        if (*typeEncode == '^' && *(typeEncode + 1) == '{'){
            isStructPointer = YES;
        }
        if (isStructPointer) {
            isStructPointer = *typeEncode != '}';
            [result appendFormat:@"%c",*typeEncode];
            typeEncode++;
            continue;
        }
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
NSMutableArray *detectStructFieldTypeEncodes(const char *typeEncode){
    NSString *layout = detectStructMemeryLayoutEncodeCode(typeEncode);
    return detectFieldTypeEncodes(layout.UTF8String);
}
/*
 typeEncode: ^^i^id^{Element1Struct}
 result: ["^^i","^i","d","^{Element1Struct}"]
*/
NSMutableArray *detectFieldTypeEncodes(const char *structMemeryLayoutEncodeCode){
    const char *typeEncode = structMemeryLayoutEncodeCode;
    BOOL isStructPointer = NO;
    NSMutableArray *results = [NSMutableArray array];
    NSMutableString *buffer = [NSMutableString string];
    while (typeEncode != NULL && *typeEncode != '\0') {
        [buffer appendFormat:@"%c",*typeEncode];
        if (*typeEncode != '^' && isStructPointer == NO) {
            [results addObject:buffer];
            buffer = [NSMutableString string];
            typeEncode++;
            continue;
        }
        if (*(typeEncode + 1) == '{'){
            isStructPointer = YES;
        }
        if (isStructPointer) {
            if (*typeEncode == '}'){
                isStructPointer = NO;
                [results addObject:buffer];
                buffer = [NSMutableString string];
            }
            typeEncode++;
            continue;
        }
        typeEncode++;
    }
    return results;
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
    // for ^{CGRect}, struct pointer
    BOOL isStructPointer = NO;
    while (typeEncode != NULL && *typeEncode != '\0') {
        if (*typeEncode == '^' && *(typeEncode + 1) == '{'){
            isStructPointer = YES;
        }
        if (isStructPointer) {
            isStructPointer = *typeEncode != '}';
            if (*typeEncode == '{') {
                count++;
            }
            typeEncode++;
            continue;
        }
        if (*typeEncode != '^') {
            count++;
        }
        typeEncode++;
    }
    return count;
}
BOOL isStructWithTypeEncode(const char *typeEncode){
    if (typeEncode == NULL) return NO;
    return *typeEncode == '{';
}
BOOL isStructPointerWithTypeEncode(const char *typeEncode){
    return isStructOrStructPointerWithTypeEncode(typeEncode) && (*typeEncode == '^');
}
BOOL isStructOrStructPointerWithTypeEncode(const char *typeEncode){
    if (typeEncode == NULL) return NO;
    NSString *encode = [NSString stringWithUTF8String:typeEncode];
    NSString *ignorePointer = [encode stringByReplacingOccurrencesOfString:@"^" withString:@""];
    return *ignorePointer.UTF8String == '{';
}
BOOL isHFAStructWithTypeEncode(const char *typeEncode){
    if (!isStructWithTypeEncode(typeEncode)) {
        return NO;
    }
    NSString *typeencode = detectStructMemeryLayoutEncodeCode(typeEncode);
    return isHomogeneousFloatingPointAggregate(typeencode.UTF8String);
}
NSUInteger totalFieldCountWithTypeEncode(const char *typeEncode){
    if (!isStructWithTypeEncode(typeEncode)) {
        return 1;
    }
    NSString *typeencode = detectStructMemeryLayoutEncodeCode(typeEncode);
    return fieldCountInStructMemeryLayoutEncode(typeencode.UTF8String);
}

BOOL isIntegerWithTypeEncode(const char *typeEncode){
    if (typeEncode == NULL) return NO;
    switch (*typeEncode) {
        case OCTypeChar:
        case OCTypeShort:
        case OCTypeInt:
        case OCTypeLong:
        case OCTypeLongLong:
        case OCTypeUChar:
        case OCTypeUShort:
        case OCTypeUInt:
        case OCTypeULong:
        case OCTypeULongLong:
        case OCTypeBOOL:
            return YES;
        default:
            return NO;
    }
    
    return NO;
}
BOOL isFloatWithTypeEncode(const char *typeEncode){
    if (typeEncode == NULL) return NO;
    return *typeEncode == 'f' || *typeEncode == 'd';
}
BOOL isObjectWithTypeEncode(const char *typeEncode){
    if (typeEncode == NULL) return NO;
    switch (*typeEncode){
        case OCTypeSEL:
        case OCTypeCString:
        case OCTypeClass:
        case OCTypeObject:
            return YES;
        default:
            return NO;
    }
}
BOOL isPointerWithTypeEncode(const char *typeEncode){
    if (typeEncode == NULL) return NO;
    return *typeEncode == OCTypePointer;
}
NSUInteger sizeOfTypeEncode(const char *typeEncode){
    NSUInteger size;
    NSGetSizeAndAlignment(typeEncode, &size, NULL);
    return size;
}
