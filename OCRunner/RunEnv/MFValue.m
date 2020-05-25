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
extern BOOL MFStatementResultTypeIsReturn(MFStatementResultType type){
    return type & MFStatementResultTypeReturnMask;
}
@interface MFValue()

@property (assign, nonatomic) BOOL structPointNoCopyData;

@end

@implementation MFValue{
    ORTypeVarPair *_pair;
    __strong id _strongObj;
    __weak id _weakObj;
    
}
- (instancetype)init{
	if (self = [super init]) {
        _structPointNoCopyData = NO;
        self.typePair = [ORTypeVarPair new];
        self.typePair.type = [ORTypeSpecial new];
        self.typePair.var = [ORVariable new];
	}
	return self;
}
- (void)setValueType:(TypeKind)type{
    self.typePair.type.type = type;
}
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
    MFValue *value = [MFValue new];
    value.resultType = MFStatementResultTypeNormal;
    return value;
}
- (BOOL)isSubtantial{
    BOOL result = NO;
    UnaryExecute(result, !, self);
    return !result;
}


- (BOOL)isMember{
    return _pair.type.type & TypeBaseMask;
}


- (BOOL)isObject{
	switch (_pair.type.type) {
		case TypeObject:
		case TypeClass:
		case TypeBlock:
			return YES;
		default:
			return NO;
	}
}

- (BOOL)isBaseValue{
	return ![self isObject];
}
- (BOOL)isPointer{
    TypeKind type = self.typePair.type.type;
    if (((type & TypeBaseMask) || (type == TypeVoid)) && self.typePair.var.ptCount > 0) {
        return YES;
    }
    if (self.typePair.var.ptCount > 1) {\
        return YES;
    }
    return NO;
}
- (MFValue *)subscriptGetWithIndex:(MFValue *)index{
    if (index.typePair.type.type & TypeBaseMask) {
        return [MFValue valueInstanceWithObject:self.objectValue[*(long long *)index.pointer]];
    }
    switch (index.typePair.type.type) {
        case TypeBlock:
        case TypeObject:
            return [MFValue valueInstanceWithObject:self.objectValue[*(__strong id *)index.pointer]];
            break;
        case TypeClass:
            return [MFValue valueInstanceWithObject:self.objectValue[*(Class *)index.pointer]];
            break;
        default:
//            NSCAssert(0, @"line:%zd, index operator can not use type: %@",expr.bottomExpr.lineNumber, bottomValue.type.typeName);
            break;
    }
    return nil;
}
- (void)subscriptSetValue:(MFValue *)value index:(MFValue *)index{
        if (index.typePair.type.type & TypeBaseMask) {
            self.objectValue[*(long long *)index.pointer] = value.objectValue;
        }
        switch (index.typePair.type.type) {
            case TypeBlock:
            case TypeObject:
                self.objectValue[*(__strong id *)index.pointer] = value.objectValue;
                break;
            case TypeClass:
                self.objectValue[(id <NSCopying>)*(Class *)index.pointer] = value.objectValue;
                break;
            default:
    //            NSCAssert(0, @"line:%zd, index operator can not use type: %@",expr.bottomExpr.lineNumber, bottomValue.type.typeName);
                break;
        }
}
- (void)assignFrom:(MFValue *)src{
	if (_pair.type.type == TypeUnKnown) {
		_pair = src->_pair;
	}
    self.pointer = src.pointer;
}

//FIXME: 编码问题以及引用相关问题，指针数转换..
- (void)writePointer:(void *)pointer typeEncode:(const char *)typeEncode{
    NSUInteger size;
    NSGetSizeAndAlignment(typeEncode, &size, NULL);
    memcpy(pointer, self.pointer, size);
}

+ (instancetype)voidValueInstance{
	MFValue *value = [[MFValue alloc] init];
//	value.type = mf_create_type_specifier(MF_TYPE_VOID);
	return value;
}

+ (instancetype)valueInstanceWithBOOL:(BOOL)boolValue{
    return [[MFValue alloc] initTypeKind:TypeChar pointer:&boolValue];
}
+ (instancetype)valueInstanceWithUChar:(unsigned char)uCharValue{
    return [[MFValue alloc] initTypeKind:TypeUChar pointer:&uCharValue];
}
+ (instancetype)valueInstanceWithUShort:(unsigned short)uShortValue{
    return [[MFValue alloc] initTypeKind:TypeUShort pointer:&uShortValue];
}
+ (instancetype)valueInstanceWithUInt:(unsigned int)uIntValue{
    return [[MFValue alloc] initTypeKind:TypeUInt pointer:&uIntValue];
}
+ (instancetype)valueInstanceWithULong:(unsigned long)uLongValue{
    return [[MFValue alloc] initTypeKind:TypeULong pointer:&uLongValue];
}
+ (instancetype)valueInstanceWithULongLong:(unsigned long long)uLongLongValue{
    return [[MFValue alloc] initTypeKind:TypeULongLong pointer:&uLongLongValue];
}
+ (instancetype)valueInstanceWithChar:(char)charValue{
    return [[MFValue alloc] initTypeKind:TypeChar pointer:&charValue];
}
+ (instancetype)valueInstanceWithShort:(short)shortValue{
    return [[MFValue alloc] initTypeKind:TypeShort pointer:&shortValue];
}
+ (instancetype)valueInstanceWithInt:(int)intValue{
    return [[MFValue alloc] initTypeKind:TypeInt pointer:&intValue];
}
+ (instancetype)valueInstanceWithLong:(long)longValue{
    return [[MFValue alloc] initTypeKind:TypeLong pointer:&longValue];
}
+ (instancetype)valueInstanceWithLongLong:(long long)longLongValue{
    return [[MFValue alloc] initTypeKind:TypeLongLong pointer:&longLongValue];
}
+ (instancetype)valueInstanceWithFloat:(float)floatValue{
    return [[MFValue alloc] initTypeKind:TypeFloat pointer:&floatValue];
}
+ (instancetype)valueInstanceWithDouble:(double)doubleValue{
	return [[MFValue alloc] initTypeKind:TypeDouble pointer:&doubleValue];
}
+ (instancetype)valueInstanceWithObject:(id)objValue{
	return [[MFValue alloc] initTypeKind:TypeObject pointer:&objValue];
}
+ (instancetype)valueInstanceWithBlock:(id)blockValue{
	return [[MFValue alloc] initTypeKind:TypeBlock pointer:&blockValue];
}
+ (instancetype)valueInstanceWithClass:(Class)clazzValue{
	return [[MFValue alloc] initTypeKind:TypeSEL pointer:&clazzValue];
}
+ (instancetype)valueInstanceWithSEL:(SEL)selValue{
	return [[MFValue alloc] initTypeKind:TypeSEL pointer:&selValue];
}

+ (instancetype)valueInstanceWithPointer:(void *)pointerValue{
	return [[MFValue alloc] initTypeKind:TypeObject pointer:pointerValue];
}

+ (instancetype)defaultValueWithTypeEncoding:(const char *)typeEncoding{
    typeEncoding = removeTypeEncodingPrefix((char *)typeEncoding);
    MFValue *value = [[MFValue alloc] initTypeEncode:typeEncoding pointer:NULL];
    *(NSUInteger *)value.pointer = 0;
    return value;
}

-(void)setObjectValue:(id)objectValue{
    if (self.modifier & ORDeclarationModifierWeak) {
        _weakObj = objectValue;
    }else{
        _strongObj = objectValue;
    }
}
- (id)objectValue{
    if (self.modifier & ORDeclarationModifierWeak) {
        return _weakObj;
    }else{
        return _strongObj;
    }
}
- (void)dealloc{
    
}

@end

@implementation MFValue (Struct)
- (ORStructField *)fieldForKey:(NSString *)key{
    NSCAssert(self.typePair.type.type == TypeStruct, @"must be struct");
    NSString *structName = self.typePair.type.name;
    ORStructDeclare *declare = [[ORStructDeclareTable shareInstance] getStructDeclareWithName:structName];
    ORStructField *field = [ORStructField new];
    NSUInteger offset = declare.keyOffsets[key].unsignedIntegerValue;
    field.fieldPointer = self.pointer + offset;
    field.fieldTypeEncode = declare.keyTypeEncodes[key];
    return field;
}
@end

@implementation ORStructField
- (BOOL)isStruct{
    NSString *ignorePointer = [self.fieldTypeEncode stringByReplacingOccurrencesOfString:@"^" withString:@""];
    return *ignorePointer.UTF8String == '{';
}
- (BOOL)isStructPointer{
    return [self isStruct] && (*self.fieldTypeEncode.UTF8String == '^');
}
- (MFValue *)value{
    return [[MFValue alloc] initTypeEncode:self.fieldTypeEncode.UTF8String pointer:self.fieldPointer];
}
- (ORStructField *)fieldForKey:(NSString *)key{
    NSCAssert([self isStruct], @"must be struct");
    return [self.value fieldForKey:key];
}
- (ORStructField *)getPointerValueField{
    ORStructField *field = [ORStructField new];
    NSUInteger pointerCount = startDetectPointerCount(self.fieldTypeEncode.UTF8String);
    void *fieldPointer = self.fieldPointer;
    while (pointerCount != 0) {
        fieldPointer = *(void **)fieldPointer;
        pointerCount--;
    }
    field.fieldPointer = fieldPointer;
    field.fieldTypeEncode = startRemovePointerOfTypeEncode(self.fieldTypeEncode.UTF8String);
    if (*field.fieldTypeEncode.UTF8String == '{') {
        NSString *structName = [field.fieldTypeEncode substringWithRange:NSMakeRange(1, field.fieldTypeEncode.length - 2)];
        ORStructDeclare *declare = [[ORStructDeclareTable shareInstance] getStructDeclareWithName:structName];
        field.fieldTypeEncode = [NSString stringWithUTF8String:declare.typeEncoding];
    }
    return field;
}
@end
