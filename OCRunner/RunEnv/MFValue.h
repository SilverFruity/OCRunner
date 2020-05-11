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

#define ValueDefineWithMFValue(suffix,target)\
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
do {\
    if ((target.typePair.type.type & TypeBaseMask) && target.typePair.var.ptCount > 0) {\
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
            objectValue##suffix = target.pointerValue;\
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

#define PrefixCat(prefix, name) prefix##name
#define SuffixCat(name, suffix) name##suffix

#define UnaryExecute(operator,suffix,target)\
void * unaryResultValuePointer##suffix = NULL;\
switch (target.typePair.type.type) {\
case TypeUChar:\
unaryResultValuePointer##suffix = operator uCharValue##suffix; break;\
case TypeUShort:\
unaryResultValuePointer##suffix =  operator uShortValue##suffix; break;\
case TypeUInt:\
unaryResultValuePointer##suffix =  operator uIntValue##suffix; break;\
case TypeULong:\
unaryResultValuePointer##suffix =  operator uLongValue##suffix; break;\
case TypeULongLong:\
unaryResultValuePointer##suffix =  operator uLLongValue##suffix; break;\
case TypeBOOL:\
unaryResultValuePointer##suffix =  operator boolValue##suffix; break;\
case TypeChar:\
unaryResultValuePointer##suffix =  operator charValue##suffix; break;\
case TypeShort:\
unaryResultValuePointer##suffix =  operator shortValue##suffix; break;\
case TypeInt:\
unaryResultValuePointer##suffix =  operator intValue##suffix; break;\
case TypeLong:\
unaryResultValuePointer##suffix =  operator longValue##suffix; break;\
case TypeLongLong:\
unaryResultValuePointer##suffix =  operator lLongValue##suffix; break;\
case TypeFloat:\
unaryResultValuePointer##suffix =  operator floatValue##suffix; break;\
case TypeDouble:\
unaryResultValuePointer##suffix =  operator doubleValue##suffix; break;\
case TypeId:\
case TypeObject:\
case TypeBlock:\
unaryResultValuePointer##suffix =  operator objectValue##suffix; break;\
case TypeSEL:\
unaryResultValuePointer##suffix =  operator selValue##suffix; break;\
case TypeClass:\
unaryResultValuePointer##suffix =  operator classValue##suffix; break;\
default:\
break;\
}



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

@property (assign, nonatomic, nullable) void *pointerValue;

@property (assign,nonatomic)MFDeclarationModifier modifier;
@property (strong,nonatomic)ORTypeVarPair *typePair;
- (void)setValueType:(TypeKind)type;
- (BOOL)isSubtantial;
- (BOOL)isObject;
- (BOOL)isMember;
- (BOOL)isBaseValue;
- (id)subscriptGetWithIndex:(MFValue *)index;
- (void)subscriptSetWithIndex:(MFValue *)index value:(MFValue *)value;

+ (instancetype)defaultValueWithTypeEncoding:(const char *)typeEncoding;
+ (instancetype)voidValueInstance;
+ (instancetype)valueInstanceWithBOOL:(BOOL)boolValue;
+ (instancetype)valueInstanceWithUint:(uint64_t)uintValue;
+ (instancetype)valueInstanceWithInt:(int64_t)intValue;
+ (instancetype)valueInstanceWithDouble:(double)doubleValue;
+ (instancetype)valueInstanceWithObject:(nullable id)objValue;
+ (instancetype)valueInstanceWithBlock:(nullable id)blockValue;
+ (instancetype)valueInstanceWithClass:(nullable Class)clazzValue;
+ (instancetype)valueInstanceWithSEL:(SEL)selValue;
+ (instancetype)valueInstanceWithCstring:(nullable const char *)cstringValue;
+ (instancetype)valueInstanceWithPointer:(nullable void *)pointerValue;
+ (instancetype)valueInstanceWithStruct:(void *)structValue typeEncoding:(const char *)typeEncoding copyData:(BOOL)copyData;

- (instancetype)nsStringValue;

@end
NS_ASSUME_NONNULL_END
