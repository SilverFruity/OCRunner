//
//  MFValue .h
//  MangoFix
//
//  Created by jerry.yong on 2018/2/28.
//  Copyright © 2018年 yongpengliang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RunnerClasses.h"
#define startBox(value)\
NSUInteger size;\
NSGetSizeAndAlignment(value.typeEncode, &size, NULL);\
void *box = malloc(size);\

#define endBox(result)\
result.pointer = box;\
free(box);

#define PrefixUnaryExecuteInt(operator,value)\
switch (value.type) {\
case TypeUChar:\
*(unsigned char *)box = (operator *(unsigned char *)value.pointer); break;\
case TypeUShort:\
*(unsigned short *)box = (operator *(unsigned short *)value.pointer); break;\
case TypeUInt:\
*(unsigned int *)box = (operator *(unsigned int *)value.pointer); break;\
case TypeULong:\
*(unsigned long *)box = (operator *(unsigned long *)value.pointer); break;\
case TypeULongLong:\
*(unsigned long long *)box = (operator *(unsigned long long *)value.pointer); break;\
case TypeBOOL:\
*(BOOL *)box = (operator *(BOOL *)value.pointer); break;\
case TypeChar:\
*(char *)box = (operator *(char *)value.pointer); break;\
case TypeShort:\
*(short *)box = (operator *(short *)value.pointer); break;\
case TypeInt:\
*(int *)box = (operator *(int *)value.pointer); break;\
case TypeLong:\
*(long *)box = (operator *(long *)value.pointer); break;\
case TypeLongLong:\
*(long long *)box = (operator *(long long *)value.pointer); break;\
default:\
break;\
}\

#define PrefixUnaryExecuteFloat(operator,value)\
switch (value.type) {\
case TypeFloat:\
*(float *)box = (operator *(float *)value.pointer); break;\
case TypeDouble:\
*(double *)box = (operator *(double *)value.pointer); break;\
default:\
break;\
}\

#define SuffixUnaryExecuteInt(operator,value)\
switch (value.type) {\
case TypeUChar:\
*(unsigned char *)box = ((*(unsigned char *)value.pointer) operator); break;\
case TypeUShort:\
*(unsigned short *)box = ((*(unsigned short *)value.pointer) operator); break;\
case TypeUInt:\
*(unsigned int *)box = ((*(unsigned int *)value.pointer) operator); break;\
case TypeULong:\
*(unsigned long *)box = ((*(unsigned long *)value.pointer) operator); break;\
case TypeULongLong:\
*(unsigned long long *)box = ((*(unsigned long long *)value.pointer) operator); break;\
case TypeBOOL:\
*(BOOL *)box = ((*(BOOL *)value.pointer) operator); break;\
case TypeChar:\
*(char *)box = ((*(char *)value.pointer) operator); break;\
case TypeShort:\
*(short *)box = ((*(short *)value.pointer) operator); break;\
case TypeInt:\
*(int *)box = ((*(int *)value.pointer) operator); break;\
case TypeLong:\
*(long *)box = ((*(long *)value.pointer) operator); break;\
case TypeLongLong:\
*(long long *)box = ((*(long long *)value.pointer) operator); break;\
default:\
break;\
}\


#define SuffixUnaryExecuteFloat(operator,value)\
switch (value.type) {\
case TypeFloat:\
*(float *)box = ((*(float *)value.pointer) operator); break;\
case TypeDouble:\
*(double *)box = ((*(double *)value.pointer) operator); break;\
default:\
break;\
}\

#define UnaryExecuteBaseType(resultName,operator,value)\
switch (value.type) {\
case TypeUChar:\
resultName = operator (*(unsigned char *)value.pointer); break;\
case TypeUShort:\
resultName = operator (*(unsigned short *)value.pointer); break;\
case TypeUInt:\
resultName = operator (*(unsigned int *)value.pointer); break;\
case TypeULong:\
resultName = operator (*(unsigned long *)value.pointer); break;\
case TypeULongLong:\
resultName = operator (*(unsigned long long *)value.pointer); break;\
case TypeBOOL:\
resultName = operator (*(BOOL *)value.pointer); break;\
case TypeChar:\
resultName = operator (*(char *)value.pointer); break;\
case TypeShort:\
resultName = operator (*(short *)value.pointer); break;\
case TypeInt:\
resultName = operator (*(int *)value.pointer); break;\
case TypeLong:\
resultName = operator (*(long *)value.pointer); break;\
case TypeLongLong:\
resultName = operator (*(long long *)value.pointer); break;\
case TypeFloat:\
resultName = operator (*(float *)value.pointer); break;\
case TypeDouble:\
resultName = operator (*(double *)value.pointer); break;\
default:\
break;\
}


#define UnaryExecute(resultName,operator,value)\
do{\
    if (value.isPointer) {\
        resultName = operator (value.pointer);\
        break;\
    }\
    UnaryExecuteBaseType(resultName,operator,value)\
    switch (value.type) {\
    case TypeId:\
    case TypeObject:\
    case TypeBlock:\
    resultName = operator (*(__strong id *)value.pointer); break;\
    case TypeSEL:\
    resultName = operator (*(SEL *)value.pointer); break;\
    case TypeClass:\
    resultName = operator (*(Class *)value.pointer); break;\
    default:\
    break;\
    }\
}while(0)

#define BinaryExecute(type,leftValue,operator,rightValue)\
( (*(type *)leftValue.pointer) operator (*(type *)rightValue.pointer) ); break;

#define BoxBinaryExecute(type,leftValue,operator,rightValue)\
*(type *)box = BinaryExecute(type,leftValue,operator,rightValue)

#define BinaryExecuteInt(leftValue,operator,rightValue,resultValue)\
switch (leftValue.type) {\
case TypeUChar:\
BoxBinaryExecute(unsigned char,leftValue,operator,rightValue)\
case TypeUShort:\
BoxBinaryExecute(unsigned short,leftValue,operator,rightValue)\
case TypeUInt:\
BoxBinaryExecute(unsigned int,leftValue,operator,rightValue)\
case TypeULong:\
BoxBinaryExecute(unsigned long,leftValue,operator,rightValue)\
case TypeULongLong:\
BoxBinaryExecute(unsigned long long,leftValue,operator,rightValue)\
case TypeBOOL:\
BoxBinaryExecute(BOOL,leftValue,operator,rightValue)\
case TypeChar:\
BoxBinaryExecute(char,leftValue,operator,rightValue)\
case TypeShort:\
BoxBinaryExecute(short,leftValue,operator,rightValue)\
case TypeInt:\
BoxBinaryExecute(int,leftValue,operator,rightValue)\
case TypeLong:\
BoxBinaryExecute(long,leftValue,operator,rightValue)\
case TypeLongLong:\
BoxBinaryExecute(long long,leftValue,operator,rightValue)\
default:\
break;\
}

#define BinaryExecuteFloat(leftValue,operator,rightValue,resultValue)\
switch (leftValue.type) {\
case TypeFloat:\
BoxBinaryExecute(float,leftValue,operator,rightValue)\
case TypeDouble:\
BoxBinaryExecute(double,leftValue,operator,rightValue)\
default:\
break;\
}

#define LogicBinaryOperatorExecute(leftValue,operator,rightValue)\
BOOL logicResultValue = NO;\
do{\
    switch (leftValue.type) {\
    case TypeUChar:\
    logicResultValue = BinaryExecute(unsigned char,leftValue,operator,rightValue)\
    case TypeUShort:\
    logicResultValue = BinaryExecute(unsigned short,leftValue,operator,rightValue)\
    case TypeUInt:\
    logicResultValue = BinaryExecute(unsigned int,leftValue,operator,rightValue)\
    case TypeULong:\
    logicResultValue = BinaryExecute(unsigned long,leftValue,operator,rightValue)\
    case TypeULongLong:\
    logicResultValue = BinaryExecute(unsigned long long,leftValue,operator,rightValue)\
    case TypeBOOL:\
    logicResultValue = BinaryExecute(BOOL,leftValue,operator,rightValue)\
    case TypeChar:\
    logicResultValue = BinaryExecute(char,leftValue,operator,rightValue)\
    case TypeShort:\
    logicResultValue = BinaryExecute(short,leftValue,operator,rightValue)\
    case TypeInt:\
    logicResultValue = BinaryExecute(int,leftValue,operator,rightValue)\
    case TypeLong:\
    logicResultValue = BinaryExecute(long,leftValue,operator,rightValue)\
    case TypeLongLong:\
    logicResultValue = BinaryExecute(long long,leftValue,operator,rightValue)\
    case TypeFloat:\
    logicResultValue = BinaryExecute(float,leftValue,operator,rightValue)\
    case TypeDouble:\
    logicResultValue = BinaryExecute(double,leftValue,operator,rightValue)\
    case TypeId:\
    case TypeObject:\
    case TypeBlock:\
    logicResultValue = ( (*(__strong id *)leftValue.pointer) operator (*(__strong id *)rightValue.pointer) ); break;\
    case TypeSEL:\
    logicResultValue = BinaryExecute(SEL,leftValue,operator,rightValue)\
    case TypeClass:\
    logicResultValue = BinaryExecute(Class,leftValue,operator,rightValue)\
    default:\
    break;\
    }\
}while(0)

#define MFValueSetValue(target,from)\
do{\
    if (target.isPointer) {\
        target.pointer = from.pointer;\
        break;\
    }\
    switch (target.typePair.type.type) {\
    case TypeUChar:\
    target.uCharValue = from.uCharValue; break;\
    case TypeUShort:\
    target.uShortValue = from.uShortValue; break;\
    case TypeUInt:\
    target.uIntValue = from.uIntValue; break;\
    case TypeULong:\
    target.uLongValue = from.uLongValue; break;\
    case TypeULongLong:\
    target.uLongLongValue = from.uLongLongValue; break;\
    case TypeBOOL:\
    target.boolValue = from.boolValue; break;\
    case TypeChar:\
    target.charValue = from.charValue; break;\
    case TypeShort:\
    target.shortValue = from.shortValue; break;\
    case TypeInt:\
    target.intValue = from.intValue; break;\
    case TypeLong:\
    target.longValue = from.longValue; break;\
    case TypeLongLong:\
    target.longLongValue = from.longLongValue; break;\
    case TypeFloat:\
    target.floatValue = from.floatValue; break;\
    case TypeDouble:\
    target.doubleValue = from.doubleValue; break;\
    case TypeId:\
    case TypeObject:\
    case TypeBlock:\
    target.objectValue = from.objectValue; break;\
    case TypeSEL:\
    target.selValue = from.selValue; break;\
    case TypeClass:\
    target.classValue = from.classValue; break;\
    default:\
    break;\
    }\
}while(0)


NS_ASSUME_NONNULL_BEGIN
typedef NS_ENUM(NSInteger, MFStatementResultType) {
    //no return, continue, break
    MFStatementResultTypeNormal = 0x00,
    MFStatementResultTypeBreak = 0x01,
    MFStatementResultTypeContinue = 0x02,
    //return value;
    MFStatementResultTypeReturnValue = 0x10,
    //return;
    MFStatementResultTypeReturnEmpty = 0x10 << 1,
    MFStatementResultTypeReturnMask = 0xF0
};
@class ORTypeVarPair;


ORTypeVarPair *typePairWithTypeEncode(const char *tyepEncode);

extern BOOL MFStatementResultTypeIsReturn(MFStatementResultType type);

@interface MFValue : NSObject <NSCopying>
@property (assign, nonatomic) MFStatementResultType resultType;
@property (assign,nonatomic)ORDeclarationModifier modifier;
@property (assign,nonatomic)TypeKind type;
@property (strong,nonatomic)NSString *typeName;
@property (assign,nonatomic)NSInteger pointerCount;
@property (nonatomic,assign)const char* typeEncode;
@property (nonatomic,assign, nullable)void *pointer;

+ (instancetype)defaultValueWithTypeEncoding:(const char *)typeEncoding;
+ (instancetype)valueWithTypeKind:(TypeKind)TypeKind pointer:(nullable void *)pointer;
+ (instancetype)valueWithTypePair:(ORTypeVarPair *)typePair pointer:(nullable void *)pointer;
- (instancetype)initTypeEncode:(const char *)typeEncoding;
- (instancetype)initTypeEncode:(const char *)tyepEncode pointer:(nullable void *)pointer;

- (void)writePointer:(void *)pointer typeEncode:(const char *)typeEncode;
- (void)setTypeInfoWithValue:(MFValue *)value;
- (void)setTypeInfoWithTypePair:(ORTypeVarPair *)typePair;
- (void)assignFrom:(MFValue *)src;
- (void)setTypeBySearchInTypeSymbolTable;

- (BOOL)isPointer;
- (BOOL)isSubtantial;
- (BOOL)isInteger;
- (BOOL)isFloat;

- (MFValue *)subscriptGetWithIndex:(MFValue *)index;
- (void)subscriptSetValue:(MFValue *)value index:(MFValue *)index;
@end

@interface MFValue (Struct)
- (BOOL)isStruct;
- (BOOL)isStructPointer;
- (void)setFieldWithValue:(MFValue *)value forKey:(NSString *)key;
- (MFValue *)fieldForKey:(NSString *)key;
- (MFValue *)getResutlInPointer;
- (void)enumerateStructFieldsUsingBlock:(void (^)(MFValue *field, NSUInteger idx))block;
@end

@interface MFValue (MFStatementResultType)
@property (assign, nonatomic, readonly) BOOL isReturn;
@property (assign, nonatomic, readonly) BOOL isContinue;
@property (assign, nonatomic, readonly) BOOL isBreak;
@property (assign, nonatomic, readonly) BOOL isNormal;
+ (instancetype)normalEnd;
@end

@interface MFValue (ValueType)


@property (assign, nonatomic, readonly) unsigned char uCharValue;
@property (assign, nonatomic, readonly) unsigned short uShortValue;
@property (assign, nonatomic, readonly) unsigned int uIntValue;
@property (assign, nonatomic, readonly) unsigned long uLongValue;
@property (assign, nonatomic, readonly) unsigned long long uLongLongValue;

@property (assign, nonatomic, readonly) char charValue;
@property (assign, nonatomic, readonly) short shortValue;
@property (assign, nonatomic, readonly) int intValue;
@property (assign, nonatomic, readonly) long longValue;
@property (assign, nonatomic, readonly) long long longLongValue;

@property (assign, nonatomic, readonly) BOOL boolValue;

@property (assign, nonatomic, readonly) float floatValue;
@property (assign, nonatomic, readonly) double doubleValue;

@property (nonatomic, nullable, readonly) id objectValue;
@property (nonatomic, nullable, readonly) Class classValue;
@property (nonatomic, nullable, readonly) SEL selValue;

+ (instancetype)voidValue;
+ (instancetype)valueWithBOOL:(BOOL)boolValue;
+ (instancetype)valueWithUChar:(unsigned char)uCharValue;
+ (instancetype)valueWithUShort:(unsigned short)uShortValue;
+ (instancetype)valueWithUInt:(unsigned int)uIntValue;
+ (instancetype)valueWithULong:(unsigned long)uLongValue;
+ (instancetype)valueWithULongLong:(unsigned long long)uLongLongValue;
+ (instancetype)valueWithChar:(char)charValue;
+ (instancetype)valueWithShort:(short)shortValue;
+ (instancetype)valueWithInt:(int)intValue;
+ (instancetype)valueWithLong:(long)longValue;
+ (instancetype)valueWithLongLong:(long long)longLongValue;
+ (instancetype)valueWithFloat:(float)floatValue;
+ (instancetype)valueWithDouble:(double)doubleValue;
+ (instancetype)valueWithObject:(nullable id)objValue;
+ (instancetype)valueWithBlock:(nullable id)blockValue;
+ (instancetype)valueWithClass:(nullable Class)clazzValue;
+ (instancetype)valueWithSEL:(SEL)selValue;
+ (instancetype)valueWithCString:(char *)pointerValue;
+ (instancetype)valueWithPointer:(nullable void *)pointerValue;
@end
NS_ASSUME_NONNULL_END
