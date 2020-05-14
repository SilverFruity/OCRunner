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
    UnaryExecute(BOOL, unaryResultValue0, !, self);
    return !unaryResultValue0;
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
#define MFConvertValue(value)\
_charValue = (char) value;\
_shortValue = (short) value;\
_intValue = (int) value;\
_longValue = (long) value;\
_longLongValue = (long long) value;\
_uCharValue = (unsigned char) value;\
_uShortValue = (unsigned short) value;\
_uIntValue = (unsigned int) value;\
_uLongValue = (unsigned long) value;\
_uLongLongValue = (unsigned long long) value;\
_floatValue = (float) value;\
_doubleValue = (double) value;\
_boolValue = (BOOL) value;

- (void)setUCharValue:(unsigned char)uCharValue{
    MFConvertValue(uCharValue)
}
- (void)setUShortValue:(unsigned short)uShortValue{
    MFConvertValue(uShortValue)
}
- (void)setUIntValue:(unsigned int)uIntValue{
    MFConvertValue(uIntValue)
}
- (void)setULongValue:(unsigned long)uLongValue{
    MFConvertValue(uLongValue)
}
- (void)setULongLongValue:(unsigned long long)uLongLongValue{
    MFConvertValue(uLongLongValue)
}
- (void)setCharValue:(char)charValue{
    MFConvertValue(charValue)
}
- (void)setShortValue:(short)shortValue{
    MFConvertValue(shortValue)
}
- (void)setIntValue:(int)intValue{
    MFConvertValue(intValue)
}
- (void)setLongValue:(long)longValue{
    MFConvertValue(longValue)
}
- (void)setLongLongValue:(long long)longLongValue{
    MFConvertValue(longLongValue)
}
- (void)setFloatValue:(float)floatValue{
    MFConvertValue(floatValue)
}
- (void)setDoubleValue:(double)doubleValue{
    MFConvertValue(doubleValue)
}
- (void)setBoolValue:(BOOL)boolValue{
    MFConvertValue(boolValue);
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
        return [MFValue valueInstanceWithObject:self.objectValue[index.longLongValue]];
    }
    switch (index.typePair.type.type) {
        case TypeBlock:
        case TypeObject:
            return [MFValue valueInstanceWithObject:self.objectValue[index.objectValue]];
            break;
        case TypeClass:
            return [MFValue valueInstanceWithObject:self.objectValue[index.classValue]];
            break;
        default:
//            NSCAssert(0, @"line:%zd, index operator can not use type: %@",expr.bottomExpr.lineNumber, bottomValue.type.typeName);
            break;
    }
    return nil;
}
- (void)subscriptSetValue:(MFValue *)value index:(MFValue *)index{
        if (index.typePair.type.type & TypeBaseMask) {
            self.objectValue[index.longLongValue] = value.objectValue;
        }
        switch (index.typePair.type.type) {
            case TypeBlock:
            case TypeObject:
                self.objectValue[index.objectValue] = value.objectValue;
                break;
            case TypeClass:
                self.objectValue[(id<NSCopying>)index.classValue] = value.objectValue;
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
    self.pointerValue = src.pointerValue;
}
- (id)c2objectValue{
    if (self.isPointer) {
        return (__bridge id)_pointerValue;
    }
    switch (self.typePair.type.type) {
		case TypeClass:
			return _classValue;
		case TypeObject:
		case TypeBlock:
			return self.objectValue;
		default:
			return nil;
	}

}


- (void *)c2pointerValue{
    if (self.isPointer) {
        return _pointerValue;
    }
    switch (self.typePair.type.type) {
        case TypeClass:
            return (__bridge void*)_classValue;
        case TypeObject:
        case TypeBlock:
            return (__bridge void*)self.objectValue;
        default:
            return NULL;
    }
}

//FIXME: 编码问题以及引用相关问题，指针数转换..
- (void)assignToCValuePointer:(void *)cvaluePointer typeEncoding:(const char *)typeEncoding{
	typeEncoding = removeTypeEncodingPrefix((char *)typeEncoding);
#define mf_ASSIGN_2_C_VALUE_POINTER_CASE(_encode, _type, _sel)\
case _encode:{\
_type *ptr = (_type *)cvaluePointer;\
*ptr = (_type)[self _sel];\
break;\
}
	switch (*typeEncoding) {
			mf_ASSIGN_2_C_VALUE_POINTER_CASE('c', char, charValue)
			mf_ASSIGN_2_C_VALUE_POINTER_CASE('i', int, intValue)
			mf_ASSIGN_2_C_VALUE_POINTER_CASE('s', short, shortValue)
			mf_ASSIGN_2_C_VALUE_POINTER_CASE('l', long, longValue)
			mf_ASSIGN_2_C_VALUE_POINTER_CASE('q', long long, longLongValue)
			mf_ASSIGN_2_C_VALUE_POINTER_CASE('C', unsigned char, uCharValue)
			mf_ASSIGN_2_C_VALUE_POINTER_CASE('I', unsigned int, uIntValue)
			mf_ASSIGN_2_C_VALUE_POINTER_CASE('S', unsigned short, uShortValue)
			mf_ASSIGN_2_C_VALUE_POINTER_CASE('L', unsigned long, uLongValue)
			mf_ASSIGN_2_C_VALUE_POINTER_CASE('Q', unsigned long long, uLongLongValue)
			mf_ASSIGN_2_C_VALUE_POINTER_CASE('f', float, floatValue)
			mf_ASSIGN_2_C_VALUE_POINTER_CASE('d', double, doubleValue)
			mf_ASSIGN_2_C_VALUE_POINTER_CASE('B', BOOL, boolValue)
			mf_ASSIGN_2_C_VALUE_POINTER_CASE('*', char *, c2pointerValue)
			mf_ASSIGN_2_C_VALUE_POINTER_CASE('^', void *, c2pointerValue)
			mf_ASSIGN_2_C_VALUE_POINTER_CASE(':', SEL, selValue)
		case '@':{
			void  **ptr =cvaluePointer;
			*ptr = (__bridge void *)[self c2objectValue];
			break;
		}
		case '#':{
			Class *ptr = (Class  *)cvaluePointer;
			*ptr = [self c2objectValue];
			break;
		}
		case 'v':{
			break;
		}
		default:
			NSCAssert(0, @"");
			break;
	}
}

//FIXME: 编码问题以及引用相关问题，指针数转换..
- (instancetype)initWithCValuePointer:(void *)cValuePointer typeEncoding:(const char *)typeEncoding bridgeTransfer:(BOOL)bridgeTransfer  {
	typeEncoding = removeTypeEncodingPrefix((char *)typeEncoding);
	MFValue *retValue = [[MFValue alloc] init];

#define MFGO_C_VALUE_CONVER_TO_mf_VALUE_CASE(_code,_kind, _type,_sel)\
case _code:{\
[retValue setValueType:_kind];\
retValue._sel = *(_type *)cValuePointer;\
break;\
}
    
	switch (*typeEncoding) {
			MFGO_C_VALUE_CONVER_TO_mf_VALUE_CASE('c',TypeChar, char, charValue)
			MFGO_C_VALUE_CONVER_TO_mf_VALUE_CASE('i',TypeInt, int,intValue)
			MFGO_C_VALUE_CONVER_TO_mf_VALUE_CASE('s',TypeShort, short,shortValue)
			MFGO_C_VALUE_CONVER_TO_mf_VALUE_CASE('l',TypeLong, long,longValue)
			MFGO_C_VALUE_CONVER_TO_mf_VALUE_CASE('q',TypeLongLong, long long,longLongValue)
			MFGO_C_VALUE_CONVER_TO_mf_VALUE_CASE('C',TypeUChar, unsigned char, uCharValue)
			MFGO_C_VALUE_CONVER_TO_mf_VALUE_CASE('I',TypeUInt,  unsigned int, uIntValue)
			MFGO_C_VALUE_CONVER_TO_mf_VALUE_CASE('S',TypeUShort, unsigned short, uShortValue)
			MFGO_C_VALUE_CONVER_TO_mf_VALUE_CASE('L',TypeULong,  unsigned long, uLongValue)
			MFGO_C_VALUE_CONVER_TO_mf_VALUE_CASE('Q',TypeULongLong, unsigned long long,uLongLongValue)
			MFGO_C_VALUE_CONVER_TO_mf_VALUE_CASE('B',TypeBOOL, BOOL, boolValue)
			MFGO_C_VALUE_CONVER_TO_mf_VALUE_CASE('f',TypeFloat, float, floatValue)
			MFGO_C_VALUE_CONVER_TO_mf_VALUE_CASE('d',TypeDouble, double,doubleValue)
			MFGO_C_VALUE_CONVER_TO_mf_VALUE_CASE(':',TypeSEL, SEL, selValue)
            case '^':{
                [retValue setValueType:TypeVoid];
                retValue.typePair.var.ptCount = 1;
                retValue.pointerValue = *(void* *)cValuePointer;
                break;
            }
            case '*':{
                [retValue setValueType:TypeChar];
                retValue.typePair.var.ptCount = 1;
                retValue.pointerValue = *(void* *)cValuePointer;
                break;
            }
			MFGO_C_VALUE_CONVER_TO_mf_VALUE_CASE('#',TypeClass, Class,classValue)
		case '@':{
            [retValue setValueType:TypeObject];
			if (bridgeTransfer) {
                id objectValue = (__bridge_transfer id)(*(void **)cValuePointer);
                retValue.objectValue = objectValue;
			}else{
                id objectValue = (__bridge id)(*(void **)cValuePointer);
                retValue.objectValue = objectValue;
			}

			break;
		}
		default:
			NSCAssert(0, @"not suppoert %s", typeEncoding);
			break;
	}
	return retValue;
}

//+ (instancetype)defaultValueWithTypeEncoding:(const char *)typeEncoding{
//	typeEncoding = removeTypeEncodingPrefix((char *)typeEncoding);
//	MFValue *value = [[MFValue alloc] init];
//	switch (*typeEncoding) {
//		case 'c':
//            [value setValueType:TypeChar];
//			break;
//		case 'i':
//			[value setValueType:TypeInt];
//			break;
//		case 's':
//            [value setValueType:TypeShort];
//			break;
//		case 'l':
//            [value setValueType:TypeLong];
//			break;
//		case 'q':
//			[value setValueType:TypeLongLong];
//			break;
//		case 'C':
//			[value setValueType:TypeUChar];
//			break;
//		case 'I':
//			[value setValueType:TypeUInt];
//			break;
//		case 'S':
//			[value setValueType:TypeUShort];
//			break;
//		case 'L':
//			[value setValueType:TypeULong];
//			break;
//		case 'Q':
//            [value setValueType:TypeULongLong];
//			break;
//		case 'B':
//            [value setValueType:TypeBOOL];
//			break;
//		case 'f':
//            [value setValueType:TypeFloat];
//			break;
//		case 'd':
//            [value setValueType:TypeDouble];
//			break;
//		case ':':
//            [value setValueType:TypeSEL];
//			break;
//        case '^':{
//            [value setValueType:TypeVoid];
//            value.typePair.var.ptCount += 1;
//            break;
//        }
//        case '*':{
//            [value setValueType:TypeChar];
//            value.typePair.var.ptCount = 1;
//            break;
//        }
//		case '#':
//			[value setValueType:TypeClass];
//			break;
//		case '@':
//			[value setValueType:TypeObject];
//			break;
//		case 'v':
//			[value setValueType:TypeVoid];
//			break;
//		default:
//			NSCAssert(0, @"");
//			break;
//	}
//	return value;
//}


+ (instancetype)voidValueInstance{
	MFValue *value = [[MFValue alloc] init];
//	value.type = mf_create_type_specifier(MF_TYPE_VOID);
	return value;
}

+ (instancetype)valueInstanceWithBOOL:(BOOL)boolValue{
    MFValue *value = [[MFValue alloc] init];
    [value setValueType:TypeBOOL];
    value.boolValue = boolValue;
    return value;
}
+ (instancetype)valueInstanceWithUChar:(unsigned char)uCharValue{
    MFValue *value = [[MFValue alloc] init];
    [value setValueType:TypeUChar];
    value.uCharValue = uCharValue;
    return value;
}
+ (instancetype)valueInstanceWithUShort:(unsigned short)uShortValue{
    MFValue *value = [[MFValue alloc] init];
    [value setValueType:TypeUShort];
    value.uShortValue = uShortValue;
    return value;
}
+ (instancetype)valueInstanceWithUInt:(unsigned int)uIntValue{
    MFValue *value = [[MFValue alloc] init];
    [value setValueType:TypeUInt];
    value.uIntValue = uIntValue;
    return value;
}
+ (instancetype)valueInstanceWithULong:(unsigned long)uLongValue{
    MFValue *value = [[MFValue alloc] init];
    [value setValueType:TypeUChar];
    value.uLongValue = uLongValue;
    return value;
}
+ (instancetype)valueInstanceWithULongLong:(unsigned long long)uLongLongValue{
    MFValue *value = [[MFValue alloc] init];
    [value setValueType:TypeULongLong];
    value.uLongLongValue = uLongLongValue;
    return value;
}
+ (instancetype)valueInstanceWithChar:(char)charValue{
    MFValue *value = [[MFValue alloc] init];
    [value setValueType:TypeChar];
    value.charValue = charValue;
    return value;
}
+ (instancetype)valueInstanceWithShort:(short)shortValue{
    MFValue *value = [[MFValue alloc] init];
    [value setValueType:TypeShort];
    value.shortValue = shortValue;
    return value;
}
+ (instancetype)valueInstanceWithInt:(int)intValue{
    MFValue *value = [[MFValue alloc] init];
   [value setValueType:TypeInt];
   value.intValue = intValue;
   return value;
}
+ (instancetype)valueInstanceWithLong:(long)longValue{
    MFValue *value = [[MFValue alloc] init];
   [value setValueType:TypeLong];
   value.longValue = longValue;
   return value;
}
+ (instancetype)valueInstanceWithLongLong:(long long)longLongValue{
    MFValue *value = [[MFValue alloc] init];
    [value setValueType:TypeLongLong];
    value.longLongValue = longLongValue;
    return value;
}
+ (instancetype)valueInstanceWithFloat:(float)floatValue{
    MFValue *value = [[MFValue alloc] init];
    [value setValueType:TypeFloat];
    value.floatValue = floatValue;
    return value;
}
+ (instancetype)valueInstanceWithDouble:(double)doubleValue{
	MFValue *value = [[MFValue alloc] init];
    [value setValueType:TypeDouble];
	value.doubleValue = doubleValue;
	return value;
}
+ (instancetype)valueInstanceWithObject:(id)objValue{
	MFValue *value = [[MFValue alloc] init];
    [value setValueType:TypeObject];
	value.objectValue = objValue;
	return value;
}
+ (instancetype)valueInstanceWithBlock:(id)blockValue{
	MFValue *value = [[MFValue alloc] init];
    [value setValueType:TypeBlock];
	value.objectValue = blockValue;
	return value;
}
+ (instancetype)valueInstanceWithClass:(Class)clazzValue{
	MFValue *value = [[MFValue alloc] init];
    [value setValueType:TypeClass];
	value.classValue = clazzValue;
	return value;
}
+ (instancetype)valueInstanceWithSEL:(SEL)selValue{
	MFValue *value = [[MFValue alloc] init];
    [value setValueType:TypeSEL];
	value.selValue = selValue;
	return value;
}

+ (instancetype)valueInstanceWithPointer:(void *)pointerValue{
	MFValue *value = [[MFValue alloc] init];
    [value setValueType:TypeChar];
    value.typePair.var.ptCount = 1;
	value.pointerValue = pointerValue;
	return value;
}
//- (instancetype)nsStringValue{
//	MFValue *value = [[MFValue alloc] init];
//	value.type = mf_create_type_specifier(MF_TYPE_OBJECT);
//	switch (_type.typeKind) {
//		case MF_TYPE_BOOL:
//		case MF_TYPE_U_INT:
//			value.objectValue = [NSString stringWithFormat:@"%llu",_uintValue];
//			break;
//		case MF_TYPE_INT:
//			value.objectValue = [NSString stringWithFormat:@"%lld",_integerValue];
//			break;
//		case MF_TYPE_DOUBLE:
//			value.objectValue = [NSString stringWithFormat:@"%lf",_doubleValue];
//			break;
//		case MF_TYPE_CLASS:
//		case MF_TYPE_BLOCK:
//		case MF_TYPE_OBJECT:
//			value.objectValue = [NSString stringWithFormat:@"%@",self.c2objectValue];
//			break;
//		case MF_TYPE_SEL:
//			value.objectValue = [NSString stringWithFormat:@"%@",NSStringFromSelector(_selValue)];
//			break;
//		case MF_TYPE_STRUCT:
//		case MF_TYPE_POINTER:
//			value.objectValue = [NSString stringWithFormat:@"%p",_pointerValue];
//			break;
//        case MF_TYPE_C_FUNCTION:{
//            NSMutableString *signature = [NSMutableString stringWithString:_type.returnTypeEncode];
//            for (NSString * paramEncode in _type.paramListTypeEncode) {
//                [signature appendString:paramEncode];
//            }
//            value.objectValue = [NSString stringWithFormat:@"%@-%p",signature,_pointerValue];
//            break;
//        }
//
//		case MF_TYPE_STRUCT_LITERAL:
//			value.objectValue = [NSString stringWithFormat:@"%@",self.objectValue];
//			break;
//		case MF_TYPE_C_STRING:
//			value.objectValue = [NSString stringWithFormat:@"%s",_cstringValue];
//			break;
//		default:
//			NSCAssert(0, @"");
//			break;
//	}
//	return value;
//}
//
-(void)setObjectValue:(id)objectValue{
    if (self.modifier & MFDeclarationModifierWeak) {
        _weakObj = objectValue;
    }else{
        _strongObj = objectValue;
    }
}
- (id)objectValue{
    if (self.modifier & MFDeclarationModifierWeak) {
        return _weakObj;
    }else{
        return _strongObj;
    }
}
-(void *)valuePointer{
    void *retPtr = NULL;
    if (self.isPointer) {
        retPtr = &_pointerValue;
        return retPtr;
    }
    switch (self.typePair.type.type) {
        case TypeUChar:{
            retPtr = &_uCharValue;
            break;
        }
        case TypeUInt:{
            retPtr = &_uIntValue;
            break;
        }
        case TypeUShort:{
            retPtr = &_uShortValue;
            break;
        }
        case TypeULong:{
            retPtr = &_uLongValue;
            break;
        }
        case TypeULongLong:{
            retPtr = &_uLongLongValue;
            break;
        }
        case TypeBOOL:{
            retPtr = &_boolValue;
            break;
        }
        case TypeChar:{
            retPtr = &_charValue;
            break;
        }
        case TypeShort:{
            retPtr = &_shortValue;
            break;
        }
        case TypeInt:{
            retPtr = &_intValue;
            break;
        }
        case TypeLong:{
            retPtr = &_longValue;
            break;
        }
        case TypeLongLong:{
            retPtr = &_longLongValue;
            break;
        }
        case TypeFloat:{
            retPtr = &_floatValue;
            break;
        }
        case TypeDouble:{
            retPtr = &_doubleValue;
            break;
        }
        case TypeSEL:{
            retPtr = &_selValue;
            break;
        }
        case TypeClass:{
            retPtr = &_classValue;
            break;
        }
        case TypeObject:
        case TypeBlock:
        case TypeId:{
            if (self.modifier & MFDeclarationModifierWeak) {
                retPtr = &_weakObj;
            }else{
                retPtr = &_strongObj;
            }
            break;
        }
        case TypeVoid:
            retPtr = &_pointerValue; break;
//        case TypeUnKnown:
//        case TypeEnum:
//        case TypeUnion:
//        case TypeStruct:
        default:
            break;
    }
    
    return retPtr;
}
- (void)dealloc{
    
}

@end

