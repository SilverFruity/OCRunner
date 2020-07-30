//
//  MFValue .h
//  MangoFix
//
//  Created by jerry.yong on 2018/2/28.
//  Copyright © 2018年 yongpengliang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RunnerClasses.h"
#import "ORHandleTypeEncode.h"

#define startBox(value)\
NSUInteger size;\
NSGetSizeAndAlignment(value.typeEncode, &size, NULL);\
void *box = malloc(size);\

#define endBox(result)\
result.pointer = box;\
free(box);

#define PrefixUnaryExecuteInt(operator,value)\
switch (value.type) {\
case OCTypeUChar:\
*(unsigned char *)box = (operator *(unsigned char *)value.pointer); break;\
case OCTypeUShort:\
*(unsigned short *)box = (operator *(unsigned short *)value.pointer); break;\
case OCTypeUInt:\
*(unsigned int *)box = (operator *(unsigned int *)value.pointer); break;\
case OCTypeULong:\
*(unsigned long *)box = (operator *(unsigned long *)value.pointer); break;\
case OCTypeULongLong:\
*(unsigned long long *)box = (operator *(unsigned long long *)value.pointer); break;\
case OCTypeBOOL:\
*(BOOL *)box = (operator *(BOOL *)value.pointer); break;\
case OCTypeChar:\
*(char *)box = (operator *(char *)value.pointer); break;\
case OCTypeShort:\
*(short *)box = (operator *(short *)value.pointer); break;\
case OCTypeInt:\
*(int *)box = (operator *(int *)value.pointer); break;\
case OCTypeLong:\
*(long *)box = (operator *(long *)value.pointer); break;\
case OCTypeLongLong:\
*(long long *)box = (operator *(long long *)value.pointer); break;\
default:\
break;\
}\

#define PrefixUnaryExecuteFloat(operator,value)\
switch (value.type) {\
case OCTypeFloat:\
*(float *)box = (operator *(float *)value.pointer); break;\
case OCTypeDouble:\
*(double *)box = (operator *(double *)value.pointer); break;\
default:\
break;\
}\

#define SuffixUnaryExecuteInt(operator,value)\
switch (value.type) {\
case OCTypeUChar:\
*(unsigned char *)box = ((*(unsigned char *)value.pointer) operator); break;\
case OCTypeUShort:\
*(unsigned short *)box = ((*(unsigned short *)value.pointer) operator); break;\
case OCTypeUInt:\
*(unsigned int *)box = ((*(unsigned int *)value.pointer) operator); break;\
case OCTypeULong:\
*(unsigned long *)box = ((*(unsigned long *)value.pointer) operator); break;\
case OCTypeULongLong:\
*(unsigned long long *)box = ((*(unsigned long long *)value.pointer) operator); break;\
case OCTypeBOOL:\
*(BOOL *)box = ((*(BOOL *)value.pointer) operator); break;\
case OCTypeChar:\
*(char *)box = ((*(char *)value.pointer) operator); break;\
case OCTypeShort:\
*(short *)box = ((*(short *)value.pointer) operator); break;\
case OCTypeInt:\
*(int *)box = ((*(int *)value.pointer) operator); break;\
case OCTypeLong:\
*(long *)box = ((*(long *)value.pointer) operator); break;\
case OCTypeLongLong:\
*(long long *)box = ((*(long long *)value.pointer) operator); break;\
default:\
break;\
}\


#define SuffixUnaryExecuteFloat(operator,value)\
switch (value.type) {\
case OCTypeFloat:\
*(float *)box = ((*(float *)value.pointer) operator); break;\
case OCTypeDouble:\
*(double *)box = ((*(double *)value.pointer) operator); break;\
default:\
break;\
}\

#define UnaryExecuteBaseType(resultName,operator,value)\
switch (value.type) {\
case OCTypeUChar:\
resultName = operator (*(unsigned char *)value.pointer); break;\
case OCTypeUShort:\
resultName = operator (*(unsigned short *)value.pointer); break;\
case OCTypeUInt:\
resultName = operator (*(unsigned int *)value.pointer); break;\
case OCTypeULong:\
resultName = operator (*(unsigned long *)value.pointer); break;\
case OCTypeULongLong:\
resultName = operator (*(unsigned long long *)value.pointer); break;\
case OCTypeBOOL:\
resultName = operator (*(BOOL *)value.pointer); break;\
case OCTypeChar:\
resultName = operator (*(char *)value.pointer); break;\
case OCTypeShort:\
resultName = operator (*(short *)value.pointer); break;\
case OCTypeInt:\
resultName = operator (*(int *)value.pointer); break;\
case OCTypeLong:\
resultName = operator (*(long *)value.pointer); break;\
case OCTypeLongLong:\
resultName = operator (*(long long *)value.pointer); break;\
case OCTypeFloat:\
resultName = operator (*(float *)value.pointer); break;\
case OCTypeDouble:\
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
    case OCTypeObject:\
    resultName = operator (*(__strong id *)value.pointer); break;\
    case OCTypeSEL:\
    resultName = operator (*(SEL *)value.pointer); break;\
    case OCTypeClass:\
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
case OCTypeUChar:\
BoxBinaryExecute(unsigned char,leftValue,operator,rightValue)\
case OCTypeUShort:\
BoxBinaryExecute(unsigned short,leftValue,operator,rightValue)\
case OCTypeUInt:\
BoxBinaryExecute(unsigned int,leftValue,operator,rightValue)\
case OCTypeULong:\
BoxBinaryExecute(unsigned long,leftValue,operator,rightValue)\
case OCTypeULongLong:\
BoxBinaryExecute(unsigned long long,leftValue,operator,rightValue)\
case OCTypeBOOL:\
BoxBinaryExecute(BOOL,leftValue,operator,rightValue)\
case OCTypeChar:\
BoxBinaryExecute(char,leftValue,operator,rightValue)\
case OCTypeShort:\
BoxBinaryExecute(short,leftValue,operator,rightValue)\
case OCTypeInt:\
BoxBinaryExecute(int,leftValue,operator,rightValue)\
case OCTypeLong:\
BoxBinaryExecute(long,leftValue,operator,rightValue)\
case OCTypeLongLong:\
BoxBinaryExecute(long long,leftValue,operator,rightValue)\
default:\
break;\
}

#define BinaryExecuteFloat(leftValue,operator,rightValue,resultValue)\
switch (leftValue.type) {\
case OCTypeFloat:\
BoxBinaryExecute(float,leftValue,operator,rightValue)\
case OCTypeDouble:\
BoxBinaryExecute(double,leftValue,operator,rightValue)\
default:\
break;\
}

#define LogicBinaryOperatorExecute(leftValue,operator,rightValue)\
BOOL logicResultValue = NO;\
do{\
    switch (leftValue.type) {\
    case OCTypeUChar:\
    logicResultValue = BinaryExecute(unsigned char,leftValue,operator,rightValue)\
    case OCTypeUShort:\
    logicResultValue = BinaryExecute(unsigned short,leftValue,operator,rightValue)\
    case OCTypeUInt:\
    logicResultValue = BinaryExecute(unsigned int,leftValue,operator,rightValue)\
    case OCTypeULong:\
    logicResultValue = BinaryExecute(unsigned long,leftValue,operator,rightValue)\
    case OCTypeULongLong:\
    logicResultValue = BinaryExecute(unsigned long long,leftValue,operator,rightValue)\
    case OCTypeBOOL:\
    logicResultValue = BinaryExecute(BOOL,leftValue,operator,rightValue)\
    case OCTypeChar:\
    logicResultValue = BinaryExecute(char,leftValue,operator,rightValue)\
    case OCTypeShort:\
    logicResultValue = BinaryExecute(short,leftValue,operator,rightValue)\
    case OCTypeInt:\
    logicResultValue = BinaryExecute(int,leftValue,operator,rightValue)\
    case OCTypeLong:\
    logicResultValue = BinaryExecute(long,leftValue,operator,rightValue)\
    case OCTypeLongLong:\
    logicResultValue = BinaryExecute(long long,leftValue,operator,rightValue)\
    case OCTypeFloat:\
    logicResultValue = BinaryExecute(float,leftValue,operator,rightValue)\
    case OCTypeDouble:\
    logicResultValue = BinaryExecute(double,leftValue,operator,rightValue)\
    case OCTypeObject:\
    logicResultValue = ( (*(__strong id *)leftValue.pointer) operator (*(__strong id *)rightValue.pointer) ); break;\
    case OCTypeSEL:\
    logicResultValue = BinaryExecute(SEL,leftValue,operator,rightValue)\
    case OCTypeClass:\
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
    case OCTypeUChar:\
    target.uCharValue = from.uCharValue; break;\
    case OCTypeUShort:\
    target.uShortValue = from.uShortValue; break;\
    case OCTypeUInt:\
    target.uIntValue = from.uIntValue; break;\
    case OCTypeULong:\
    target.uLongValue = from.uLongValue; break;\
    case OCTypeULongLong:\
    target.uLongLongValue = from.uLongLongValue; break;\
    case OCTypeBOOL:\
    target.boolValue = from.boolValue; break;\
    case OCTypeChar:\
    target.charValue = from.charValue; break;\
    case OCTypeShort:\
    target.shortValue = from.shortValue; break;\
    case OCTypeInt:\
    target.intValue = from.intValue; break;\
    case OCTypeLong:\
    target.longValue = from.longValue; break;\
    case OCTypeLongLong:\
    target.longLongValue = from.longLongValue; break;\
    case OCTypeFloat:\
    target.floatValue = from.floatValue; break;\
    case OCTypeDouble:\
    target.doubleValue = from.doubleValue; break;\
    case OCTypeObject:\
    target.objectValue = from.objectValue; break;\
    case OCTypeSEL:\
    target.selValue = from.selValue; break;\
    case OCTypeClass:\
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
@property (assign,nonatomic,readonly)OCType type;
@property (strong,nonatomic)NSString *typeName;
@property (assign,nonatomic)NSInteger pointerCount;
@property (nonatomic,assign)const char* typeEncode;
@property (nonatomic,assign, nullable)void *pointer;
- (void)setPointerWithNoCopy:(void *)pointer;
- (void)setDefaultValue;
- (BOOL)isBlockValue;

+ (instancetype)defaultValueWithTypeEncoding:(const char *)typeEncoding;
+ (instancetype)valueWithTypeEncode:(const char *)typeEncode pointer:(nullable void *)pointer;
- (instancetype)initTypeEncode:(const char *)tyepEncode pointer:(nullable void *)pointer;

- (void)writePointer:(void *)pointer typeEncode:(const char *)typeEncode;
- (void)setTypeInfoWithValue:(MFValue *)value;

- (void)assignFrom:(MFValue *)src;
- (void)setTypeBySearchInTypeSymbolTable;

- (BOOL)isPointer;
- (BOOL)isSubtantial;
- (BOOL)isInteger;
- (BOOL)isFloat;
- (BOOL)isObject;
- (NSUInteger)memerySize;
- (MFValue *)subscriptGetWithIndex:(MFValue *)index;
- (void)subscriptSetValue:(MFValue *)value index:(MFValue *)index;
@end

@interface MFValue (Struct)
- (BOOL)isStruct;
- (BOOL)isStructPointer;
- (BOOL)isStructValueOrPointer;
- (BOOL)isHFAStruct;
- (NSUInteger)structLayoutFieldCount;
- (void)setFieldWithValue:(MFValue *)value forKey:(NSString *)key;
- (MFValue *)fieldForKey:(NSString *)key;
- (MFValue *)fieldNoCopyForKey:(NSString *)key;
- (MFValue *)getResutlInPointer;
- (void)enumerateStructFieldsUsingBlock:(void (^)(MFValue *field, NSUInteger idx, BOOL *stop))block;
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
@property (nonatomic, nullable, readonly) char *cStringValue;

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
