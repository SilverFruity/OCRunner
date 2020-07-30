//
//  MFValue .m
//  MangoFix
//
//  Created by jerry.yong on 2018/2/28.
//  Copyright © 2018年 yongpengliang. All rights reserved.
//

#import "MFValue.h"
#import "RunnerClasses.h"
#import "util.h"
#import "ORStructDeclare.h"
#import "ORHandleTypeEncode.h"

#define MFValueBridge(target,resultType)\
resultType result;\
const char *typeEncode = target.typeEncode;\
switch (*typeEncode) {\
    case OCTypeUChar: result = (resultType)*(unsigned char *)target.pointer; break;\
    case OCTypeUInt: result = (resultType)*(unsigned int *)target.pointer; break;\
    case OCTypeUShort: result = (resultType)*(unsigned short *)target.pointer; break;\
    case OCTypeULong: result = (resultType)*(unsigned int *)target.pointer; break;\
    case OCTypeULongLong: result = (resultType)*(unsigned long long *)target.pointer; break;\
    case OCTypeBOOL: result = (resultType)*(BOOL *)target.pointer; break;\
    case OCTypeChar: result = (resultType)*(char *)target.pointer; break;\
    case OCTypeShort: result = (resultType)*(short *)target.pointer; break;\
    case OCTypeInt: result = (resultType)*(int *)target.pointer; break;\
    case OCTypeLong: result = (resultType)*(int *)target.pointer; break;\
    case OCTypeLongLong: result = (resultType)*(long long *)target.pointer; break;\
    case OCTypeFloat: result = (resultType)*(float *)target.pointer; break;\
    case OCTypeDouble: result = (resultType)*(double *)target.pointer; break;\
    default: result = 0;\
}

extern BOOL MFStatementResultTypeIsReturn(MFStatementResultType type){
    return type & MFStatementResultTypeReturnMask;
}
@interface MFValue()
@property (nonatomic,strong)id strongObjectValue;
@property (nonatomic,weak)id weakObjectValue;
@end

@implementation MFValue
{
    BOOL _isAlloced;
}
+ (instancetype)defaultValueWithTypeEncoding:(const char *)typeEncode{
    return [MFValue valueWithTypeEncode:typeEncode pointer:NULL];;
}
+ (instancetype)valueWithTypeEncode:(const char *)typeEncode pointer:(void *)pointer{
    return [[MFValue alloc]initTypeEncode:typeEncode pointer:pointer];;;
}
- (instancetype)initTypeEncode:(const char *)typeEncoding pointer:(void *)pointer{
    self = [super init];
    typeEncoding = removeTypeEncodingPrefix((char *)typeEncoding);
    self.typeEncode = typeEncoding;
    self.pointer = pointer;
    return self;
}
- (void)deallocPointer{
    if (_pointer != NULL && _isAlloced) {
        if (*_typeEncode == '*') {
            void *str = *(void **)_pointer;
            free(str);
        }
        free(_pointer);
        _pointer = NULL;
        _strongObjectValue = nil;
        _weakObjectValue = nil;
    }
}
- (void)setPointer:(void *)pointer{
    NSCAssert(self.typeEncode != NULL, @"TypeEncode must exist");
    [self deallocPointer];
    NSUInteger size = self.memerySize;
    void *dst = malloc(size);
    memset(dst, 0, size);
    _pointer = dst;
    _isAlloced = YES;
    if (pointer == NULL) {
        return;
    }
    if (*_typeEncode == '@') {
        self.strongObjectValue = *(__strong id *)pointer;
    }
    if (*_typeEncode == '*') {
        char *str = *(char **)pointer;
        size_t len = strlen(str);
        char * cstring = malloc(len * sizeof(char) + 1);
        cstring[len] = '\0';
        memcpy(cstring, str, len);
        *(void **)dst = cstring;
        return;
    }
    memcpy(dst, pointer, size);
}
- (void)setPointerCount:(NSInteger)pointerCount{
    if (pointerCount > _pointerCount) {
        //取地址，增加一个 '^'
        char *typeencode = alloca(strlen(self.typeEncode) + 2);
        memset(typeencode, 0, strlen(self.typeEncode) + 2);
        typeencode[0] = OCTypePointer;
        memcpy(typeencode + 1, self.typeEncode, strlen(self.typeEncode));
        self.typeEncode = typeencode;
    }else if (*_typeEncode == OCTypePointer){
        //取值, 减少一个 '^'
        char *typeencode = alloca(strlen(self.typeEncode));
        memset(typeencode, 0, strlen(self.typeEncode));
        memcpy(typeencode, self.typeEncode + 1, strlen(self.typeEncode) - 1);
        self.typeEncode = typeencode;
    }
}
- (void)setPointerWithNoCopy:(void *)pointer{
    [self deallocPointer];
    _pointer = pointer;
    _isAlloced = NO;
}
- (BOOL)isBlockValue{
    if (self.typeEncode == NULL) {
        return NO;
    }
    return strcmp(self.typeEncode, OCTypeStringBlock) == 0;
}
- (void)setModifier:(ORDeclarationModifier)modifier{
    if (modifier & ORDeclarationModifierWeak && (self.type == OCTypeObject || self.isBlockValue)) {
        self.weakObjectValue = self.strongObjectValue;
        self.strongObjectValue = nil;
    }
    _modifier = modifier;
}
- (OCType)type{
    if (self.typeEncode == NULL) {
        return OCTypeLongLong;
    }
    return *self.typeEncode;
}
- (void)dealloc{
    [self deallocPointer];
    if(_typeEncode != NULL) free((void *)_typeEncode);
}
- (void)setTypeEncode:(const char *)typeEncode{
    
    void *result = NULL;
    [self convertValueWithTypeEncode:typeEncode result:&result];
    
    if(_typeEncode != NULL)
        free((void *)_typeEncode);
    
    size_t strLen = strlen(typeEncode);
    char *buffer = malloc(strLen+1);
    buffer[strLen] = '\0';
    strncpy((void *)buffer, typeEncode, strLen);
    _typeEncode = buffer;

    if (result != NULL) {
        self.pointer = &result;
    }
    _pointerCount = startDetectPointerCount(typeEncode);
    if (*typeEncode == OCTypeClass) {
        self.typeName = @"Class";
    }else if(*typeEncode == OCTypeStruct){
        self.typeName = startStructNameDetect(typeEncode);
    }
}
- (void)convertValueWithTypeEncode:(const char *)typeEncode result:(void **)resultValue{
    if (self.typeEncode == NULL) {
        return;
    }
    do {
        if ((TypeEncodeIsBaseType(typeEncode)) == 0) break;
        if (*self.typeEncode == *typeEncode) break;
        if (self.pointer == NULL) break;
        //基础类型转换
        switch (*typeEncode) {
            case OCTypeUChar:{
                MFValueBridge(self, unsigned char)
                memcpy(resultValue, &result, sizeof(unsigned char));
                break;
            }
            case OCTypeUInt:{
                MFValueBridge(self, unsigned int)
                memcpy(resultValue, &result, sizeof(unsigned int));
                break;
            }
            case OCTypeUShort:{
                MFValueBridge(self, unsigned short)
                memcpy(resultValue, &result, sizeof(unsigned short));
                break;
            }
            case OCTypeULong:{
                MFValueBridge(self, unsigned long)
                memcpy(resultValue, &result, sizeof(unsigned long));
                break;
            }
            case OCTypeULongLong:{
                MFValueBridge(self, unsigned long long)
                memcpy(resultValue, &result, sizeof(unsigned long long));
                break;
            }
            case OCTypeBOOL:{
                MFValueBridge(self, BOOL)
                memcpy(resultValue, &result, sizeof(BOOL));
                break;
            }
            case OCTypeChar:{
                MFValueBridge(self, char)
                memcpy(resultValue, &result, sizeof(char));
                break;
            }
            case OCTypeShort:{
                MFValueBridge(self, short)
                memcpy(resultValue, &result, sizeof(short));
                break;
            }
            case OCTypeInt:{
                MFValueBridge(self, int)
                memcpy(resultValue, &result, sizeof(int));
                break;
            }
            case OCTypeLong:{
                MFValueBridge(self, long)
                memcpy(resultValue, &result, sizeof(long));
                break;
            }
            case OCTypeLongLong:{
                MFValueBridge(self, long long)
                memcpy(resultValue, &result, sizeof(long long));
                break;
            }
            case OCTypeFloat:{
                MFValueBridge(self, float)
                memcpy(resultValue, &result, sizeof(float));
                break;
            }
            case OCTypeDouble:{
                MFValueBridge(self, double)
                memcpy(resultValue, &result, sizeof(double));
                break;
            }
            default: break;
        }
    } while (0);
}
- (void)setTypeInfoWithValue:(MFValue *)value{
    self.typeEncode = value.typeEncode;
    self.typeName = value.typeName;
}


- (void)assignFrom:(MFValue *)src{
    [self setTypeInfoWithValue:src];
    self.pointer = src.pointer;
}
- (void)setDefaultValue{
    self.pointer = NULL;
}
- (void)setTypeBySearchInTypeSymbolTable{
    do {
        if (!self.typeName) break;
        ORSymbolItem *item = [[ORTypeSymbolTable shareInstance] symbolItemForTypeName:self.typeName];
        if (!item) break;
        self.typeName = item.typeName;
        self.typeEncode = item.typeEncode.UTF8String;
     } while (0);
}

- (void)writePointer:(void *)pointer typeEncode:(const char *)typeEncode{
    if (pointer == NULL) {
        return;
    }
    NSUInteger resultSize;
    NSGetSizeAndAlignment(typeEncode, &resultSize, NULL);
    memset(pointer, 0, resultSize);
    NSUInteger currentSize;
    NSGetSizeAndAlignment(self.typeEncode, &currentSize, NULL);
    void *copySource = self.pointer;
    void *convertResult = NULL;
    [self convertValueWithTypeEncode:typeEncode result:&convertResult];
    if (convertResult != NULL) {
        copySource = &convertResult;
    }
    if (currentSize < resultSize){
        memcpy(pointer, copySource, currentSize);
    }else{
        memcpy(pointer, copySource, resultSize);
    }
}
- (BOOL)isSubtantial{
    BOOL result = NO;
    UnaryExecute(result, !, self);
    return !result;
}
- (BOOL)isInteger{
    return isIntegerWithTypeEncode(self.typeEncode);
}
- (BOOL)isFloat{
    return isFloatWithTypeEncode(self.typeEncode);
}
- (BOOL)isObject{
    return isObjectWithTypeEncode(self.typeEncode);
}
- (BOOL)isPointer{
    return *self.typeEncode == '^';
}
- (NSUInteger)memerySize{
    if (self.typeEncode == NULL) {
        return 0;
    }
    NSUInteger size;
    NSGetSizeAndAlignment(self.typeEncode, &size, NULL);
    return size;
}
- (MFValue *)subscriptGetWithIndex:(MFValue *)index{
    if (index.type & TypeBaseMask) {
        return [MFValue valueWithObject:self.objectValue[*(long long *)index.pointer]];
    }
    switch (index.type) {
        case OCTypeObject:
            return [MFValue valueWithObject:self.objectValue[index.objectValue]];
            break;
        case OCTypeClass:
            return [MFValue valueWithObject:self.objectValue[*(Class *)index.pointer]];
            break;
        default:
            //            NSCAssert(0, @"line:%zd, index operator can not use type: %@",expr.bottomExpr.lineNumber, bottomValue.type.typeName);
            break;
    }
    return nil;
}
- (void)subscriptSetValue:(MFValue *)value index:(MFValue *)index{
    if (index.type & TypeBaseMask) {
        self.objectValue[*(long long *)index.pointer] = value.objectValue;
    }
    switch (index.type) {
        case OCTypeObject:
            self.objectValue[index.objectValue] = value.objectValue;
            break;
        case OCTypeClass:
            self.objectValue[(id <NSCopying>)*(Class *)index.pointer] = value.objectValue;
            break;
        default:
            //            NSCAssert(0, @"line:%zd, index operator can not use type: %@",expr.bottomExpr.lineNumber, bottomValue.type.typeName);
            break;
    }
}
- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    MFValue *value = [MFValue defaultValueWithTypeEncoding:self.typeEncode];
    value.pointer = self.pointer;
    value.typeName = self.typeName;
    value.modifier = self.modifier;
    value.resultType = self.resultType;
    return value;
}

@end

@implementation MFValue (Struct)
- (BOOL)isStruct{
    return isStructWithTypeEncode(self.typeEncode);
}
- (BOOL)isStructPointer{
    return isStructPointerWithTypeEncode(self.typeEncode);
}
- (BOOL)isStructValueOrPointer{
    return isStructOrStructPointerWithTypeEncode(self.typeEncode);
}
- (BOOL)isHFAStruct{
    return isHFAStructWithTypeEncode(self.typeEncode);
}
- (NSUInteger)structLayoutFieldCount{
    return totalFieldCountWithTypeEncode(self.typeEncode);
}
- (MFValue *)getResutlInPointer{
    MFValue *field = [MFValue new];
    NSUInteger pointerCount = startDetectPointerCount(self.typeEncode);
    void *fieldPointer = self.pointer;
    while (pointerCount != 0) {
        fieldPointer = *(void **)fieldPointer;
        pointerCount--;
    }
    const char *removedPointerTypeEncode = startRemovePointerOfTypeEncode(self.typeEncode).UTF8String;
    if (*removedPointerTypeEncode == '{') {
        NSString *encode = [NSString stringWithUTF8String:removedPointerTypeEncode];
        NSString *structName = startStructNameDetect(encode.UTF8String);
        ORStructDeclare *declare = [[ORStructDeclareTable shareInstance] getStructDeclareWithName:structName];
        field.typeEncode = declare.typeEncoding;
        field.typeName = structName;
    }else{
        field.typeEncode = removedPointerTypeEncode;
    }
    field.pointer = fieldPointer;
    return field;
}
- (MFValue *)fieldForKey:(NSString *)key copied:(BOOL)copied{
    NSCAssert(self.type == OCTypeStruct, @"must be struct");
    NSString *structName = self.typeName;
    ORStructDeclare *declare = [[ORStructDeclareTable shareInstance] getStructDeclareWithName:structName];
    NSUInteger offset = declare.keyOffsets[key].unsignedIntegerValue;
    MFValue *result = [MFValue defaultValueWithTypeEncoding:declare.keyTypeEncodes[key].UTF8String];
    if (copied) {
        result.pointer = self.pointer + offset;
    }else{
        [result setPointerWithNoCopy:self.pointer + offset];
    }
    return result;
}
- (MFValue *)fieldForKey:(NSString *)key{
    return [self fieldForKey:key copied:YES];
}
- (MFValue *)fieldNoCopyForKey:(NSString *)key{
    return [self fieldForKey:key copied:NO];
}
- (void)setFieldWithValue:(MFValue *)value forKey:(NSString *)key{
    NSCAssert(self.type == OCTypeStruct, @"must be struct");
    NSString *structName = self.typeName;
    ORStructDeclare *declare = [[ORStructDeclareTable shareInstance] getStructDeclareWithName:structName];
    NSUInteger offset = declare.keyOffsets[key].unsignedIntegerValue;
    void *pointer = self.pointer + offset;
    [value writePointer:pointer typeEncode:declare.keyTypeEncodes[key].UTF8String];
}
- (void)enumerateStructFieldsUsingBlock:(void (^)(MFValue *field, NSUInteger idx, BOOL *stop))block{
    NSString *structName = self.typeName;
    ORStructDeclare *declare = [[ORStructDeclareTable shareInstance] getStructDeclareWithName:structName];
    for (int i = 0 ; i < declare.keys.count; i++) {
        MFValue *field = [self fieldForKey:declare.keys[i]];
        BOOL stop = NO;
        block(field,i, &stop);
        if (stop) {
            break;
        }
    }
}
@end

@implementation MFValue (MFStatementResultType)
- (BOOL)isReturn{
    return MFStatementResultTypeIsReturn(self.resultType);
}
- (BOOL)isContinue{
    return self.resultType == MFStatementResultTypeContinue;
}
- (BOOL)isBreak{
    return self.resultType == MFStatementResultTypeBreak;
}
- (BOOL)isNormal{
    return self.resultType == MFStatementResultTypeNormal;
}
+ (instancetype)normalEnd{
    MFValue *value = [MFValue voidValue];
    value.resultType = MFStatementResultTypeNormal;
    return value;
}

@end





@implementation MFValue (ValueType)
- (unsigned char)uCharValue{
    MFValueBridge(self, unsigned char);
    return result;
}
- (unsigned short)uShortValue{
    MFValueBridge(self, unsigned short);
    return result;
}
- (unsigned int)uIntValue{
    MFValueBridge(self, unsigned int);
    return result;
}
- (unsigned long)uLongValue{
    MFValueBridge(self, unsigned long);
    return result;
}
- (unsigned long long)uLongLongValue{
    MFValueBridge(self, unsigned long long);
    return result;
}
- (char)charValue{
    MFValueBridge(self, char);
    return result;
}
- (short)shortValue{
    MFValueBridge(self, short);
    return result;
}
- (int)intValue{
    MFValueBridge(self, int);
    return result;
}
- (long)longValue{
    //NOTE: arm64下， NSGetSizeAndAlignment long 为4字节，sizeof(long)为8字节，当为负数时，会出现问题。所以将long改为int。
    MFValueBridge(self, int);
    return result;
}
- (long long)longLongValue{
    MFValueBridge(self, long long);
    return result;
}
- (BOOL)boolValue{
    MFValueBridge(self, BOOL);
    return result;
}
- (float)floatValue{
    MFValueBridge(self, float);
    return result;
}
- (double)doubleValue{
    MFValueBridge(self, double);
    return result;
}
- (id)objectValue{
    return *(__strong id *)self.pointer;
}
- (Class)classValue{
    return *(Class *)self.pointer;
}
- (SEL)selValue{
    return *(SEL *)self.pointer;
}
- (char *)cStringValue{
    return *(char **)self.pointer;
}
+ (instancetype)voidValue{
    return [MFValue valueWithTypeEncode:OCTypeStringVoid pointer:NULL];
}

+ (instancetype)valueWithBOOL:(BOOL)boolValue{
    return [MFValue valueWithTypeEncode:OCTypeStringBOOL pointer:&boolValue];
}
+ (instancetype)valueWithUChar:(unsigned char)uCharValue{
    return [MFValue valueWithTypeEncode:OCTypeStringUChar pointer:&uCharValue];
}
+ (instancetype)valueWithUShort:(unsigned short)uShortValue{
    return [MFValue valueWithTypeEncode:OCTypeStringUShort pointer:&uShortValue];
}
+ (instancetype)valueWithUInt:(unsigned int)uIntValue{
    return [MFValue valueWithTypeEncode:OCTypeStringUInt pointer:&uIntValue];
}
+ (instancetype)valueWithULong:(unsigned long)uLongValue{
    return [MFValue valueWithTypeEncode:OCTypeStringULong pointer:&uLongValue];
}
+ (instancetype)valueWithULongLong:(unsigned long long)uLongLongValue{
    return [MFValue valueWithTypeEncode:OCTypeStringULongLong pointer:&uLongLongValue];
}
+ (instancetype)valueWithChar:(char)charValue{
    return [MFValue valueWithTypeEncode:OCTypeStringChar pointer:&charValue];
}
+ (instancetype)valueWithShort:(short)shortValue{
    return [MFValue valueWithTypeEncode:OCTypeStringShort pointer:&shortValue];
}
+ (instancetype)valueWithInt:(int)intValue{
    return [MFValue valueWithTypeEncode:OCTypeStringInt pointer:&intValue];
}
+ (instancetype)valueWithLong:(long)longValue{
    return [MFValue valueWithTypeEncode:OCTypeStringLong pointer:&longValue];
}
+ (instancetype)valueWithLongLong:(long long)longLongValue{
    return [MFValue valueWithTypeEncode:OCTypeStringLongLong pointer:&longLongValue];
}
+ (instancetype)valueWithFloat:(float)floatValue{
    return [MFValue valueWithTypeEncode:OCTypeStringFloat pointer:&floatValue];
}
+ (instancetype)valueWithDouble:(double)doubleValue{
    return [MFValue valueWithTypeEncode:OCTypeStringDouble pointer:&doubleValue];
}
+ (instancetype)valueWithObject:(id)objValue{
    return [MFValue valueWithTypeEncode:OCTypeStringObject pointer:&objValue];
}
+ (instancetype)valueWithBlock:(id)blockValue{
    return [MFValue valueWithTypeEncode:OCTypeStringBlock pointer:&blockValue];
}
+ (instancetype)valueWithClass:(Class)clazzValue{
    return [MFValue valueWithTypeEncode:OCTypeStringClass pointer:&clazzValue];
}
+ (instancetype)valueWithSEL:(SEL)selValue{
    return [MFValue valueWithTypeEncode:OCTypeStringSEL pointer:&selValue];
}
+ (instancetype)valueWithCString:(char *)pointerValue{
    return [MFValue valueWithTypeEncode:OCTypeStringCString pointer:&pointerValue];
}
+ (instancetype)valueWithPointer:(void *)pointerValue{
    return [MFValue valueWithTypeEncode:OCTypeStringPointer pointer:&pointerValue];
}

@end
