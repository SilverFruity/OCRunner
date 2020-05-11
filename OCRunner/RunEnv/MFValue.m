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
    switch (_pair.type.type) {
		case TypeBOOL:
        case TypeUChar:
        case TypeUShort:
		case TypeUInt:
        case TypeULong:
        case TypeULongLong:
			return _uintValue ? YES : NO;
		case TypeChar:
        case TypeShort:
        case TypeInt:
        case TypeLong:
        case TypeLongLong:
			return _integerValue ? YES : NO;
		case TypeFloat:
        case TypeDouble:
			return _doubleValue ? YES : NO;
//		case MF_TYPE_C_STRING:
//			return _cstringValue ? YES : NO;
		case TypeClass:
			return _classValue ? YES : NO;
		case TypeSEL:
			return _selValue ? YES : NO;
		case TypeObject:
//		case MF_TYPE_STRUCT_LITERAL:
		case TypeBlock:
			return self.objectValue ? YES : NO;
		case TypeStruct:
//		case MF_TYPE_POINTER:
			return _pointerValue ? YES : NO;
		case TypeVoid:
			return NO;
		default:
			break;
	}
	return NO;
}


- (BOOL)isMember{
    switch (_pair.type.type) {
		case TypeBOOL:
		case TypeInt:
		case TypeULongLong:
		case TypeDouble:
			return YES;
		default:
			return NO;
	}
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
- (id)subscriptGetWithIndex:(MFValue *)index{
    if (index.typePair.type.type & TypeBaseMask) {
        return (id)self.objectValue[index.c2integerValue];
    }
    switch (index.typePair.type.type) {
        case TypeBlock:
        case TypeObject:
            return self.objectValue[index.objectValue];
            break;
        case TypeClass:
            return self.objectValue[index.classValue];
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
    switch (_pair.type.type) {
		case TypeBOOL:
		case TypeUInt:
			_uintValue = [src c2uintValue];
			break;
		case TypeInt:
			_integerValue = [src c2integerValue];
			break;
		case TypeDouble:
			_doubleValue = [src c2doubleValue];
			break;
		case TypeSEL:
			_selValue = [src selValue];
			break;
		case TypeBlock:
		case TypeObject:
			self.objectValue = [src c2objectValue];
			break;
		case TypeClass:
			_classValue = [src c2objectValue];
			break;
//		case MF_TYPE_POINTER:
//			_pointerValue = [src c2pointerValue];
//			break;
//		case MF_TYPE_C_STRING:
//			_cstringValue = [src c2pointerValue];
//			break;

		default:
			NSCAssert(0, @"");
			break;
	}
	
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
//
//
//+ (instancetype)valueInstanceWithBOOL:(BOOL)boolValue{
//	MFValue *value = [[MFValue alloc] init];
//	value.type = mf_create_type_specifier(MF_TYPE_BOOL);
//	value.uintValue = boolValue;
//	return value;
//}
//
//
//+ (instancetype)valueInstanceWithUint:(uint64_t)uintValue{
//	MFValue *value = [[MFValue alloc] init];
//	value.type = mf_create_type_specifier(MF_TYPE_U_INT);
//	value.uintValue = uintValue;
//	return value;
//}
//
//
//+ (instancetype)valueInstanceWithInt:(int64_t)intValue{
//	MFValue *value = [[MFValue alloc] init];
//	value.type = mf_create_type_specifier(MF_TYPE_INT);
//	value.integerValue = intValue;
//	return value;
//}
//
//
//+ (instancetype)valueInstanceWithDouble:(double)doubleValue{
//	MFValue *value = [[MFValue alloc] init];
//	value.type = mf_create_type_specifier(MF_TYPE_DOUBLE);
//	value.doubleValue = doubleValue;
//	return value;
//}
//
//
//+ (instancetype)valueInstanceWithObject:(id)objValue{
//	MFValue *value = [[MFValue alloc] init];
//	value.type = mf_create_type_specifier(MF_TYPE_OBJECT);
//	value.objectValue = objValue;
//	return value;
//}
//
//
//+ (instancetype)valueInstanceWithBlock:(id)blockValue{
//	MFValue *value = [[MFValue alloc] init];
//	value.type = mf_create_type_specifier(MF_TYPE_BLOCK);
//	value.objectValue = blockValue;
//	return value;
//}
//
//
//+ (instancetype)valueInstanceWithClass:(Class)clazzValue{
//	MFValue *value = [[MFValue alloc] init];
//	value.type = mf_create_type_specifier(MF_TYPE_CLASS);
//	value.classValue = clazzValue;
//	return value;
//}
//
//
//+ (instancetype)valueInstanceWithSEL:(SEL)selValue{
//	MFValue *value = [[MFValue alloc] init];
//	value.type = mf_create_type_specifier(MF_TYPE_SEL);
//	value.selValue = selValue;
//	return value;
//}
//
//
//+ (instancetype)valueInstanceWithCstring:(const char *)cstringValue{
//	MFValue *value = [[MFValue alloc] init];
//	value.type = mf_create_type_specifier(MF_TYPE_C_STRING);
//	value.cstringValue = cstringValue;
//	return value;
//}
//
//
//+ (instancetype)valueInstanceWithPointer:(void *)pointerValue{
//	MFValue *value = [[MFValue alloc] init];
//	value.type = mf_create_type_specifier(MF_TYPE_POINTER);
//	value.pointerValue = pointerValue;
//	return value;
//}
//
//
//+ (instancetype)valueInstanceWithStruct:(void *)structValue typeEncoding:(const char *)typeEncoding copyData:(BOOL)copyData{
//	MFValue *value = [[MFValue alloc] init];
//	value.type = mf_create_type_specifier(MF_TYPE_STRUCT);
//	value.type.structName = mf_struct_name_with_encoding(typeEncoding);
//	size_t size = mf_size_with_encoding(typeEncoding);
//    if (copyData) {
//        value.pointerValue = malloc(size);
//        memcpy(value.pointerValue, structValue, size);
//    }else{
//        value.pointerValue = structValue;
//        value.structPointNoCopyData = YES;
//    }
//	return value;
//}
//
//
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
//
//- (MFTypeSpecifier *)type{
//    return _type;
//}
//
//
//- (void)setType:(MFTypeSpecifier *)type{
//    _type = type;
//}
//
//-(void)setObjectValue:(id)objectValue{
//    if (self.modifier & MFDeclarationModifierWeak) {
//        _weakObj = objectValue;
//    }else{
//        _strongObj = objectValue;
//    }
//}
//
//
//- (id)objectValue{
//    if (self.modifier & MFDeclarationModifierWeak) {
//        return _weakObj;
//    }else{
//        return _strongObj;
//    }
//}
//
-(void *)valuePointer{
    unsigned char ucharValue = 0;
    unsigned short uShortValue = 0;
    unsigned int uIntValue = 0;
    unsigned long uLongValue = 0;
    unsigned long long uLLongValue = 0;
    BOOL boolValue = 0;
    
    char charValue = 0;
    short shortValue = 0;
    int intValue = 0;
    long longValue = 0;
    long long lLongValue = 0;
    
    float floatValue = 0;
    float doubleValue = 0;
    NSObject *objectValue = nil;
    SEL selValue = 0;
    Class classValue = nil;
    void *pointerValue = nil;
    do {
        if ((self.typePair.type.type & TypeBaseMask) && self.typePair.var.ptCount > 0) {
            pointerValue = *(void **)self.pointerValue;
            break;
        }
        switch (self.typePair.type.type) {
            case TypeUChar:
                ucharValue = *(unsigned char *)self.pointerValue; break;
            case TypeUShort:
                uShortValue = *(unsigned short *)self.pointerValue; break;
            case TypeUInt:
                uIntValue = *(unsigned int *)self.pointerValue; break;
            case TypeULong:
                uLongValue = *(unsigned long *)self.pointerValue; break;
            case TypeULongLong:
                uLLongValue = *(unsigned long long *)self.pointerValue; break;
            case TypeBOOL:
                boolValue = *(BOOL *)self.pointerValue; break;
            case TypeChar:
                charValue = *(char *)self.pointerValue; break;
            case TypeShort:
                shortValue = *(short *)self.pointerValue; break;
            case TypeInt:
                intValue = *(int *)self.pointerValue; break;
            case TypeLong:
                longValue = *(long *)self.pointerValue; break;
            case TypeLongLong:
                lLongValue = *(long long *)self.pointerValue; break;
                break;
                
            case TypeFloat:
                floatValue = *(double *)self.pointerValue; break;
            case TypeDouble:
                doubleValue = *(double *)self.pointerValue; break;
                break;
                
            case TypeId:
            case TypeObject:
            case TypeBlock:{
                if (self.modifier & MFDeclarationModifierWeak) {
                    objectValue = _weakObj;
                }else{
                    objectValue = _strongObj;
                }
                break;
            }
            case TypeSEL:
                selValue = *(SEL *)self.pointerValue; break;
                break;
            case TypeClass:
                classValue = *(Class *)self.pointerValue; break;;
                break;
                break;
//            case TypeUnion:
//            case TypeEnum:
//            case TypeStruct:
            default:
                break;
        }
    } while (0);
    

    return NULL;
}
//
//- (void)dealloc{
//    if (_type.typeKind == MF_TYPE_STRUCT && !_structPointNoCopyData) {
//        free(_pointerValue);
//    }
//}

@end

