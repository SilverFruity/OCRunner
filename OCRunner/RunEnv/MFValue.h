//
//  MFValue .h
//  MangoFix
//
//  Created by jerry.yong on 2018/2/28.
//  Copyright © 2018年 yongpengliang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RunnerClasses+Execute.h"
#import <oc2mangoLib/ocHandleTypeEncode.h>

#define START_BOX \
ORCaculateValue cal_result;\

#define END_BOX(result)\
result.typeEncode = cal_result.typeEncode;\
result->realBaseValue = cal_result.box;\

#define PrefixUnaryExecuteInt(operator,value)\
cal_result.typeEncode = value.typeEncode;\
switch (value.type) {\
case OCTypeUChar:\
cal_result.box.uCharValue = (operator *(unsigned char *)value.pointer); break;\
case OCTypeUShort:\
cal_result.box.uShortValue = (operator *(unsigned short *)value.pointer); break;\
case OCTypeUInt:\
cal_result.box.uIntValue = (operator *(unsigned int *)value.pointer); break;\
case OCTypeULong:\
cal_result.box.uLongValue = (operator *(unsigned long *)value.pointer); break;\
case OCTypeULongLong:\
cal_result.box.uLongLongValue = (operator *(unsigned long long *)value.pointer); break;\
case OCTypeBOOL:\
cal_result.box.boolValue = (operator *(BOOL *)value.pointer); break;\
case OCTypeChar:\
cal_result.box.charValue = (operator *(char *)value.pointer); break;\
case OCTypeShort:\
cal_result.box.charValue = (operator *(short *)value.pointer); break;\
case OCTypeInt:\
cal_result.box.intValue = (operator *(int *)value.pointer); break;\
case OCTypeLong:\
cal_result.box.longValue = (operator *(long *)value.pointer); break;\
case OCTypeLongLong:\
cal_result.box.longlongValue = (operator *(long long *)value.pointer); break;\
default:\
break;\
}\

#define PrefixUnaryExecuteFloat(operator,value)\
cal_result.typeEncode = value.typeEncode;\
switch (value.type) {\
case OCTypeFloat:\
cal_result.box.floatValue = (operator *(float *)value.pointer); break;\
case OCTypeDouble:\
cal_result.box.doubleValue = (operator *(double *)value.pointer); break;\
default:\
break;\
}\

#define SuffixUnaryExecuteInt(operator,value)\
cal_result.typeEncode = value.typeEncode;\
switch (value.type) {\
case OCTypeUChar:\
cal_result.box.uCharValue = ((*(unsigned char *)value.pointer) operator); break;\
case OCTypeUShort:\
cal_result.box.uShortValue = ((*(unsigned short *)value.pointer) operator); break;\
case OCTypeUInt:\
cal_result.box.uIntValue = ((*(unsigned int *)value.pointer) operator); break;\
case OCTypeULong:\
cal_result.box.uLongValue = ((*(unsigned long *)value.pointer) operator); break;\
case OCTypeULongLong:\
cal_result.box.uLongLongValue = ((*(unsigned long long *)value.pointer) operator); break;\
case OCTypeBOOL:\
cal_result.box.boolValue = ((*(BOOL *)value.pointer) operator); break;\
case OCTypeChar:\
cal_result.box.charValue = ((*(char *)value.pointer) operator); break;\
case OCTypeShort:\
cal_result.box.shortValue = ((*(short *)value.pointer) operator); break;\
case OCTypeInt:\
cal_result.box.intValue = ((*(int *)value.pointer) operator); break;\
case OCTypeLong:\
cal_result.box.longValue = ((*(long *)value.pointer) operator); break;\
case OCTypeLongLong:\
cal_result.box.longlongValue = ((*(long long *)value.pointer) operator); break;\
default:\
break;\
}\


#define SuffixUnaryExecuteFloat(operator,value)\
cal_result.typeEncode = value.typeEncode;\
switch (value.type) {\
case OCTypeFloat:\
cal_result.box.floatValue = ((*(float *)value.pointer) operator); break;\
case OCTypeDouble:\
cal_result.box.doubleValue = ((*(double *)value.pointer) operator); break;\
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

#define BinaryExecute(value_type,leftValue,operator,rightValue)\
( (*(value_type *)leftValue.pointer) operator (*(value_type *)rightValue.pointer) ); break;

#define BinaryExecuteInt(leftValue,operator,rightValue)\
cal_result.typeEncode = leftValue.typeEncode;\
switch (leftValue.type) {\
case OCTypeUChar:\
cal_result.box.uCharValue = BinaryExecute(unsigned char,leftValue,operator,rightValue)\
case OCTypeUShort:\
cal_result.box.uShortValue = BinaryExecute(unsigned short,leftValue,operator,rightValue)\
case OCTypeUInt:\
cal_result.box.uIntValue = BinaryExecute(unsigned int,leftValue,operator,rightValue)\
case OCTypeULong:\
cal_result.box.uLongValue = BinaryExecute(unsigned long,leftValue,operator,rightValue)\
case OCTypeULongLong:\
cal_result.box.uLongLongValue = BinaryExecute(unsigned long long,leftValue,operator,rightValue)\
case OCTypeBOOL:\
cal_result.box.boolValue = BinaryExecute(BOOL,leftValue,operator,rightValue)\
case OCTypeChar:\
cal_result.box.charValue = BinaryExecute(char,leftValue,operator,rightValue)\
case OCTypeShort:\
cal_result.box.charValue = BinaryExecute(short,leftValue,operator,rightValue)\
case OCTypeInt:\
cal_result.box.intValue = BinaryExecute(int,leftValue,operator,rightValue)\
case OCTypeLong:\
cal_result.box.longValue = BinaryExecute(long,leftValue,operator,rightValue)\
case OCTypeLongLong:\
cal_result.box.longlongValue = BinaryExecute(long long,leftValue,operator,rightValue)\
default:\
break;\
}

#define CalculateExecuteSaveInBox(value_type,leftValue,operator,rightValue)\
cal_result.box.value_type = leftValue.value_type operator rightValue.value_type

#define CalculateExecuteRight(value_type,leftValue,operator,rightValue)\
leftValue.value_type operator rightValue.value_type

#define CalculateExecute(leftValue,operator,rightValue)\
OCType result_type = leftValue.type;\
cal_result.typeEncode = leftValue.typeEncode;\
if (leftValue.type != rightValue.type\
    && (leftValue.type == OCTypeFloat || leftValue.type == OCTypeDouble\
    || rightValue.type == OCTypeFloat || rightValue.type == OCTypeDouble )){\
    result_type = OCTypeDouble;\
    cal_result.typeEncode = OCTypeStringDouble;\
}\
switch (result_type) {\
case OCTypeUChar:\
CalculateExecuteSaveInBox(uCharValue,leftValue,operator,rightValue); break;\
case OCTypeUShort:\
CalculateExecuteSaveInBox(uShortValue,leftValue,operator,rightValue); break;\
case OCTypeUInt:\
CalculateExecuteSaveInBox(uIntValue,leftValue,operator,rightValue); break;\
case OCTypeULong:\
CalculateExecuteSaveInBox(uLongValue,leftValue,operator,rightValue); break;\
case OCTypeULongLong:\
CalculateExecuteSaveInBox(uLongLongValue,leftValue,operator,rightValue); break;\
case OCTypeBOOL:\
CalculateExecuteSaveInBox(boolValue,leftValue,operator,rightValue); break;\
case OCTypeChar:\
CalculateExecuteSaveInBox(charValue,leftValue,operator,rightValue); break;\
case OCTypeShort:\
CalculateExecuteSaveInBox(shortValue,leftValue,operator,rightValue); break;\
case OCTypeInt:\
CalculateExecuteSaveInBox(intValue,leftValue,operator,rightValue); break;\
case OCTypeLong:\
CalculateExecuteSaveInBox(longValue,leftValue,operator,rightValue); break;\
case OCTypeLongLong:\
CalculateExecuteSaveInBox(longlongValue,leftValue,operator,rightValue); break;\
case OCTypeFloat:\
CalculateExecuteSaveInBox(floatValue,leftValue,operator,rightValue); break;\
case OCTypeDouble:\
CalculateExecuteSaveInBox(doubleValue,leftValue,operator,rightValue); break;\
default:\
break;\
}


#define LogicBinaryOperatorExecute(leftValue,operator,rightValue)\
BOOL logicResultValue = NO;\
do{\
    OCType compare_type = leftValue.type;\
    if (leftValue.type != rightValue.type\
        && (leftValue.type == OCTypeFloat || leftValue.type == OCTypeDouble\
        || rightValue.type == OCTypeFloat || rightValue.type == OCTypeDouble )){\
        compare_type = OCTypeDouble;\
    }\
    switch (compare_type) {\
    case OCTypeUChar:\
        logicResultValue = leftValue.uCharValue operator rightValue.uCharValue;  break;\
    case OCTypeUShort:\
        logicResultValue = leftValue.uShortValue operator rightValue.uShortValue;  break;\
    case OCTypeUInt:\
        logicResultValue = leftValue.uIntValue operator rightValue.uIntValue;  break;\
    case OCTypeULong:\
        logicResultValue = leftValue.uLongValue operator rightValue.uLongValue;  break;\
    case OCTypeULongLong:\
        logicResultValue = leftValue.uLongLongValue operator rightValue.uLongLongValue;  break;\
    case OCTypeBOOL:\
        logicResultValue = leftValue.boolValue operator rightValue.boolValue;  break;\
    case OCTypeChar:\
        logicResultValue = leftValue.charValue operator rightValue.charValue;  break;\
    case OCTypeShort:\
        logicResultValue = leftValue.shortValue operator rightValue.shortValue;  break;\
    case OCTypeInt:\
        logicResultValue = leftValue.intValue operator rightValue.intValue;  break;\
    case OCTypeLong:\
        logicResultValue = leftValue.longValue operator rightValue.longValue;  break;\
    case OCTypeLongLong:\
        logicResultValue = leftValue.longlongValue operator rightValue.longlongValue;  break;\
    case OCTypeFloat:\
        logicResultValue = leftValue.floatValue operator rightValue.floatValue;  break;\
    case OCTypeDouble:\
        logicResultValue = leftValue.doubleValue operator rightValue.doubleValue;  break;\
    case OCTypeObject:\
        logicResultValue = BinaryExecute(__strong id,leftValue,operator,rightValue); break;\
    case OCTypeSEL:\
        logicResultValue = BinaryExecute(SEL,leftValue,operator,rightValue);  break;\
    case OCTypeClass:\
        logicResultValue = BinaryExecute(Class,leftValue,operator,rightValue);  break;\
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

typedef struct{
    MFRealBaseValue box;
    const char *typeEncode;
}ORCaculateValue;

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
    @protected
    __strong id _strongObjectValue;
    __weak id _weakObjectValue;
}
@property (assign, nonatomic)MFStatementResultType resultType;
@property (assign,nonatomic)DeclarationModifier modifier;
@property (assign,nonatomic)OCBaseTypeString typeString;
@property (assign,nonatomic)OCType type;
@property (strong,nonatomic)NSString *typeName;
@property (assign,nonatomic)NSInteger pointerCount;
@property (nonatomic,assign)const char* typeEncode;
@property (nonatomic,assign, nullable)void *pointer;
- (void)setValuePointerWithNoCopy:(void *)pointer;
- (void)setDefaultValue;
- (BOOL)isBlockValue;

+ (instancetype)defaultValueWithTypeEncoding:(const char *)typeEncoding;
+ (instancetype)valueWithTypeEncode:(const char *)typeEncode pointer:(nullable void *)pointer;
+ (instancetype)valueWithORCaculateValue:(ORCaculateValue)value;
- (instancetype)initTypeEncode:(const char *)tyepEncode pointer:(nullable void *)pointer;

- (void)writePointer:(void *)pointer typeEncode:(const char *)typeEncode;
- (void)setTypeInfoWithValue:(MFValue *)value;

- (void)assignWithNewValue:(MFValue *)src;

- (BOOL)isPointer;
- (BOOL)isSubtantial;
- (BOOL)isInteger;
- (BOOL)isFloat;
- (BOOL)isObject;
- (NSUInteger)memerySize;
- (MFValue *)subscriptGetWithIndex:(MFValue *)index;
- (void)subscriptSetValue:(MFValue *)value index:(MFValue *)index;

///  仅仅针对函数指针变量的调用，记录签名信息， int (*xxx)(int a ) = &x;  xxxx();
@property (nonatomic,strong)ORFunctionDeclNode *funDecl;
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

@interface MFValue (Union)
- (void)setUnionFieldWithValue:(MFValue *)value forKey:(NSString *)key;
- (MFValue *)unionFieldForKey:(NSString *)key;
@end

@interface MFValue  (CArray)
- (MFValue *)cArraySubscriptGetValueWithIndex:(MFValue *)index;
- (void)cArraySubscriptSetValue:(MFValue *)value index:(MFValue *)index;
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
@property (assign, nonatomic, readonly) long long longlongValue;

@property (assign, nonatomic, readonly) BOOL boolValue;

@property (assign, nonatomic, readonly) float floatValue;
@property (assign, nonatomic, readonly) double doubleValue;

@property (nonatomic, nullable, readonly) id objectValue;
@property (nonatomic, nullable, readonly) void *classValue;
@property (nonatomic, nullable, readonly) SEL selValue;
@property (nonatomic, nullable, readonly) char *cStringValue;
+ (instancetype)nullValue;
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
+ (instancetype)valueWithUnownedObject:(nullable id)objValue;
+ (instancetype)valueWithWeakObject:(nullable id)objValue;
+ (instancetype)valueWithBlock:(nullable id)blockValue;
+ (instancetype)valueWithClass:(nullable Class)clazzValue;
+ (instancetype)valueWithSEL:(SEL)selValue;
+ (instancetype)valueWithCString:(char *)pointerValue;
+ (instancetype)valueWithPointer:(nullable void *)pointerValue;
@end
NS_ASSUME_NONNULL_END
