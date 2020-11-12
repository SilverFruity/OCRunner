//
//  MFValue .h
//  MangoFix
//
//  Created by jerry.yong on 2018/2/28.
//  Copyright © 2018年 yongpengliang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RunnerClasses+Execute.h"
#import "ORHandleTypeEncode.h"

#define START_BOX \
MFRealBaseValue box = { 0 };\

#define END_BOX(result)\
result->realBaseValue = box;\

#define PrefixUnaryExecuteInt(operator,value)\
switch (value.type) {\
case OCTypeUChar:\
box.uCharValue = (operator *(unsigned char *)value.pointer); break;\
case OCTypeUShort:\
box.uShortValue = (operator *(unsigned short *)value.pointer); break;\
case OCTypeUInt:\
box.uIntValue = (operator *(unsigned int *)value.pointer); break;\
case OCTypeULong:\
box.uLongValue = (operator *(unsigned long *)value.pointer); break;\
case OCTypeULongLong:\
box.uLongLongValue = (operator *(unsigned long long *)value.pointer); break;\
case OCTypeBOOL:\
box.boolValue = (operator *(BOOL *)value.pointer); break;\
case OCTypeChar:\
box.charValue = (operator *(char *)value.pointer); break;\
case OCTypeShort:\
box.charValue = (operator *(short *)value.pointer); break;\
case OCTypeInt:\
box.intValue = (operator *(int *)value.pointer); break;\
case OCTypeLong:\
box.longValue = (operator *(long *)value.pointer); break;\
case OCTypeLongLong:\
box.longlongValue = (operator *(long long *)value.pointer); break;\
default:\
break;\
}\

#define PrefixUnaryExecuteFloat(operator,value)\
switch (value.type) {\
case OCTypeFloat:\
box.floatValue = (operator *(float *)value.pointer); break;\
case OCTypeDouble:\
box.doubleValue = (operator *(double *)value.pointer); break;\
default:\
break;\
}\

#define SuffixUnaryExecuteInt(operator,value)\
switch (value.type) {\
case OCTypeUChar:\
box.uCharValue = ((*(unsigned char *)value.pointer) operator); break;\
case OCTypeUShort:\
box.uShortValue = ((*(unsigned short *)value.pointer) operator); break;\
case OCTypeUInt:\
box.uIntValue = ((*(unsigned int *)value.pointer) operator); break;\
case OCTypeULong:\
box.uLongValue = ((*(unsigned long *)value.pointer) operator); break;\
case OCTypeULongLong:\
box.uLongLongValue = ((*(unsigned long long *)value.pointer) operator); break;\
case OCTypeBOOL:\
box.boolValue = ((*(BOOL *)value.pointer) operator); break;\
case OCTypeChar:\
box.charValue = ((*(char *)value.pointer) operator); break;\
case OCTypeShort:\
box.shortValue = ((*(short *)value.pointer) operator); break;\
case OCTypeInt:\
box.intValue = ((*(int *)value.pointer) operator); break;\
case OCTypeLong:\
box.longValue = ((*(long *)value.pointer) operator); break;\
case OCTypeLongLong:\
box.longlongValue = ((*(long long *)value.pointer) operator); break;\
default:\
break;\
}\


#define SuffixUnaryExecuteFloat(operator,value)\
switch (value.type) {\
case OCTypeFloat:\
box.floatValue = ((*(float *)value.pointer) operator); break;\
case OCTypeDouble:\
box.doubleValue = ((*(double *)value.pointer) operator); break;\
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

#define BinaryExecuteInt(leftValue,operator,rightValue,resultValue)\
switch (leftValue.type) {\
case OCTypeUChar:\
box.uCharValue = BinaryExecute(unsigned char,leftValue,operator,rightValue)\
case OCTypeUShort:\
box.uShortValue = BinaryExecute(unsigned short,leftValue,operator,rightValue)\
case OCTypeUInt:\
box.uIntValue = BinaryExecute(unsigned int,leftValue,operator,rightValue)\
case OCTypeULong:\
box.uLongValue = BinaryExecute(unsigned long,leftValue,operator,rightValue)\
case OCTypeULongLong:\
box.uLongLongValue = BinaryExecute(unsigned long long,leftValue,operator,rightValue)\
case OCTypeBOOL:\
box.boolValue = BinaryExecute(BOOL,leftValue,operator,rightValue)\
case OCTypeChar:\
box.charValue = BinaryExecute(char,leftValue,operator,rightValue)\
case OCTypeShort:\
box.charValue = BinaryExecute(short,leftValue,operator,rightValue)\
case OCTypeInt:\
box.intValue = BinaryExecute(int,leftValue,operator,rightValue)\
case OCTypeLong:\
box.longValue = BinaryExecute(long,leftValue,operator,rightValue)\
case OCTypeLongLong:\
box.longlongValue = BinaryExecute(long long,leftValue,operator,rightValue)\
default:\
break;\
}

#define BinaryExecuteFloat(leftValue,operator,rightValue,resultValue)\
switch (leftValue.type) {\
case OCTypeFloat:\
box.floatValue = BinaryExecute(float,leftValue,operator,rightValue)\
case OCTypeDouble:\
box.doubleValue = BinaryExecute(double,leftValue,operator,rightValue)\
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

typedef union{
    BOOL boolValue;
    char charValue;
    short shortValue;
    int intValue;
    long longValue;
    long long longlongValue;
    unsigned char uCharValue;
    unsigned short uShortValue;
    unsigned int uIntValue;
    unsigned long uLongValue;
    unsigned long long uLongLongValue;
    float floatValue;
    double doubleValue;
    void *pointerValue;
}MFRealBaseValue;

typedef struct {
    OCType type;
    char end;
}OCBaseTypeString;

ORTypeVarPair *typePairWithTypeEncode(const char *tyepEncode);

extern BOOL MFStatementResultTypeIsReturn(MFStatementResultType type);

@interface MFValue : NSObject <NSCopying>
{
    @public
    MFRealBaseValue realBaseValue;
}
@property (assign, nonatomic)MFStatementResultType resultType;
@property (assign,nonatomic)DeclarationModifier modifier;
@property (assign,nonatomic)OCBaseTypeString typeString;
@property (assign,nonatomic)OCType type;
@property (strong,nonatomic)NSString *typeName;
@property (assign,nonatomic)NSInteger pointerCount;
@property (nonatomic,assign)const char* typeEncode;
@property (nonatomic,assign, nullable)void *pointer;
- (void)setStructPointerWithNoCopy:(void *)pointer;
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

///  仅仅针对函数指针变量的调用，记录签名信息， int (*xxx)(int a ) = &x;  xxxx();
@property (nonatomic,strong)ORTypeVarPair *funPair;
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
