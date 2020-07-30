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
#import "ORTypeVarPair+TypeEncode.h"
#import "ORHandleTypeEncode.h"

#define MFValueBridge(target,resultType)\
resultType result;\
const char *typeEncode = target.typeEncode;\
switch (*typeEncode) {\
    case OCTypeEncodeUChar: result = (resultType)*(unsigned char *)target.pointer; break;\
    case OCTypeEncodeUInt: result = (resultType)*(unsigned int *)target.pointer; break;\
    case OCTypeEncodeUShort: result = (resultType)*(unsigned short *)target.pointer; break;\
    case OCTypeEncodeULong: result = (resultType)*(unsigned int *)target.pointer; break;\
    case OCTypeEncodeULongLong: result = (resultType)*(unsigned long long *)target.pointer; break;\
    case OCTypeEncodeBOOL: result = (resultType)*(BOOL *)target.pointer; break;\
    case OCTypeEncodeChar: result = (resultType)*(char *)target.pointer; break;\
    case OCTypeEncodeShort: result = (resultType)*(short *)target.pointer; break;\
    case OCTypeEncodeInt: result = (resultType)*(int *)target.pointer; break;\
    case OCTypeEncodeLong: result = (resultType)*(int *)target.pointer; break;\
    case OCTypeEncodeLongLong: result = (resultType)*(long long *)target.pointer; break;\
    case OCTypeEncodeFloat: result = (resultType)*(float *)target.pointer; break;\
    case OCTypeEncodeDouble: result = (resultType)*(double *)target.pointer; break;\
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
- (void)setPointerWithNoCopy:(void *)pointer{
    [self deallocPointer];
    _pointer = pointer;
    _isAlloced = NO;
}
- (void)setModifier:(ORDeclarationModifier)modifier{
    if (modifier & ORDeclarationModifierWeak && (self.type == TypeObject || self.type == TypeBlock)) {
        self.weakObjectValue = self.strongObjectValue;
        self.strongObjectValue = nil;
    }
    _modifier = modifier;
}
- (void)dealloc{
    [self deallocPointer];
    if(_typeEncode != NULL) free((void *)_typeEncode);
}
- (void)setTypeEncode:(const char *)typeEncode{
#define copyTypeEncode(encode) if(_typeEncode != NULL) free((void *)_typeEncode);\
size_t strLen = strlen(encode);\
char *buffer = malloc(strLen+1);\
buffer[strLen] = '\0';\
strncpy((void *)buffer, encode, strLen);\
_typeEncode = buffer;
    if (strcmp(typeEncode, OCTypeEncodeBlock) == 0) {
        copyTypeEncode(typeEncode)
        self.type = TypeBlock;
        return;
    }
    if (self.type == TypeBlock) {
        return;
    }
    ORTypeVarPair *pair = ORTypeVarPairForTypeEncode(typeEncode);
    TypeKind type = pair.type.type;
    NSString *typeName = pair.type.name;
    NSUInteger pointerCount = pair.var.ptCount;
    void *result = NULL;
    [self convertValueWithTypeEncode:typeEncode result:&result];
    copyTypeEncode(typeEncode)
    if (result != NULL) {
        self.pointer = &result;
    }
    self.type = type;
    self.pointerCount = pointerCount;
    if (typeName != nil) {
        self.typeName = typeName;
    }
}
- (void)convertValueWithTypeEncode:(const char *)typeEncode result:(void **)resultValue{
    ORTypeVarPair *pair = ORTypeVarPairForTypeEncode(typeEncode);
    TypeKind type = pair.type.type;
    NSUInteger pointerCount = pair.var.ptCount;
    do {
        if ((self.type & TypeBaseMask) == 0) break;
        if (self.type == type) break;
        if (pointerCount != 0) break;
        if (self.pointer == NULL) break;
        //基础类型转换
        switch (*typeEncode) {
            case OCTypeEncodeUChar:{
                MFValueBridge(self, unsigned char)
                memcpy(resultValue, &result, sizeof(unsigned char));
                break;
            }
            case OCTypeEncodeUInt:{
                MFValueBridge(self, unsigned int)
                memcpy(resultValue, &result, sizeof(unsigned int));
                break;
            }
            case OCTypeEncodeUShort:{
                MFValueBridge(self, unsigned short)
                memcpy(resultValue, &result, sizeof(unsigned short));
                break;
            }
            case OCTypeEncodeULong:{
                MFValueBridge(self, unsigned long)
                memcpy(resultValue, &result, sizeof(unsigned long));
                break;
            }
            case OCTypeEncodeULongLong:{
                MFValueBridge(self, unsigned long long)
                memcpy(resultValue, &result, sizeof(unsigned long long));
                break;
            }
            case OCTypeEncodeBOOL:{
                MFValueBridge(self, BOOL)
                memcpy(resultValue, &result, sizeof(BOOL));
                break;
            }
            case OCTypeEncodeChar:{
                MFValueBridge(self, char)
                memcpy(resultValue, &result, sizeof(char));
                break;
            }
            case OCTypeEncodeShort:{
                MFValueBridge(self, short)
                memcpy(resultValue, &result, sizeof(short));
                break;
            }
            case OCTypeEncodeInt:{
                MFValueBridge(self, int)
                memcpy(resultValue, &result, sizeof(int));
                break;
            }
            case OCTypeEncodeLong:{
                MFValueBridge(self, long)
                memcpy(resultValue, &result, sizeof(long));
                break;
            }
            case OCTypeEncodeLongLong:{
                MFValueBridge(self, long long)
                memcpy(resultValue, &result, sizeof(long long));
                break;
            }
            case OCTypeEncodeFloat:{
                MFValueBridge(self, float)
                memcpy(resultValue, &result, sizeof(float));
                break;
            }
            case OCTypeEncodeDouble:{
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
- (void)setTypeInfoWithTypePair:(ORTypeVarPair *)typePair{
    self.typeName = typePair.type.name;
    self.typeEncode = typePair.typeEncode;
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
         ORTypeVarPair *pair = [[ORTypeSymbolTable shareInstance] typePairForTypeName:self.typeName];
         if (!pair) break;
         if (pair.type.type == TypeStruct) {
             ORStructDeclare *structDecl = [[ORStructDeclareTable shareInstance] getStructDeclareWithName:pair.type.name];
             if (!structDecl) break;
             self.typeEncode = structDecl.typeEncoding;
         }else{
             [self setTypeInfoWithTypePair:pair];
         }
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
        case TypeBlock:
        case TypeObject:
            return [MFValue valueWithObject:self.objectValue[index.objectValue]];
            break;
        case TypeClass:
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
        case TypeBlock:
        case TypeObject:
            self.objectValue[index.objectValue] = value.objectValue;
            break;
        case TypeClass:
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
        field.type = TypeStruct;
        field.typeName = structName;
    }else{
        field.typeEncode = removedPointerTypeEncode;
    }
    field.pointer = fieldPointer;
    return field;
}
- (MFValue *)fieldForKey:(NSString *)key copied:(BOOL)copied{
    NSCAssert(self.type == TypeStruct, @"must be struct");
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
    NSCAssert(self.type == TypeStruct, @"must be struct");
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
    return [MFValue valueWithTypeEncode:OCTypeEncodeStringVoid pointer:NULL];
}

+ (instancetype)valueWithBOOL:(BOOL)boolValue{
    return [MFValue valueWithTypeEncode:OCTypeEncodeStringBOOL pointer:&boolValue];
}
+ (instancetype)valueWithUChar:(unsigned char)uCharValue{
    return [MFValue valueWithTypeEncode:OCTypeEncodeStringUChar pointer:&uCharValue];
}
+ (instancetype)valueWithUShort:(unsigned short)uShortValue{
    return [MFValue valueWithTypeEncode:OCTypeEncodeStringUShort pointer:&uShortValue];
}
+ (instancetype)valueWithUInt:(unsigned int)uIntValue{
    return [MFValue valueWithTypeEncode:OCTypeEncodeStringUInt pointer:&uIntValue];
}
+ (instancetype)valueWithULong:(unsigned long)uLongValue{
    return [MFValue valueWithTypeEncode:OCTypeEncodeStringULong pointer:&uLongValue];
}
+ (instancetype)valueWithULongLong:(unsigned long long)uLongLongValue{
    return [MFValue valueWithTypeEncode:OCTypeEncodeStringULongLong pointer:&uLongLongValue];
}
+ (instancetype)valueWithChar:(char)charValue{
    return [MFValue valueWithTypeEncode:OCTypeEncodeStringChar pointer:&charValue];
}
+ (instancetype)valueWithShort:(short)shortValue{
    return [MFValue valueWithTypeEncode:OCTypeEncodeStringShort pointer:&shortValue];
}
+ (instancetype)valueWithInt:(int)intValue{
    return [MFValue valueWithTypeEncode:OCTypeEncodeStringInt pointer:&intValue];
}
+ (instancetype)valueWithLong:(long)longValue{
    return [MFValue valueWithTypeEncode:OCTypeEncodeStringLong pointer:&longValue];
}
+ (instancetype)valueWithLongLong:(long long)longLongValue{
    return [MFValue valueWithTypeEncode:OCTypeEncodeStringLongLong pointer:&longLongValue];
}
+ (instancetype)valueWithFloat:(float)floatValue{
    return [MFValue valueWithTypeEncode:OCTypeEncodeStringFloat pointer:&floatValue];
}
+ (instancetype)valueWithDouble:(double)doubleValue{
    return [MFValue valueWithTypeEncode:OCTypeEncodeStringDouble pointer:&doubleValue];
}
+ (instancetype)valueWithObject:(id)objValue{
    return [MFValue valueWithTypeEncode:OCTypeEncodeStringObject pointer:&objValue];
}
+ (instancetype)valueWithBlock:(id)blockValue{
    return [MFValue valueWithTypeEncode:OCTypeEncodeBlock pointer:&blockValue];
}
+ (instancetype)valueWithClass:(Class)clazzValue{
    return [MFValue valueWithTypeEncode:OCTypeEncodeStringClass pointer:&clazzValue];
}
+ (instancetype)valueWithSEL:(SEL)selValue{
    return [MFValue valueWithTypeEncode:OCTypeEncodeStringSEL pointer:&selValue];
}
+ (instancetype)valueWithCString:(char *)pointerValue{
    return [MFValue valueWithTypeEncode:OCTypeEncodeStringCString pointer:&pointerValue];
}
+ (instancetype)valueWithPointer:(void *)pointerValue{
    return [MFValue valueWithTypeEncode:OCTypeEncodeStringPointer pointer:&pointerValue];
}

@end
