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


#define PrefixUnaryExecuteInt(operator,suffix,target,resultSuffix)\
switch (target.typePair.type.type) {\
case TypeUChar:\
uCharValue##resultSuffix = (operator uCharValue##suffix); break;\
case TypeUShort:\
uShortValue##resultSuffix = (operator uShortValue##suffix); break;\
case TypeUInt:\
uIntValue##resultSuffix = (operator uIntValue##suffix); break;\
case TypeULong:\
uLongValue##resultSuffix = (operator uLongValue##suffix); break;\
case TypeULongLong:\
uLLongValue##resultSuffix = (operator uLLongValue##suffix); break;\
case TypeBOOL:\
boolValue##resultSuffix = (operator boolValue##suffix); break;\
case TypeChar:\
charValue##resultSuffix = (operator charValue##suffix); break;\
case TypeShort:\
shortValue##resultSuffix = (operator shortValue##suffix); break;\
case TypeInt:\
intValue##resultSuffix = (operator intValue##suffix); break;\
case TypeLong:\
longValue##resultSuffix = (operator longValue##suffix); break;\
case TypeLongLong:\
lLongValue##resultSuffix = (operator lLongValue##suffix); break;\
default:\
break;\
}

#define PrefixUnaryExecuteFloat(operator,suffix,target,resultSuffix)\
switch (target.typePair.type.type) {\
case TypeFloat:\
floatValue##resultSuffix = (operator floatValue##suffix); break;\
case TypeDouble:\
doubleValue##resultSuffix = (operator doubleValue##suffix); break;\
default:\
break;\
}

#define SuffixUnaryExecuteInt(operator,suffix,target,resultSuffix)\
switch (target.typePair.type.type) {\
case TypeUChar:\
uCharValue##resultSuffix = (uCharValue##suffix operator); break;\
case TypeUShort:\
uShortValue##resultSuffix = (uShortValue##suffix operator); break;\
case TypeUInt:\
uIntValue##resultSuffix = (uIntValue##suffix operator); break;\
case TypeULong:\
uLongValue##resultSuffix = (uLongValue##suffix operator); break;\
case TypeULongLong:\
uLLongValue##resultSuffix = (uLLongValue##suffix operator); break;\
case TypeBOOL:\
boolValue##resultSuffix = (boolValue##suffix operator); break;\
case TypeChar:\
charValue##resultSuffix = (charValue##suffix operator); break;\
case TypeShort:\
shortValue##resultSuffix = (shortValue##suffix operator); break;\
case TypeInt:\
intValue##resultSuffix = (intValue##suffix operator); break;\
case TypeLong:\
longValue##resultSuffix = (longValue##suffix operator); break;\
case TypeLongLong:\
lLongValue##resultSuffix = (lLongValue##suffix operator); break;\
default:\
break;\
}

#define SuffixUnaryExecuteFloat(operator,suffix,target,resultSuffix)\
switch (target.typePair.type.type) {\
case TypeFloat:\
floatValue##resultSuffix = (floatValue##suffix operator); break;\
case TypeDouble:\
doubleValue##resultSuffix = (doubleValue##suffix operator); break;\
default:\
break;\
}


#define UnaryExecute(resutlType,operator,suffix,target)\
resutlType unaryResultValue##suffix;\
do{\
    if (target.isPointer) {\
        pointerValue##suffix = operator (pointerValue##suffix);\
        break;\
    }\
    switch (target.typePair.type.type) {\
    case TypeUChar:\
    unaryResultValue##suffix = operator (uCharValue##suffix); break;\
    case TypeUShort:\
    unaryResultValue##suffix = operator (uShortValue##suffix); break;\
    case TypeUInt:\
    unaryResultValue##suffix = operator (uIntValue##suffix); break;\
    case TypeULong:\
    unaryResultValue##suffix = operator (uLongValue##suffix); break;\
    case TypeULongLong:\
    unaryResultValue##suffix = operator (uLLongValue##suffix); break;\
    case TypeBOOL:\
    unaryResultValue##suffix = operator (boolValue##suffix); break;\
    case TypeChar:\
    unaryResultValue##suffix = operator (charValue##suffix); break;\
    case TypeShort:\
    unaryResultValue##suffix = operator (shortValue##suffix); break;\
    case TypeInt:\
    unaryResultValue##suffix = operator (intValue##suffix); break;\
    case TypeLong:\
    unaryResultValue##suffix = operator (longValue##suffix); break;\
    case TypeLongLong:\
    unaryResultValue##suffix = operator (lLongValue##suffix); break;\
    case TypeFloat:\
    unaryResultValue##suffix = operator (floatValue##suffix); break;\
    case TypeDouble:\
    unaryResultValue##suffix = operator (doubleValue##suffix); break;\
    case TypeId:\
    case TypeObject:\
    case TypeBlock:\
    unaryResultValue##suffix = operator (objectValue##suffix); break;\
    case TypeSEL:\
    unaryResultValue##suffix = operator (selValue##suffix); break;\
    case TypeClass:\
    unaryResultValue##suffix = operator (classValue##suffix); break;\
    default:\
    break;\
    }\
}while(0)


#define BinaryExecuteInt(left,operator,right,type,resultSuffix)\
switch (type) {\
case TypeUChar:\
uCharValue##resultSuffix = (uCharValue##left operator uCharValue##right); break;\
case TypeUShort:\
uShortValue##resultSuffix = (uShortValue##left operator uShortValue##right); break;\
case TypeUInt:\
uIntValue##resultSuffix = (uIntValue##left operator uIntValue##right); break;\
case TypeULong:\
uLongValue##resultSuffix = (uLongValue##left operator uLongValue##right); break;\
case TypeULongLong:\
uLLongValue##resultSuffix = (uLLongValue##left operator uLLongValue##right); break;\
case TypeBOOL:\
boolValue##resultSuffix = (boolValue##left operator boolValue##right); break;\
case TypeChar:\
charValue##resultSuffix = (charValue##left operator charValue##right); break;\
case TypeShort:\
shortValue##resultSuffix = (shortValue##left operator shortValue##right); break;\
case TypeInt:\
intValue##resultSuffix = (intValue##left operator intValue##right); break;\
case TypeLong:\
longValue##resultSuffix = (longValue##left operator longValue##right); break;\
case TypeLongLong:\
lLongValue##resultSuffix = (lLongValue##left operator lLongValue##right); break;\
default:\
break;\
}

#define BinaryExecuteFloat(left,operator,right,type, resultSuffix)\
switch (type) {\
case TypeFloat:\
floatValue##resultSuffix = (floatValue##left operator floatValue##right); break;\
case TypeDouble:\
doubleValue##resultSuffix = (doubleValue##left operator doubleValue##right); break;\
default:\
break;\
}

#define LogicBinaryOperatorExecute(left,operator,right,target)\
BOOL logicResultValue = NO;\
do{\
    if (target.isPointer) {\
        logicResultValue= (pointerValue##left operator pointerValue##right);\
        break;\
    }\
    switch (target.typePair.type.type) {\
    case TypeUChar:\
    logicResultValue = (uCharValue##left operator uCharValue##right); break;\
    case TypeUShort:\
    logicResultValue = (uShortValue##left operator uShortValue##right); break;\
    case TypeUInt:\
    logicResultValue = (uIntValue##left operator uIntValue##right); break;\
    case TypeULong:\
    logicResultValue = (uLongValue##left operator uLongValue##right); break;\
    case TypeULongLong:\
    logicResultValue = (uLLongValue##left operator uLLongValue##right); break;\
    case TypeBOOL:\
    logicResultValue = (boolValue##left operator boolValue##right); break;\
    case TypeChar:\
    logicResultValue = (charValue##left operator charValue##right); break;\
    case TypeShort:\
    logicResultValue = (shortValue##left operator shortValue##right); break;\
    case TypeInt:\
    logicResultValue = (intValue##left operator intValue##right); break;\
    case TypeLong:\
    logicResultValue = (longValue##left operator longValue##right); break;\
    case TypeLongLong:\
    logicResultValue = (lLongValue##left operator lLongValue##right); break;\
    case TypeFloat:\
    logicResultValue = (floatValue##left operator floatValue##right); break;\
    case TypeDouble:\
    logicResultValue = (doubleValue##left operator doubleValue##right); break;\
    case TypeId:\
    case TypeObject:\
    case TypeBlock:\
    logicResultValue = (objectValue##left operator objectValue##right); break;\
    case TypeSEL:\
    logicResultValue =  (selValue##left operator selValue##right); break;\
    case TypeClass:\
    logicResultValue =  (classValue##left operator classValue##right); break;\
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
    default:\
    break;\
    }\
}while(0)


NS_ASSUME_NONNULL_BEGIN
typedef NS_ENUM(NSInteger, MFStatementResultType) {
    //no return, continue, break
    MFStatementResultTypeNormal = 0x01,
    MFStatementResultTypeBreak = 0x02,
    MFStatementResultTypeContinue = 0x03,
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
- (id)subscriptGetWithIndex:(MFValue *)index;
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
@end
NS_ASSUME_NONNULL_END
