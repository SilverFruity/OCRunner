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
#define MFValueGetValueInPointer(resultValue, fromValue)\
do {\
    if (fromValue.typePair.var.ptCount > 1) {\
        resultValue.pointerValue = *(void **)fromValue.pointerValue;\
        break;\
    }\
    switch (fromValue.typePair.type.type) {\
        case TypeUChar:\
            resultValue.uCharValue = *(unsigned char *)fromValue.pointerValue; break;\
        case TypeUShort:\
            resultValue.uShortValue = *(unsigned short *)fromValue.pointerValue; break;\
        case TypeUInt:\
            resultValue.uIntValue = *(unsigned int *)fromValue.pointerValue; break;\
        case TypeULong:\
            resultValue.uLongValue = *(unsigned long *)fromValue.pointerValue; break;\
        case TypeULongLong:\
            resultValue.uLongLongValue = *(unsigned long long *)fromValue.pointerValue; break;\
        case TypeBOOL:\
            resultValue.boolValue = *(BOOL *)fromValue.pointerValue; break;\
        case TypeChar:\
            resultValue.charValue = *(char *)fromValue.pointerValue; break;\
        case TypeShort:\
            resultValue.shortValue = *(short *)fromValue.pointerValue; break;\
        case TypeInt:\
            resultValue.intValue = *(int *)fromValue.pointerValue; break;\
        case TypeLong:\
            resultValue.longValue = *(long *)fromValue.pointerValue; break;\
        case TypeLongLong:\
            resultValue.longLongValue = *(long long *)fromValue.pointerValue; break;\
        case TypeFloat:\
            resultValue.floatValue = *(double *)fromValue.pointerValue; break;\
        case TypeDouble:\
            resultValue.doubleValue = *(double *)fromValue.pointerValue; break;\
        case TypeId:\
        case TypeObject:\
        case TypeBlock:{\
            resultValue.objectValue = *(__strong id *)fromValue.pointerValue;\
            break;\
        }\
        case TypeSEL:\
            resultValue.selValue = *(SEL *)fromValue.pointerValue; break;\
            break;\
        case TypeClass:\
            resultValue.classValue = *(Class *)fromValue.pointerValue; break;\
            break;\
        default:\
            break;\
    }\
} while (0);

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

#define UnaryExecuteBaseType(resultName,operator,value)\
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


#define UnaryExecute(resultName,operator,value)\
do{\
    if (value.isPointer) {\
        resultName = operator (value.pointerValue);\
        break;\
    }\
    UnaryExecuteBaseType(resultName,operator,value)\
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

#define MFValueSetValue(target,from)\
do{\
    if (target.isPointer) {\
        target.pointerValue = from.pointerValue;\
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
- (void)assignFrom:(MFValue *)src;
- (MFValue *)subscriptGetWithIndex:(MFValue *)index;
- (void)subscriptSetValue:(MFValue *)value index:(MFValue *)index;


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
