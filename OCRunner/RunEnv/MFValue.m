//
//  MFValue .m
//  MangoFix
//
//  Created by jerry.yong on 2018/2/28.
//  Copyright © 2018年 yongpengliang. All rights reserved.
//

#import "MFValue.h"
#import "RunnerClasses+Execute.h"
#import "util.h"
#import <oc2mangoLib/ocHandleTypeEncode.h>
#import "MFBlock.h"
#define MFValueBridge(target, typeencode, resultType)\
resultType result;\
switch (*typeencode) {\
    case OCTypeUChar: result = (resultType)target.uCharValue; break;\
    case OCTypeUInt: result = (resultType)target.uIntValue; break;\
    case OCTypeUShort: result = (resultType)target.uShortValue; break;\
    case OCTypeULong: result = (resultType)target.uLongValue; break;\
    case OCTypeULongLong: result = (resultType)target.uLongLongValue; break;\
    case OCTypeBOOL: result = (resultType)target.boolValue; break;\
    case OCTypeChar: result = (resultType)target.charValue; break;\
    case OCTypeShort: result = (resultType)target.shortValue; break;\
    case OCTypeInt: result = (resultType)target.intValue; break;\
    case OCTypeLong: result = (resultType)target.longValue; break;\
    case OCTypeLongLong: result = (resultType)target.longlongValue; break;\
    case OCTypeFloat: result = (resultType)target.floatValue; break;\
    case OCTypeDouble: result = (resultType)target.doubleValue; break;\
    default: result = 0;\
}


@interface MFValue()
@property (nonatomic,strong)id strongObjectValue;
@property (nonatomic,weak)id weakObjectValue;
@end

@implementation MFValue

+ (instancetype)defaultValueWithTypeEncoding:(const char *)typeEncode{
    return [MFValue valueWithTypeEncode:typeEncode pointer:NULL];
}
+ (instancetype)valueWithORValue:(or_value *)value{
    return [MFValue valueWithTypeEncode:value->typeencode pointer:value->pointer];
}
+ (instancetype)valueWithTypeEncode:(const char *)typeEncode pointer:(void *)pointer{
    return [[MFValue alloc]initTypeEncode:typeEncode pointer:pointer];
}
+ (instancetype)valueWithORCaculateValue:(or_value)value{
    MFValue *result = [MFValue new];
    result.typeEncode = value.typeencode;
    result->realBaseValue = *(or_value_box *)value.pointer;
    result->_pointer = &result->realBaseValue;
    return result;
}
- (instancetype)initTypeEncode:(const char *)typeEncoding pointer:(void *)pointer{
    self = [super init];
    typeEncoding = removeTypeEncodingPrefix((char *)typeEncoding);
    _modifier = DeclarationModifierStrong;
//    _typeEncode = typeEncoding;
//    _pointer = pointer;
    [self setTypeEncode:typeEncoding];
    [self setPointer:pointer];
    return self;
}

- (void)setPointer:(void *)pointer{
    NSCAssert(_typeEncode != NULL, @"TypeEncode must exist");
    void *replace = NULL;
    if (pointer == NULL) {
        pointer = &replace;
    }
    switch (*_typeEncode) {
        case OCTypeUChar:
            realBaseValue.uCharValue = *(unsigned char *)pointer;
            _pointer = &realBaseValue.uCharValue;
            break;
        
        case OCTypeUInt:
            realBaseValue.uIntValue = *(unsigned int *)pointer;
            _pointer = &realBaseValue.uIntValue;
            break;
        
        case OCTypeUShort:
            realBaseValue.uShortValue = *(unsigned short *)pointer;
            _pointer = &realBaseValue.uShortValue;
            break;
        
        case OCTypeULong:
            realBaseValue.uLongValue = *(unsigned long *)pointer;
            _pointer = &realBaseValue.uLongValue;
            break;
        
        case OCTypeULongLong:
            realBaseValue.uLongLongValue = *(unsigned long long *)pointer;
            _pointer = &realBaseValue.uLongLongValue;
            break;
        
        case OCTypeBOOL:
            realBaseValue.boolValue = *(BOOL *)pointer;
            _pointer = &realBaseValue.boolValue;
            break;
        
        case OCTypeChar:
            realBaseValue.charValue = *(char *)pointer;
            _pointer = &realBaseValue.charValue;
            break;
        
        case OCTypeShort:
            realBaseValue.shortValue = *(short *)pointer;
            _pointer = &realBaseValue.shortValue;
            break;
        
        case OCTypeInt:
            realBaseValue.intValue = *(int *)pointer;
            _pointer = &realBaseValue.intValue;
            break;
        
        case OCTypeLong:
            realBaseValue.longValue = *(long *)pointer;
            _pointer = &realBaseValue.longValue;
            break;
        
        case OCTypeLongLong:
            realBaseValue.longlongValue = *(long long *)pointer;
            _pointer = &realBaseValue.longlongValue;
            break;
        
        case OCTypeFloat:
            realBaseValue.floatValue = *(float *)pointer;
            _pointer = &realBaseValue.floatValue;
            break;
        
        case OCTypeDouble:
            realBaseValue.doubleValue = *(double *)pointer;
            _pointer = &realBaseValue.doubleValue;
            break;
        
        case OCTypeCString:
            realBaseValue.pointerValue = *(void **)pointer;
            _pointer = &realBaseValue.pointerValue;
            break;
        
        case OCTypeObject:{
            [self setObjectPointer:pointer withModifier:_modifier];
            break;
        }
        
        case OCTypeClass:
            realBaseValue.pointerValue = *(void **)pointer;
            _pointer = &realBaseValue.pointerValue;
            break;
        
        case OCTypeSEL:
            realBaseValue.pointerValue = *(void **)pointer;
            _pointer = &realBaseValue.pointerValue;
            break;
            
        case OCTypeArray:
        {
            realBaseValue.pointerValue = pointer;
            _pointer = &realBaseValue.pointerValue;
            break;
        }
        case OCTypeUnion:
        case OCTypeStruct:
            realBaseValue.pointerValue = pointer;
            _pointer = realBaseValue.pointerValue;
            break;
        case OCTypePointer:
            realBaseValue.pointerValue = *(void **)pointer;
            _pointer = &realBaseValue.pointerValue;
            break;
        default:
            realBaseValue.uLongLongValue = 0;
            _pointer = &realBaseValue.uLongLongValue;
            break;
    }
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
- (void)setValuePointerWithNoCopy:(void *)pointer{
    realBaseValue.pointerValue = pointer;
    _pointer = pointer;
}
- (BOOL)isBlockValue{
    if (self.typeEncode == NULL) {
        return NO;
    }
    return strcmp(self.typeEncode, OCTypeStringBlock) == 0;
}
- (void)setModifier:(DeclarationModifier)modifier{
    if (_type == OCTypeObject) {
        [self setObjectPointer:_pointer withModifier:modifier];
    }
    _modifier = modifier;
}
- (void)setObjectPointer:(void **)pointer withModifier:(DeclarationModifier)modifier{
    void *object = *(void **)pointer;
    realBaseValue.pointerValue = object;
    if (modifier & DeclarationModifierWeak) {
        _weakObjectValue = (__bridge id)object;
        _strongObjectValue = nil;
        _pointer = &_weakObjectValue;
    }else{
        _strongObjectValue = (__bridge id)object;
        _weakObjectValue = nil;
        _pointer = &_strongObjectValue;
    }
}
- (void)setTypeEncode:(const char *)typeEncode{
    if (typeEncode == NULL) {
        typeEncode = OCTypeStringULongLong;
    }
    _type = *typeEncode;
    if (_typeEncode == NULL) {
        _typeEncode = typeEncode;
        return;
    }
    //基础类型转换
    if (strlen(typeEncode) == 1) {
        //类型相同时，直接跳过
        if (*typeEncode == *_typeEncode) {
            return;
        }
        void *result = NULL;
        [self convertValueWithTypeEncode:typeEncode result:&result];
        _typeEncode = typeEncode;
        if (result != NULL) {
            [self setPointer:&result];
        }
        return;
    }
    _typeEncode = typeEncode;
}
- (void)convertValueWithTypeEncode:(const char *)typeEncode result:(void **)resultValue{
    do {
        if ((TypeEncodeIsBaseType(typeEncode)) == 0) break;
        if (*_typeEncode == *typeEncode) break;
        if (_pointer == NULL) break;
        //基础类型转换
        switch (*typeEncode) {
            case OCTypeUChar:{
                
                MFValueBridge(self->realBaseValue, self->_typeEncode, unsigned char)
                memcpy(resultValue, &result, sizeof(unsigned char));
                break;
            }
            case OCTypeUInt:{
                MFValueBridge(self->realBaseValue, self->_typeEncode, unsigned int)
                memcpy(resultValue, &result, sizeof(unsigned int));
                break;
            }
            case OCTypeUShort:{
                MFValueBridge(self->realBaseValue, self->_typeEncode, unsigned short)
                memcpy(resultValue, &result, sizeof(unsigned short));
                break;
            }
            case OCTypeULong:{
                MFValueBridge(self->realBaseValue, self->_typeEncode, unsigned long)
                memcpy(resultValue, &result, sizeof(unsigned long));
                break;
            }
            case OCTypeULongLong:{
                MFValueBridge(self->realBaseValue, self->_typeEncode, unsigned long long)
                memcpy(resultValue, &result, sizeof(unsigned long long));
                break;
            }
            case OCTypeBOOL:{
                MFValueBridge(self->realBaseValue, self->_typeEncode, BOOL)
                memcpy(resultValue, &result, sizeof(BOOL));
                break;
            }
            case OCTypeChar:{
                MFValueBridge(self->realBaseValue, self->_typeEncode, char)
                memcpy(resultValue, &result, sizeof(char));
                break;
            }
            case OCTypeShort:{
                MFValueBridge(self->realBaseValue, self->_typeEncode, short)
                memcpy(resultValue, &result, sizeof(short));
                break;
            }
            case OCTypeInt:{
                MFValueBridge(self->realBaseValue, self->_typeEncode, int)
                memcpy(resultValue, &result, sizeof(int));
                break;
            }
            case OCTypeLong:{
                MFValueBridge(self->realBaseValue, self->_typeEncode, long)
                memcpy(resultValue, &result, sizeof(long));
                break;
            }
            case OCTypeLongLong:{
                MFValueBridge(self->realBaseValue, self->_typeEncode, long long)
                memcpy(resultValue, &result, sizeof(long long));
                break;
            }
            case OCTypeFloat:{
                MFValueBridge(self->realBaseValue, self->_typeEncode, float)
                memcpy(resultValue, &result, sizeof(float));
                break;
            }
            case OCTypeDouble:{
                MFValueBridge(self->realBaseValue, self->_typeEncode, double)
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


- (void)assignWithNewValue:(MFValue *)src{
    [self setTypeInfoWithValue:src];
    [self setPointer:src.pointer];
}
- (void)setDefaultValue{
    [self setPointer:NULL];
}

- (void)writePointer:(void *)pointer typeEncode:(const char *)typeEncode{
    typeEncode = typeEncode == NULL ? OCTypeStringPointer : typeEncode;
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
    UnaryExecute(result, !, or_value_create(_typeEncode, _pointer));
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
    if (_typeEncode == NULL) {
        return 0;
    }
    NSUInteger size;
    NSGetSizeAndAlignment(_typeEncode, &size, NULL);
    return size;
}
- (MFValue *)subscriptGetWithIndex:(MFValue *)index{
    if (_type != OCTypeObject && _type != OCTypeClass) {
        return [self cArraySubscriptGetValueWithIndex:index];
    }
    if (TypeEncodeCharIsBaseType(index.type)) {
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
    if (_type != OCTypeObject && _type != OCTypeClass) {
        [self cArraySubscriptSetValue:value index:index];
        return;
    }
    if (TypeEncodeCharIsBaseType(index.type)) {
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
//        ORStructDeclare *declare = [[ORTypeSymbolTable shareInstance] symbolItemForTypeName:structName].declare;
//        field.typeEncode = declare.typeEncoding;
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
//    ORStructDeclare *declare = [[ORTypeSymbolTable shareInstance] symbolItemForTypeName:structName].declare;
//    NSUInteger offset = declare.keyOffsets[key].unsignedIntegerValue;
//    MFValue *result = [MFValue defaultValueWithTypeEncoding:declare.keyTypeEncodes[key].UTF8String];
//    if (copied) {
//        result.pointer = realBaseValue.pointerValue + offset;
//    }else{
//        [result setValuePointerWithNoCopy:realBaseValue.pointerValue + offset];
//    }
//    return result;
    return nil;
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
//    ORStructDeclare *declare = [[ORTypeSymbolTable shareInstance] symbolItemForTypeName:structName].declare;
//    NSUInteger offset = declare.keyOffsets[key].unsignedIntegerValue;
//    void *pointer = realBaseValue.pointerValue;
//    if (pointer != NULL) {
//        pointer += offset;
//    }
//    [value writePointer:pointer typeEncode:declare.keyTypeEncodes[key].UTF8String];
}
- (void)enumerateStructFieldsUsingBlock:(void (^)(MFValue *field, NSUInteger idx, BOOL *stop))block{
    NSString *structName = self.typeName;
//    ORStructDeclare *declare = [[ORTypeSymbolTable shareInstance] symbolItemForTypeName:structName].declare;
//    for (int i = 0 ; i < declare.keys.count; i++) {
//        MFValue *field = [self fieldForKey:declare.keys[i]];
//        BOOL stop = NO;
//        block(field,i, &stop);
//        if (stop) {
//            break;
//        }
//    }
}
@end

@implementation MFValue (Union)

- (void)setUnionFieldWithValue:(MFValue *)value forKey:(NSString *)key{
    NSCAssert(self.type == OCTypeUnion, @"must be union");
//    ORUnionDeclare *declare = [[ORTypeSymbolTable shareInstance] symbolItemForTypeName:self.typeName].declare;
//    void *pointer = realBaseValue.pointerValue;
//    [value writePointer:pointer typeEncode:declare.keyTypeEncodes[key].UTF8String];
}

- (MFValue *)unionFieldForKey:(NSString *)key{
    NSCAssert(self.type == OCTypeUnion, @"must be union");
//    ORUnionDeclare *declare = [[ORTypeSymbolTable shareInstance] symbolItemForTypeName:self.typeName].declare;
//    MFValue *result = [MFValue defaultValueWithTypeEncoding:declare.keyTypeEncodes[key].UTF8String];
//    result.pointer = realBaseValue.pointerValue;
//    return result;
    return nil;
}
@end

@implementation MFValue  (CArray)
- (MFValue *)cArraySubscriptGetValueWithIndex:(MFValue *)index{
    const char *element_type_encode;
    if (_type == OCTypeArray) {
        NSArray *results = startArrayDetect(_typeEncode);
        element_type_encode = [results[1] UTF8String];
    }else{
        //默认操作为减少一个指针: ^i
        element_type_encode = _typeEncode + 1;
    }
    NSInteger element_mem_size = (NSInteger)sizeOfTypeEncode(element_type_encode);
    NSInteger offset = element_mem_size * (NSInteger)index.longlongValue;
    MFValue *result = [MFValue defaultValueWithTypeEncoding:element_type_encode];
    result.pointer = (char *)self->realBaseValue.pointerValue + offset;
    return result;
}
- (void)cArraySubscriptSetValue:(MFValue *)value index:(MFValue *)index{
    const char *element_type_encode;
    if (_type == OCTypeArray) {
        NSArray *results = startArrayDetect(_typeEncode);
        element_type_encode = [results[1] UTF8String];
    }else{
        //默认操作为减少一个指针
        element_type_encode = _typeEncode + 1;
    }
    NSUInteger element_mem_size = sizeOfTypeEncode(element_type_encode);
    NSInteger offset = element_mem_size * (NSInteger)index.longlongValue;
    void *pointer = (char *)self->realBaseValue.pointerValue + offset;
    [value writePointer:pointer typeEncode:element_type_encode];
}
@end

@implementation MFValue (MFStatementResultType)



@end





@implementation MFValue (ValueType)
- (unsigned char)uCharValue{
    MFValueBridge(self->realBaseValue, self->_typeEncode, unsigned char);
    return result;
}
- (unsigned short)uShortValue{
    MFValueBridge(self->realBaseValue, self->_typeEncode, unsigned short);
    return result;
}
- (unsigned int)uIntValue{
    MFValueBridge(self->realBaseValue, self->_typeEncode, unsigned int);
    return result;
}
- (unsigned long)uLongValue{
    MFValueBridge(self->realBaseValue, self->_typeEncode, unsigned long);
    return result;
}
- (unsigned long long)uLongLongValue{
    MFValueBridge(self->realBaseValue, self->_typeEncode, unsigned long long);
    return result;
}
- (char)charValue{
    MFValueBridge(self->realBaseValue, self->_typeEncode, char);
    return result;
}
- (short)shortValue{
    MFValueBridge(self->realBaseValue, self->_typeEncode, short);
    return result;
}
- (int)intValue{
    MFValueBridge(self->realBaseValue, self->_typeEncode, int);
    return result;
}
- (long)longValue{
    //NOTE: arm64下， NSGetSizeAndAlignment long 为4字节，sizeof(long)为8字节，当为负数时，会出现问题。所以将long改为int。
    MFValueBridge(self->realBaseValue, self->_typeEncode, int);
    return result;
}
- (long long)longlongValue{
    MFValueBridge(self->realBaseValue, self->_typeEncode, long long);
    return result;
}
- (BOOL)boolValue{
    MFValueBridge(self->realBaseValue, self->_typeEncode, BOOL);
    return result;
}
- (float)floatValue{
    MFValueBridge(self->realBaseValue, self->_typeEncode, float);
    return result;
}
- (double)doubleValue{
    MFValueBridge(self->realBaseValue, self->_typeEncode, double);
    return result;
}
- (id)objectValue{
    void *value = *(void **)self.pointer;
    if (value == NULL) return nil;
    return (__bridge id)value;
}
- (void *)classValue{
    return *(void **)self.pointer;
}
- (SEL)selValue{
    return *(SEL *)self.pointer;
}
- (char *)cStringValue{
    return *(char **)self.pointer;
}
+ (instancetype)nullValue{
    return [MFValue valueWithPointer:NULL];
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
+ (instancetype)valueWithUnownedObject:(id)objValue{
    MFValue *value = [MFValue valueWithTypeEncode:OCTypeStringPointer pointer:&objValue];
    value.typeEncode = OCTypeStringObject;
    return value;
}
+ (instancetype)valueWithWeakObject:(nullable id)objValue{
    MFValue *value = [MFValue defaultValueWithTypeEncoding:OCTypeStringObject];
    value.modifier = DeclarationModifierWeak;
    value.pointer = &objValue;
    return value;
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
#if DEBUG
- (NSString *)description{
    return [NSString stringWithFormat:@"[MFValue: %p, type: %d, typeName: %@, typeEncode: %s, pointerValue: %p, modifier:%d]"
            ,self,self.type,self.typeName,self.typeEncode,self->realBaseValue.pointerValue,self.modifier];
}
#endif
@end
