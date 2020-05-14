//
//  MFValue .h
//  MangoFix
//
//  Created by jerry.yong on 2018/2/28.
//  Copyright © 2018年 yongpengliang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MFDeclarationModifier.h"
#import "RunnerClasses.h"
// FIXME: 转码问题，int->char 等等， 设置一个基础类型，同时设置所有类型。导致 testBlockCopyValue 测试不能通过。
#define ValueDefineWithSuffix(suffix)\
unsigned char uCharValue##suffix = 0;\
unsigned short uShortValue##suffix = 0;\
unsigned int uIntValue##suffix = 0;\
unsigned long uLongValue##suffix = 0;\
unsigned long long uLLongValue##suffix = 0;\
BOOL boolValue##suffix = 0;\
char charValue##suffix = 0;\
short shortValue##suffix = 0;\
int intValue##suffix = 0;\
long longValue##suffix = 0;\
long long lLongValue##suffix = 0;\
float floatValue##suffix = 0;\
float doubleValue##suffix = 0;\
id objectValue##suffix = nil;\
SEL selValue##suffix = 0;\
Class classValue##suffix = nil;\
void *pointerValue##suffix = nil;\

#define GetPointerValue(suffix, target)\
ValueDefineWithSuffix(suffix)\
do {\
    if (currentValue.typePair.var.ptCount > 1) {\
        pointerValue##suffix = *(void **)target.pointerValue;\
        break;\
    }\
    switch (target.typePair.type.type) {\
        case TypeUChar:\
            uCharValue##suffix = *(unsigned char *)target.pointerValue; break;\
        case TypeUShort:\
            uShortValue##suffix = *(unsigned short *)target.pointerValue; break;\
        case TypeUInt:\
            uIntValue##suffix = *(unsigned int *)target.pointerValue; break;\
        case TypeULong:\
            uLongValue##suffix = *(unsigned long *)target.pointerValue; break;\
        case TypeULongLong:\
            uLLongValue##suffix = *(unsigned long long *)target.pointerValue; break;\
        case TypeBOOL:\
            boolValue##suffix = *(BOOL *)target.pointerValue; break;\
        case TypeChar:\
            charValue##suffix = *(char *)target.pointerValue; break;\
        case TypeShort:\
            shortValue##suffix = *(short *)target.pointerValue; break;\
        case TypeInt:\
            intValue##suffix = *(int *)target.pointerValue; break;\
        case TypeLong:\
            longValue##suffix = *(long *)target.pointerValue; break;\
        case TypeLongLong:\
            lLongValue##suffix = *(long long *)target.pointerValue; break;\
        case TypeFloat:\
            floatValue##suffix = *(double *)target.pointerValue; break;\
        case TypeDouble:\
            doubleValue##suffix = *(double *)target.pointerValue; break;\
        case TypeId:\
        case TypeObject:\
        case TypeBlock:{\
            objectValue##suffix = *(__strong id *)target.pointerValue;\
            break;\
        }\
        case TypeSEL:\
            selValue##suffix = *(SEL *)target.pointerValue; break;\
            break;\
        case TypeClass:\
            classValue##suffix = *(Class *)target.pointerValue; break;\
            break;\
        default:\
            break;\
    }\
} while (0);

#define ValueDefineWithMFValue(suffix,target)\
ValueDefineWithSuffix(suffix)\
do {\
    if (target.isPointer) {\
        pointerValue##suffix = target.pointerValue;\
        break;\
    }\
    switch (target.typePair.type.type) {\
        case TypeUChar:\
            uCharValue##suffix = target.uCharValue; break;\
        case TypeUShort:\
            uShortValue##suffix = target.uShortValue; break;\
        case TypeUInt:\
            uIntValue##suffix = target.uIntValue; break;\
        case TypeULong:\
            uLongValue##suffix = target.uLongValue; break;\
        case TypeULongLong:\
            uLLongValue##suffix = target.uLongLongValue; break;\
        case TypeBOOL:\
            boolValue##suffix = target.boolValue; break;\
        case TypeChar:\
            charValue##suffix = target.charValue; break;\
        case TypeShort:\
            shortValue##suffix = target.shortValue; break;\
        case TypeInt:\
            intValue##suffix = target.intValue; break;\
        case TypeLong:\
            longValue##suffix = target.longValue; break;\
        case TypeLongLong:\
            lLongValue##suffix = target.longLongValue; break;\
        case TypeFloat:\
            floatValue##suffix = target.floatValue; break;\
        case TypeDouble:\
            doubleValue##suffix = target.doubleValue; break;\
        case TypeId:\
        case TypeObject:\
        case TypeBlock:{\
            objectValue##suffix = target.objectValue;\
            break;\
        }\
        case TypeSEL:\
            selValue##suffix = target.selValue; break;\
            break;\
        case TypeClass:\
            classValue##suffix = target.classValue; break;\
            break;\
        default:\
            break;\
    }\
} while (0);



#define HoleValue(valueType, suffix, target)\
valueType holeValue_##valueType##suffix  = 0;\
switch (target.typePair.type.type) {\
    case TypeUChar:\
        holeValue_##valueType##suffix = uCharValue##suffix; break;\
    case TypeUShort:\
        holeValue_##valueType##suffix  = uShortValue##suffix; break;\
    case TypeUInt:\
        holeValue_##valueType##suffix  = uIntValue##suffix; break;\
    case TypeULong:\
        holeValue_##valueType##suffix  = uLongValue##suffix; break;\
    case TypeULongLong:\
        holeValue_##valueType##suffix  = uLLongValue##suffix; break;\
    case TypeBOOL:\
        holeValue_##valueType##suffix  = boolValue##suffix; break;\
    case TypeChar:\
        holeValue_##valueType##suffix  = charValue##suffix; break;\
    case TypeShort:\
        holeValue_##valueType##suffix  = shortValue##suffix; break;\
    case TypeInt:\
        holeValue_##valueType##suffix  = intValue##suffix; break;\
    case TypeLong:\
        holeValue_##valueType##suffix  = longValue##suffix; break;\
    case TypeLongLong:\
        holeValue_##valueType##suffix  = lLongValue##suffix; break;\
    case TypeFloat:\
        holeValue_##valueType##suffix  = floatValue##suffix; break;\
    case TypeDouble:\
        holeValue_##valueType##suffix  = doubleValue##suffix; break;\
    default:\
        break;\
}

#define HoleUCharValue(suffix, target) HoleValue(uint8_t, suffix, target)
#define HoleUShortValue(suffix, target) HoleValue(uint16_t, suffix, target)
#define HoleUIntValue(suffix, target) HoleValue(uint32_t, suffix, target)
#define HoleULongValue(suffix, target) HoleValue(uint64_t, suffix, target)

#define HoleCharValue(suffix, target) HoleValue(int8_t, suffix, target)
#define HoleShortValue(suffix, target) HoleValue(int16_t, suffix, target)
#define HoleIntValue(suffix, target) HoleValue(int32_t, suffix, target)
#define HoleLongValue(suffix, target) HoleValue(int64_t, suffix, target)

#define HoleIntegerValue(suffix, target) HoleLongValue(suffix, target)
#define HoleUIntegerValue(suffix, target) HoleULongValue(suffix, target)

#define HoleFloatValue(suffix, target) HoleValue(float, suffix, target)
#define HoleDoubleValue(suffix, target) HoleValue(double, suffix, target)


#define PrefixUnaryExecuteInt(operator,value,resultValue)\
switch (value.typePair.type.type) {\
case TypeUChar:\
resultValue.uCharValue = (operator value.uCharValue); break;\
case TypeUShort:\
resultValue.uShortValue = (operator value.uShortValue); break;\
case TypeUInt:\
resultValue.uIntValue = (operator value.uIntValue); break;\
case TypeULong:\
resultValue.uLongValue = (operator value.uLongValue); break;\
case TypeULongLong:\
resultValue.uLongLongValue = (operator value.uLongLongValue); break;\
case TypeBOOL:\
resultValue.boolValue = (operator value.boolValue); break;\
case TypeChar:\
resultValue.charValue = (operator value.charValue); break;\
case TypeShort:\
resultValue.shortValue = (operator value.shortValue); break;\
case TypeInt:\
resultValue.intValue = (operator value.intValue); break;\
case TypeLong:\
resultValue.longValue = (operator value.longValue); break;\
case TypeLongLong:\
resultValue.longLongValue = (operator value.longLongValue); break;\
default:\
break;\
}

#define PrefixUnaryExecuteFloat(operator,value,resultValue)\
switch (value.typePair.type.type) {\
case TypeFloat:\
resultValue.floatValue = (operator value.floatValue); break;\
case TypeDouble:\
resultValue.doubleValue = (operator value.doubleValue); break;\
default:\
break;\
}

#define SuffixUnaryExecuteInt(operator,value,resultValue)\
switch (value.typePair.type.type) {\
case TypeUChar:\
resultValue.uCharValue = (value.uCharValue operator); break;\
case TypeUShort:\
resultValue.uShortValue = (value.uShortValue operator); break;\
case TypeUInt:\
resultValue.uIntValue = (value.uIntValue operator); break;\
case TypeULong:\
resultValue.uLongValue = (value.uLongValue operator); break;\
case TypeULongLong:\
resultValue.uLongLongValue = (value.uLongLongValue operator); break;\
case TypeBOOL:\
resultValue.boolValue = (value.boolValue operator); break;\
case TypeChar:\
resultValue.charValue = (value.charValue operator); break;\
case TypeShort:\
resultValue.shortValue = (value.shortValue operator); break;\
case TypeInt:\
resultValue.intValue = (value.intValue operator); break;\
case TypeLong:\
resultValue.longValue = (value.longValue operator); break;\
case TypeLongLong:\
resultValue.longLongValue = (value.longLongValue operator); break;\
default:\
break;\
}

#define SuffixUnaryExecuteFloat(operator,value,resultValue)\
switch (value.typePair.type.type) {\
case TypeFloat:\
resultValue.floatValue = (value.floatValue operator); break;\
case TypeDouble:\
resultValue.doubleValue = (value.doubleValue operator); break;\
default:\
break;\
}

#define UnaryExecuteBaseType(resutlType,resultName,operator,value)\
resutlType resultName;\
switch (value.typePair.type.type) {\
case TypeUChar:\
resultName = operator (value.uCharValue); break;\
case TypeUShort:\
resultName = operator (value.uShortValue); break;\
case TypeUInt:\
resultName = operator (value.uIntValue); break;\
case TypeULong:\
resultName = operator (value.uLongValue); break;\
case TypeULongLong:\
resultName = operator (value.uLongLongValue); break;\
case TypeBOOL:\
resultName = operator (value.boolValue); break;\
case TypeChar:\
resultName = operator (value.charValue); break;\
case TypeShort:\
resultName = operator (value.shortValue); break;\
case TypeInt:\
resultName = operator (value.intValue); break;\
case TypeLong:\
resultName = operator (value.longValue); break;\
case TypeLongLong:\
resultName = operator (value.longLongValue); break;\
case TypeFloat:\
resultName = operator (value.floatValue); break;\
case TypeDouble:\
resultName = operator (value.doubleValue); break;\
default:\
break;\
}


#define UnaryExecute(resutlType,resultName,operator,value)\
resutlType resultName;\
do{\
    if (value.isPointer) {\
        resultName = operator (value.pointerValue);\
        break;\
    }\
    UnaryExecuteBaseType(resutlType,resultName,operator,value)\
    switch (value.typePair.type.type) {\
    case TypeId:\
    case TypeObject:\
    case TypeBlock:\
    resultName = operator (value.objectValue); break;\
    case TypeSEL:\
    resultName = operator (value.selValue); break;\
    case TypeClass:\
    resultName = operator (value.classValue); break;\
    default:\
    break;\
    }\
}while(0)


#define BinaryExecuteInt(leftValue,operator,rightValue,resultValue)\
switch (leftValue.typePair.type.type) {\
case TypeUChar:\
resultValue.uCharValue = (leftValue.uCharValue operator rightValue.uCharValue); break;\
case TypeUShort:\
resultValue.uShortValue = (leftValue.uShortValue operator rightValue.uShortValue); break;\
case TypeUInt:\
resultValue.uIntValue = (leftValue.uIntValue operator rightValue.uIntValue); break;\
case TypeULong:\
resultValue.uLongValue = (leftValue.uLongValue operator rightValue.uLongValue); break;\
case TypeULongLong:\
resultValue.uLongLongValue = (leftValue.uLongLongValue operator rightValue.uLongLongValue); break;\
case TypeBOOL:\
resultValue.boolValue = (leftValue.boolValue operator rightValue.boolValue); break;\
case TypeChar:\
resultValue.charValue = (leftValue.charValue operator rightValue.charValue); break;\
case TypeShort:\
resultValue.shortValue = (leftValue.shortValue operator rightValue.shortValue); break;\
case TypeInt:\
resultValue.intValue = (leftValue.intValue operator rightValue.intValue); break;\
case TypeLong:\
resultValue.longValue = (leftValue.longValue operator rightValue.longValue); break;\
case TypeLongLong:\
resultValue.longLongValue = (leftValue.longLongValue operator rightValue.longLongValue); break;\
default:\
break;\
}

#define BinaryExecuteFloat(leftValue,operator,rightValue,resultValue)\
switch (leftValue.typePair.type.type) {\
case TypeFloat:\
resultValue.floatValue = (leftValue.floatValue operator rightValue.floatValue); break;\
case TypeDouble:\
resultValue.doubleValue = (leftValue.doubleValue operator rightValue.doubleValue); break;\
default:\
break;\
}

#define LogicBinaryOperatorExecute(leftValue,operator,rightValue)\
BOOL logicResultValue = NO;\
do{\
    if (leftValue.isPointer) {\
        logicResultValue= (leftValue.pointerValue operator rightValue.pointerValue);\
        break;\
    }\
    switch (leftValue.typePair.type.type) {\
    case TypeUChar:\
    logicResultValue = (leftValue.uCharValue operator rightValue.uCharValue); break;\
    case TypeUShort:\
    logicResultValue = (leftValue.uShortValue operator rightValue.uShortValue); break;\
    case TypeUInt:\
    logicResultValue = (leftValue.uIntValue operator rightValue.uIntValue); break;\
    case TypeULong:\
    logicResultValue = (leftValue.uLongValue operator rightValue.uLongValue); break;\
    case TypeULongLong:\
    logicResultValue = (leftValue.uLongLongValue operator rightValue.uLongLongValue); break;\
    case TypeBOOL:\
    logicResultValue = (leftValue.boolValue operator rightValue.boolValue); break;\
    case TypeChar:\
    logicResultValue = (leftValue.charValue operator rightValue.charValue); break;\
    case TypeShort:\
    logicResultValue = (leftValue.shortValue operator rightValue.shortValue); break;\
    case TypeInt:\
    logicResultValue = (leftValue.intValue operator rightValue.intValue); break;\
    case TypeLong:\
    logicResultValue = (leftValue.longValue operator rightValue.longValue); break;\
    case TypeLongLong:\
    logicResultValue = (leftValue.longLongValue operator rightValue.longLongValue); break;\
    case TypeFloat:\
    logicResultValue = (leftValue.floatValue operator rightValue.floatValue); break;\
    case TypeDouble:\
    logicResultValue = (leftValue.doubleValue operator rightValue.doubleValue); break;\
    case TypeId:\
    case TypeObject:\
    case TypeBlock:\
    logicResultValue = (leftValue.objectValue operator rightValue.objectValue); break;\
    case TypeSEL:\
    logicResultValue =  (leftValue.selValue operator rightValue.selValue); break;\
    case TypeClass:\
    logicResultValue =  (leftValue.classValue operator rightValue.classValue); break;\
    default:\
    break;\
    }\
}while(0)

#define MFValueSetValue(target,resultSuffix)\
do{\
    if (target.isPointer) {\
        target.pointerValue = pointerValue##resultSuffix;\
        break;\
    }\
    switch (target.typePair.type.type) {\
    case TypeUChar:\
    target.uCharValue = uCharValue##resultSuffix; break;\
    case TypeUShort:\
    target.uShortValue = uShortValue##resultSuffix; break;\
    case TypeUInt:\
    target.uIntValue = uIntValue##resultSuffix; break;\
    case TypeULong:\
    target.uLongValue = uLongValue##resultSuffix; break;\
    case TypeULongLong:\
    target.uLongLongValue = uLLongValue##resultSuffix; break;\
    case TypeBOOL:\
    target.boolValue = boolValue##resultSuffix; break;\
    case TypeChar:\
    target.charValue = charValue##resultSuffix; break;\
    case TypeShort:\
    target.shortValue = shortValue##resultSuffix; break;\
    case TypeInt:\
    target.intValue = intValue##resultSuffix; break;\
    case TypeLong:\
    target.longValue = longValue##resultSuffix; break;\
    case TypeLongLong:\
    target.longLongValue = lLongValue##resultSuffix; break;\
    case TypeFloat:\
    target.floatValue = floatValue##resultSuffix; break;\
    case TypeDouble:\
    target.doubleValue = doubleValue##resultSuffix; break;\
    case TypeId:\
    case TypeObject:\
    case TypeBlock:\
    target.objectValue = objectValue##resultSuffix; break;\
    case TypeSEL:\
    target.selValue = selValue##resultSuffix; break;\
    case TypeClass:\
    target.classValue = classValue##resultSuffix; break;\
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
extern BOOL MFStatementResultTypeIsReturn(MFStatementResultType type);
@interface MFValue : NSObject

@property (assign, nonatomic) MFStatementResultType resultType;
@property (assign, nonatomic) BOOL isReturn;
@property (assign, nonatomic) BOOL isContinue;
@property (assign, nonatomic) BOOL isBreak;
@property (assign, nonatomic) BOOL isNormal;

+ (instancetype)normalEnd;

@property (assign, nonatomic) unsigned char uCharValue;
@property (assign, nonatomic) unsigned short uShortValue;
@property (assign, nonatomic) unsigned int uIntValue;
@property (assign, nonatomic) unsigned long uLongValue;
@property (assign, nonatomic) unsigned long long uLongLongValue;

@property (assign, nonatomic) char charValue;
@property (assign, nonatomic) short shortValue;
@property (assign, nonatomic) int intValue;
@property (assign, nonatomic) long longValue;
@property (assign, nonatomic) long long longLongValue;

@property (assign, nonatomic) BOOL boolValue;

@property (assign, nonatomic) float floatValue;
@property (assign, nonatomic) double doubleValue;

@property (nonatomic,nullable) id objectValue;
@property (strong, nonatomic, nullable) Class classValue;
@property (assign, nonatomic, nullable) SEL selValue;
@property (assign, nonatomic, nullable) void *pointerValue;

@property (assign,nonatomic)MFDeclarationModifier modifier;
@property (strong,nonatomic)ORTypeVarPair *typePair;
- (void)setValueType:(TypeKind)type;
- (BOOL)isSubtantial;
- (BOOL)isObject;
- (BOOL)isMember;
- (BOOL)isBaseValue;
- (BOOL)isPointer;
- (MFValue *)subscriptGetWithIndex:(MFValue *)index;
- (void)subscriptSetValue:(MFValue *)value index:(MFValue *)index;
- (void)subscriptSetWithIndex:(MFValue *)index value:(MFValue *)value;

+ (instancetype)defaultValueWithTypeEncoding:(const char *)typeEncoding;
+ (instancetype)voidValueInstance;

+ (instancetype)valueInstanceWithBOOL:(BOOL)boolValue;
+ (instancetype)valueInstanceWithUChar:(unsigned char)uCharValue;
+ (instancetype)valueInstanceWithUShort:(unsigned short)uShortValue;
+ (instancetype)valueInstanceWithUInt:(unsigned int)uIntValue;
+ (instancetype)valueInstanceWithULong:(unsigned long)uLongValue;
+ (instancetype)valueInstanceWithULongLong:(unsigned long long)uLongLongValue;
+ (instancetype)valueInstanceWithChar:(char)charValue;
+ (instancetype)valueInstanceWithShort:(short)shortValue;
+ (instancetype)valueInstanceWithInt:(int)intValue;
+ (instancetype)valueInstanceWithLong:(long)longValue;
+ (instancetype)valueInstanceWithLongLong:(long long)longLongValue;
+ (instancetype)valueInstanceWithFloat:(float)floatValue;
+ (instancetype)valueInstanceWithDouble:(double)doubleValue;
+ (instancetype)valueInstanceWithObject:(nullable id)objValue;
+ (instancetype)valueInstanceWithBlock:(nullable id)blockValue;
+ (instancetype)valueInstanceWithClass:(nullable Class)clazzValue;
+ (instancetype)valueInstanceWithSEL:(SEL)selValue;
+ (instancetype)valueInstanceWithCstring:(nullable const char *)cstringValue;
+ (instancetype)valueInstanceWithPointer:(nullable void *)pointerValue;
+ (instancetype)valueInstanceWithStruct:(void *)structValue typeEncoding:(const char *)typeEncoding copyData:(BOOL)copyData;

- (instancetype)nsStringValue;
- (void *)valuePointer;

- (id)c2objectValue;
- (void *)c2pointerValue;
- (void)assignToCValuePointer:(void *)cvaluePointer typeEncoding:(const char *)typeEncoding;
- (instancetype)initWithCValuePointer:(void *)cValuePointer typeEncoding:(const char *)typeEncoding bridgeTransfer:(BOOL)bridgeTransfer;
@end
NS_ASSUME_NONNULL_END
