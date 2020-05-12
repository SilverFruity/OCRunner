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
    ValueDefineWithMFValue(0, self);
    UnaryExecute(BOOL, !, 0, self);
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


- (BOOL)isBaseValue{
	return ![self isObject];
}
- (BOOL)isPointer{
    if ((self.typePair.type.type & TypeBaseMask) && self.typePair.var.ptCount > 0) {
        return YES;
    }
    if (self.typePair.var.ptCount > 1) {\
        return YES;
    }
    return NO;
}
- (id)subscriptGetWithIndex:(MFValue *)index{
    ValueDefineWithMFValue(Self, self);
    ValueDefineWithMFValue(Index, index);
    if (index.typePair.type.type & TypeBaseMask) {
        HoleIntegerValue(Index, index);
        return (id)objectValueSelf[holeValue_int64_tIndex];
    }
    switch (index.typePair.type.type) {
        case TypeBlock:
        case TypeObject:
            return objectValueSelf[objectValueIndex];
            break;
        case TypeClass:
            return objectValueSelf[classValueIndex];
            break;
        default:
//            NSCAssert(0, @"line:%zd, index operator can not use type: %@",expr.bottomExpr.lineNumber, bottomValue.type.typeName);
            break;
    }
    return nil;
}
- (void)subscriptSetWithIndex:(MFValue *)index value:(MFValue *)value{
    
}

- (void)assignFrom:(MFValue *)src{
	if (_pair.type.type == TypeUnKnown) {
		_pair = src->_pair;
	}
    self.pointerValue = src.pointerValue;
}


//- (uint64_t)c2uintValue{
//	switch (_type.typeKind) {
//		case MF_TYPE_BOOL:
//			return _uintValue;
//		case MF_TYPE_INT:
//			return _integerValue;
//		case MF_TYPE_U_INT:
//			return _uintValue;
//		case MF_TYPE_DOUBLE:
//			return _doubleValue;
//		default:
//			return 0;
//	}
//}
//
//
//- (int64_t)c2integerValue{
//	switch (_type.typeKind) {
//		case MF_TYPE_BOOL:
//			return _uintValue;
//		case MF_TYPE_INT:
//			return _integerValue;
//		case MF_TYPE_U_INT:
//			return _uintValue;
//		case MF_TYPE_DOUBLE:
//			return _doubleValue;
//		default:
//			return 0;
//	}
//}
//
//
//- (double)c2doubleValue{
//	switch (_type.typeKind) {
//		case MF_TYPE_BOOL:
//			return _uintValue;
//		case MF_TYPE_INT:
//			return _integerValue;
//		case MF_TYPE_U_INT:
//			return _uintValue;
//		case MF_TYPE_DOUBLE:
//			return _doubleValue;
//		default:
//			return 0.0;
//	}
//}
//
//
//- (id)c2objectValue{
//	switch (_type.typeKind) {
//		case MF_TYPE_CLASS:
//			return _classValue;
//		case MF_TYPE_OBJECT:
//		case MF_TYPE_BLOCK:
//			return self.objectValue;
//		case MF_TYPE_POINTER:
//			return (__bridge id)_pointerValue;
//		default:
//			return nil;
//	}
//
//}
//
//
//- (void *)c2pointerValue{
//	switch (_type.typeKind) {
//		case MF_TYPE_C_STRING:
//			return (void *)_cstringValue;
//		case MF_TYPE_POINTER:
//        case MF_TYPE_C_FUNCTION:
//			return _pointerValue;
//		case MF_TYPE_CLASS:
//			return (__bridge void*)_classValue;
//		case MF_TYPE_OBJECT:
//		case MF_TYPE_BLOCK:
//			return (__bridge void*)self.objectValue;
//		default:
//			return NULL;
//	}
//}


//- (void)assignToCValuePointer:(void *)cvaluePointer typeEncoding:(const char *)typeEncoding{
//	typeEncoding = removeTypeEncodingPrefix((char *)typeEncoding);
//#define mf_ASSIGN_2_C_VALUE_POINTER_CASE(_encode, _type, _sel)\
//case _encode:{\
//_type *ptr = (_type *)cvaluePointer;\
//*ptr = (_type)[self _sel];\
//break;\
//}
//
//	switch (*typeEncoding) {
//			mf_ASSIGN_2_C_VALUE_POINTER_CASE('c', char, c2integerValue)
//			mf_ASSIGN_2_C_VALUE_POINTER_CASE('i', int, c2integerValue)
//			mf_ASSIGN_2_C_VALUE_POINTER_CASE('s', short, c2integerValue)
//			mf_ASSIGN_2_C_VALUE_POINTER_CASE('l', long, c2integerValue)
//			mf_ASSIGN_2_C_VALUE_POINTER_CASE('q', long long, c2integerValue)
//			mf_ASSIGN_2_C_VALUE_POINTER_CASE('C', unsigned char, c2uintValue)
//			mf_ASSIGN_2_C_VALUE_POINTER_CASE('I', unsigned int, c2uintValue)
//			mf_ASSIGN_2_C_VALUE_POINTER_CASE('S', unsigned short, c2uintValue)
//			mf_ASSIGN_2_C_VALUE_POINTER_CASE('L', unsigned long, c2uintValue)
//			mf_ASSIGN_2_C_VALUE_POINTER_CASE('Q', unsigned long long, c2uintValue)
//			mf_ASSIGN_2_C_VALUE_POINTER_CASE('f', float, c2doubleValue)
//			mf_ASSIGN_2_C_VALUE_POINTER_CASE('d', double, c2doubleValue)
//			mf_ASSIGN_2_C_VALUE_POINTER_CASE('B', BOOL, c2uintValue)
//			mf_ASSIGN_2_C_VALUE_POINTER_CASE('*', char *, c2pointerValue)
//			mf_ASSIGN_2_C_VALUE_POINTER_CASE('^', void *, c2pointerValue)
//			mf_ASSIGN_2_C_VALUE_POINTER_CASE(':', SEL, selValue)
//		case '@':{
//			void  **ptr =cvaluePointer;
//			*ptr = (__bridge void *)[self c2objectValue];
//			break;
//		}
//		case '#':{
//			Class *ptr = (Class  *)cvaluePointer;
//			*ptr = [self c2objectValue];
//			break;
//		}
//		case '{':{
//			if (_type.typeKind == MF_TYPE_STRUCT) {
//				size_t structSize = mf_size_with_encoding(typeEncoding);
//				memcpy(cvaluePointer, self.pointerValue, structSize);
//			}else if (_type.typeKind == MF_TYPE_STRUCT_LITERAL){
//				NSString *structName = mf_struct_name_with_encoding(typeEncoding);
//				MFStructDeclareTable *table = [MFStructDeclareTable shareInstance];
//				mf_struct_data_with_dic(cvaluePointer, self.objectValue, [table getStructDeclareWithName:structName]);
//			}
//			break;
//		}
//		case 'v':{
//			break;
//		}
//		default:
//			NSCAssert(0, @"");
//			break;
//	}
//}


//- (instancetype)initWithCValuePointer:(void *)cValuePointer typeEncoding:(const char *)typeEncoding bridgeTransfer:(BOOL)bridgeTransfer  {
//	typeEncoding = removeTypeEncodingPrefix((char *)typeEncoding);
//	MFValue *retValue = [[MFValue alloc] init];
//
//#define MFGO_C_VALUE_CONVER_TO_mf_VALUE_CASE(_code,_kind, _type,_sel)\
//case _code:{\
//retValue.type = mf_create_type_specifier(_kind);\
//retValue._sel = *(_type *)cValuePointer;\
//break;\
//}
//
//	switch (*typeEncoding) {
//			MFGO_C_VALUE_CONVER_TO_mf_VALUE_CASE('c',MF_TYPE_INT, char, integerValue)
//			MFGO_C_VALUE_CONVER_TO_mf_VALUE_CASE('i',MF_TYPE_INT, int,integerValue)
//			MFGO_C_VALUE_CONVER_TO_mf_VALUE_CASE('s',MF_TYPE_INT, short,integerValue)
//			MFGO_C_VALUE_CONVER_TO_mf_VALUE_CASE('l',MF_TYPE_INT, long,integerValue)
//			MFGO_C_VALUE_CONVER_TO_mf_VALUE_CASE('q',MF_TYPE_INT, long long,integerValue)
//			MFGO_C_VALUE_CONVER_TO_mf_VALUE_CASE('C',MF_TYPE_U_INT, unsigned char, uintValue)
//			MFGO_C_VALUE_CONVER_TO_mf_VALUE_CASE('I',MF_TYPE_U_INT,  unsigned int, uintValue)
//			MFGO_C_VALUE_CONVER_TO_mf_VALUE_CASE('S',MF_TYPE_U_INT, unsigned short, uintValue)
//			MFGO_C_VALUE_CONVER_TO_mf_VALUE_CASE('L',MF_TYPE_U_INT,  unsigned long, uintValue)
//			MFGO_C_VALUE_CONVER_TO_mf_VALUE_CASE('Q',MF_TYPE_U_INT, unsigned long long,uintValue)
//			MFGO_C_VALUE_CONVER_TO_mf_VALUE_CASE('B',MF_TYPE_BOOL, BOOL, uintValue)
//			MFGO_C_VALUE_CONVER_TO_mf_VALUE_CASE('f',MF_TYPE_DOUBLE, float, doubleValue)
//			MFGO_C_VALUE_CONVER_TO_mf_VALUE_CASE('d',MF_TYPE_DOUBLE, double,doubleValue)
//			MFGO_C_VALUE_CONVER_TO_mf_VALUE_CASE(':',MF_TYPE_SEL, SEL, selValue)
//			MFGO_C_VALUE_CONVER_TO_mf_VALUE_CASE('^',MF_TYPE_POINTER,void *, pointerValue)
//			MFGO_C_VALUE_CONVER_TO_mf_VALUE_CASE('*',MF_TYPE_C_STRING, char *,cstringValue)
//			MFGO_C_VALUE_CONVER_TO_mf_VALUE_CASE('#',MF_TYPE_CLASS, Class,classValue)
//		case '@':{
//			retValue.type = mf_create_type_specifier(MF_TYPE_OBJECT);
//			if (bridgeTransfer) {
//                id objectValue = (__bridge_transfer id)(*(void **)cValuePointer);
//                retValue.objectValue = objectValue;
//			}else{
//                id objectValue = (__bridge id)(*(void **)cValuePointer);
//                retValue.objectValue = objectValue;
//			}
//
//			break;
//		}
//		case '{':{
//			NSString *structName = mf_struct_name_with_encoding(typeEncoding);
//			retValue.type= mf_create_struct_type_specifier(structName);
//			size_t size = mf_size_with_encoding(typeEncoding);
//			retValue.pointerValue = malloc(size);
//			memcpy(retValue.pointerValue, cValuePointer, size);
//			break;
//		}
//
//		default:
//			NSCAssert(0, @"not suppoert %s", typeEncoding);
//			break;
//	}
//
//	return retValue;
//}


//+ (instancetype)defaultValueWithTypeEncoding:(const char *)typeEncoding{
//	typeEncoding = removeTypeEncodingPrefix((char *)typeEncoding);
//	MFValue *value = [[MFValue alloc] init];
//	switch (*typeEncoding) {
//		case 'c':
//			value.type = mf_create_type_specifier(MF_TYPE_INT);
//			break;
//		case 'i':
//			value.type = mf_create_type_specifier(MF_TYPE_INT);
//			break;
//		case 's':
//			value.type = mf_create_type_specifier(MF_TYPE_INT);
//			break;
//		case 'l':
//			value.type = mf_create_type_specifier(MF_TYPE_INT);
//			break;
//		case 'q':
//			value.type = mf_create_type_specifier(MF_TYPE_INT);
//			break;
//		case 'C':
//			value.type = mf_create_type_specifier(MF_TYPE_U_INT);
//			break;
//		case 'I':
//			value.type = mf_create_type_specifier(MF_TYPE_U_INT);
//			break;
//		case 'S':
//			value.type = mf_create_type_specifier(MF_TYPE_U_INT);
//			break;
//		case 'L':
//			value.type = mf_create_type_specifier(MF_TYPE_U_INT);
//			break;
//		case 'Q':
//			value.type = mf_create_type_specifier(MF_TYPE_U_INT);
//			break;
//		case 'B':
//			value.type = mf_create_type_specifier(MF_TYPE_BOOL);
//			break;
//		case 'f':
//			value.type = mf_create_type_specifier(MF_TYPE_DOUBLE);
//			break;
//		case 'd':
//			value.type = mf_create_type_specifier(MF_TYPE_DOUBLE);
//			break;
//		case ':':
//			value.type = mf_create_type_specifier(MF_TYPE_SEL);
//			break;
//		case '^':
//			value.type = mf_create_type_specifier(MF_TYPE_POINTER);
//			break;
//		case '*':
//			value.type = mf_create_type_specifier(MF_TYPE_C_STRING);
//			break;
//		case '#':
//			value.type = mf_create_type_specifier(MF_TYPE_CLASS);
//			break;
//		case '@':
//			value.type = mf_create_type_specifier(MF_TYPE_OBJECT);
//			break;
//        case '{':{
//			value.type = mf_create_struct_type_specifier(mf_struct_name_with_encoding(typeEncoding));
//            value.type.structName =  mf_struct_name_with_encoding(typeEncoding);
//            size_t size = mf_size_with_encoding(typeEncoding);
//            value.pointerValue = malloc(size);
//			break;
//        }
//		case 'v':
//			value.type = mf_create_type_specifier(MF_TYPE_VOID);
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
    [value setValueType:TypeObject];
    value.typePair.var.ptCount = 2;
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

