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
#define MFValueBridge(target,resultType)\
resultType result;\
switch (target.type) {\
    case TypeUChar: result = (resultType)*(unsigned char *)target.pointer; break;\
    case TypeUInt: result = (resultType)*(unsigned int *)target.pointer; break;\
    case TypeUShort: result = (resultType)*(unsigned short *)target.pointer; break;\
    case TypeULong: result = (resultType)*(unsigned long *)target.pointer; break;\
    case TypeULongLong: result = (resultType)*(unsigned long long *)target.pointer; break;\
    case TypeBOOL: result = (resultType)*(BOOL *)target.pointer; break;\
    case TypeChar: result = (resultType)*(char *)target.pointer; break;\
    case TypeShort: result = (resultType)*(short *)target.pointer; break;\
    case TypeInt: result = (resultType)*(int *)target.pointer; break;\
    case TypeLong: result = (resultType)*(int *)target.pointer; break;\
    case TypeLongLong: result = (resultType)*(long long *)target.pointer; break;\
    case TypeFloat: result = (resultType)*(float *)target.pointer; break;\
    case TypeDouble: result = (resultType)*(double *)target.pointer; break;\
    default: result = 0;\
}

extern BOOL MFStatementResultTypeIsReturn(MFStatementResultType type){
    return type & MFStatementResultTypeReturnMask;
}
@interface MFValue()
@property (nonatomic,strong)id objectValue;
@property (nonatomic,weak)id weakObjectValue;
@end

@implementation MFValue
{
    BOOL _isAlloced;
}
+ (instancetype)defaultValueWithTypeEncoding:(const char *)typeEncoding{
    typeEncoding = removeTypeEncodingPrefix((char *)typeEncoding);
    MFValue *value = [[MFValue alloc] initTypeEncode:typeEncoding pointer:NULL];
    NSUInteger a = 0;
    value.pointer = &a;
    return value;
}
+ (instancetype)valueWithTypeKind:(TypeKind)TypeKind pointer:(void *)pointer{
    return [MFValue valueWithTypePair:[ORTypeVarPair typePairWithTypeKind:TypeKind] pointer:pointer];
}
+ (instancetype)valueWithTypePair:(ORTypeVarPair *)typePair pointer:(void *)pointer{
    return [[[self class] alloc] initTypeEncode:typePair.typeEncode pointer:pointer];
}
- (instancetype)initTypeEncode:(const char *)typeEncoding{
    self = [super init];
    self.typeEncode = typeEncoding;
    self.pointer = NULL;
    return self;
}
- (instancetype)initTypeEncode:(const char *)typeEncoding pointer:(void *)pointer{
    self = [super init];
    self.typeEncode = typeEncoding;
    self.pointer = pointer;
    return self;
}
- (void)deallocPointer{
    if (_pointer != NULL && _isAlloced) {
        free(_pointer);
        _objectValue = nil;
        _weakObjectValue = nil;
    }
}
- (void)setPointer:(void *)pointer{
    NSCAssert(self.typeEncode != NULL, @"TypeEncode must exist");
    if (pointer == NULL) {
        _pointer = pointer;
        return;
    }
    [self deallocPointer];
    if (*self.typeEncode == '@') {
        _objectValue = *(__strong id *)pointer;
    }
    NSUInteger size;
    NSGetSizeAndAlignment(self.typeEncode, &size, NULL);
    void *dst = malloc(size);
    memset(dst, 0, size);
    memcpy(dst, pointer, size);
    _pointer = dst;
    _isAlloced = YES;
}
- (void)setPointerWithNoCopy:(void *)pointer{;
    [self deallocPointer];
    _pointer = pointer;
    _isAlloced = NO;
}
- (void)setModifier:(ORDeclarationModifier)modifier{
    if (modifier & ORDeclarationModifierWeak && (self.type == TypeObject || self.type == TypeBlock)) {
        self.weakObjectValue = self.objectValue;
        self.objectValue = nil;
    }
    _modifier = modifier;
}
- (id)objectValue{
    return *(__strong id *)self.pointer;
}

- (void)dealloc{
    [self deallocPointer];
}
- (void)setTypeEncode:(const char *)typeEncode{
    if (strcmp(typeEncode, "@?") == 0) {
        _typeEncode = typeEncode;
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
    [self convertValueWithTypeEncode:&result typeEncode:typeEncode];
    _typeEncode = typeEncode;
    if (result != NULL) {
        self.pointer = &result;
    }
    self.type = type;
    self.pointerCount = pointerCount;
    if (typeName != nil) {
        self.typeName = typeName;
    }
}
- (void)convertValueWithTypeEncode:(void **)resultValue typeEncode:(const char *)typeEncode{
    ORTypeVarPair *pair = ORTypeVarPairForTypeEncode(typeEncode);
    TypeKind type = pair.type.type;
    NSUInteger pointerCount = pair.var.ptCount;
    do {
        if ((self.type & TypeBaseMask) == 0) break;
        if (self.type == type) break;
        if (pointerCount != 0) break;
        if (self.pointer == NULL) break;
        //基础类型转换
        switch (type) {
            case TypeUChar:{
                MFValueBridge(self, unsigned char)
                memcpy(resultValue, &result, sizeof(unsigned char));
                break;
            }
            case TypeUInt:{
                MFValueBridge(self, unsigned int)
                memcpy(resultValue, &result, sizeof(unsigned int));
                break;
            }
            case TypeUShort:{
                MFValueBridge(self, unsigned short)
                memcpy(resultValue, &result, sizeof(unsigned short));
                break;
            }
            case TypeULong:{
                MFValueBridge(self, unsigned long)
                memcpy(resultValue, &result, sizeof(unsigned long));
                break;
            }
            case TypeULongLong:{
                MFValueBridge(self, unsigned long long)
                memcpy(resultValue, &result, sizeof(unsigned long long));
                break;
            }
            case TypeBOOL:{
                MFValueBridge(self, BOOL)
                memcpy(resultValue, &result, sizeof(BOOL));
                break;
            }
            case TypeChar:{
                MFValueBridge(self, char)
                memcpy(resultValue, &result, sizeof(char));
                break;
            }
            case TypeShort:{
                MFValueBridge(self, short)
                memcpy(resultValue, &result, sizeof(short));
                break;
            }
            case TypeInt:{
                MFValueBridge(self, int)
                memcpy(resultValue, &result, sizeof(int));
                break;
            }
            case TypeLong:{
                MFValueBridge(self, long)
                memcpy(resultValue, &result, sizeof(long));
                break;
            }
            case TypeLongLong:{
                MFValueBridge(self, long long)
                memcpy(resultValue, &result, sizeof(long long));
                break;
            }
            case TypeFloat:{
                MFValueBridge(self, float)
                memcpy(resultValue, &result, sizeof(float));
                break;
            }
            case TypeDouble:{
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

- (void)setTypeBySearchInTypeSymbolTable{
    do {
         if (!self.typeName) break;
         ORTypeVarPair *pair = [[ORTypeSymbolTable shareInstance] typePairForTypeName:self.typeName];
         if (!pair) break;
         if (pair.type.type == TypeStruct) {
             ORStructDeclare *structDecl = [[ORStructDeclareTable shareInstance] getStructDeclareWithName:pair.type.name];
             if (!structDecl) break;
             self.typeEncode = structDecl.typeEncoding;
             NSLog(@"%s",structDecl.typeEncoding);
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
    [self convertValueWithTypeEncode:&convertResult typeEncode:typeEncode];
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
- (BOOL)isMember{
    return self.type & TypeBaseMask;
}
- (BOOL)isInteger{
    if (self.isPointer) {
        return NO;
    }
    return self.type <= TypeLongLong && self.type !=  TypeVoid;
}
- (BOOL)isFloat{
    if (self.isPointer) {
        return NO;
    }
    return self.type == TypeFloat || self.type == TypeDouble;
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
   return *self.typeEncode == '{';
}
- (BOOL)isStructPointer{
    return [self isStructValueOrPointer] && (*self.typeEncode == '^');
}
- (BOOL)isStructValueOrPointer{
    NSString *encode = [NSString stringWithUTF8String:self.typeEncode];
    NSString *ignorePointer = [encode stringByReplacingOccurrencesOfString:@"^" withString:@""];
    return *ignorePointer.UTF8String == '{';
}
- (BOOL)isHFAStruct{
    if (!self.isStruct) {
        return NO;
    }
    NSString *typeencode = detectStructMemeryLayoutEncodeCode(self.typeEncode);
    return isHomogeneousFloatingPointAggregate(typeencode.UTF8String);
}
- (NSUInteger)structLayoutFieldCount{
    NSString *typeencode = detectStructMemeryLayoutEncodeCode(self.typeEncode);
    return fieldCountInStructMemeryLayoutEncode(typeencode.UTF8String);
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
        NSString *structName = [encode substringWithRange:NSMakeRange(1, strlen(removedPointerTypeEncode) - 2)];
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
- (MFValue *)fieldForKey:(NSString *)key{
    NSCAssert(self.type == TypeStruct, @"must be struct");
    NSString *structName = self.typeName;
    ORStructDeclare *declare = [[ORStructDeclareTable shareInstance] getStructDeclareWithName:structName];
    NSUInteger offset = declare.keyOffsets[key].unsignedIntegerValue;
    MFValue *result = [[MFValue alloc] initTypeEncode:declare.keyTypeEncodes[key].UTF8String];
    // no copy
//    [result setPointerWithNoCopy:self.pointer + offset];
    result.pointer = self.pointer + offset;
    return result;
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
+ (instancetype)voidValue{
    return [MFValue valueWithTypeKind:TypeVoid pointer:NULL];;
}

+ (instancetype)valueWithBOOL:(BOOL)boolValue{
    return [MFValue valueWithTypeKind:TypeBOOL pointer:&boolValue];
}
+ (instancetype)valueWithUChar:(unsigned char)uCharValue{
    return [MFValue valueWithTypeKind:TypeUChar pointer:&uCharValue];
}
+ (instancetype)valueWithUShort:(unsigned short)uShortValue{
    return [MFValue valueWithTypeKind:TypeUShort pointer:&uShortValue];
}
+ (instancetype)valueWithUInt:(unsigned int)uIntValue{
    return [MFValue valueWithTypeKind:TypeUInt pointer:&uIntValue];
}
+ (instancetype)valueWithULong:(unsigned long)uLongValue{
    return [MFValue valueWithTypeKind:TypeULong pointer:&uLongValue];
}
+ (instancetype)valueWithULongLong:(unsigned long long)uLongLongValue{
    return [MFValue valueWithTypeKind:TypeULongLong pointer:&uLongLongValue];
}
+ (instancetype)valueWithChar:(char)charValue{
    return [MFValue valueWithTypeKind:TypeChar pointer:&charValue];
}
+ (instancetype)valueWithShort:(short)shortValue{
    return [MFValue valueWithTypeKind:TypeShort pointer:&shortValue];
}
+ (instancetype)valueWithInt:(int)intValue{
    return [MFValue valueWithTypeKind:TypeInt pointer:&intValue];
}
+ (instancetype)valueWithLong:(long)longValue{
    return [MFValue valueWithTypeKind:TypeLong pointer:&longValue];
}
+ (instancetype)valueWithLongLong:(long long)longLongValue{
    return [MFValue valueWithTypeKind:TypeLongLong pointer:&longLongValue];
}
+ (instancetype)valueWithFloat:(float)floatValue{
    return [MFValue valueWithTypeKind:TypeFloat pointer:&floatValue];
}
+ (instancetype)valueWithDouble:(double)doubleValue{
    return [MFValue valueWithTypeKind:TypeDouble pointer:&doubleValue];
}
+ (instancetype)valueWithObject:(id)objValue{
    return [MFValue valueWithTypeKind:TypeObject pointer:&objValue];
}
+ (instancetype)valueWithBlock:(id)blockValue{
    return [MFValue valueWithTypeKind:TypeBlock pointer:&blockValue];
}
+ (instancetype)valueWithClass:(Class)clazzValue{
    return [MFValue valueWithTypeKind:TypeSEL pointer:&clazzValue];
}
+ (instancetype)valueWithSEL:(SEL)selValue{
    return [MFValue valueWithTypeKind:TypeSEL pointer:&selValue];
}
+ (instancetype)valueWithCString:(char *)pointerValue{
    return [[MFValue alloc] initTypeEncode:"*" pointer:&pointerValue];
}
+ (instancetype)valueWithPointer:(void *)pointerValue{
    return [[MFValue alloc] initTypeEncode:"^" pointer:&pointerValue];
}

@end
