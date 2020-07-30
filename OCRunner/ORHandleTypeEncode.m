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
        case OCTypeEncodeChar:
        case OCTypeEncodeShort:
        case OCTypeEncodeInt:
        case OCTypeEncodeLong:
        case OCTypeEncodeLongLong:
        case OCTypeEncodeUChar:
        case OCTypeEncodeUShort:
        case OCTypeEncodeUInt:
        case OCTypeEncodeULong:
        case OCTypeEncodeULongLong:
        case OCTypeEncodeBOOL:
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
        case OCTypeEncodeSEL:
        case OCTypeEncodeCString:
        case OCTypeEncodeClass:
        case OCTypeEncodeObject:
            return YES;
        default:
            return NO;
    }
}
BOOL isPointerWithTypeEncode(const char *typeEncode){
    if (typeEncode == NULL) return NO;
    return *typeEncode == OCTypeEncodePointer;
}
NSUInteger sizeOfTypeEncode(const char *typeEncode){
    NSUInteger size;
    NSGetSizeAndAlignment(typeEncode, &size, NULL);
    return size;
}
