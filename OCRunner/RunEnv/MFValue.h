//
//  MFValue .h
//  MangoFix
//
//  Created by jerry.yong on 2018/2/28.
//  Copyright © 2018年 yongpengliang. All rights reserved.
//

#import <Foundation/Foundation.h>
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
#define startBox(value)\
NSUInteger size;\
NSGetSizeAndAlignment(value.typeEncode, &size, NULL);\
void *box = malloc(size);\

#define endBox(result)\
result.pointer = box;\
free(box);

#define PrefixUnaryExecuteInt(operator,value,resultValue)\
switch (value.typePair.type.type) {\
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

#define PrefixUnaryExecuteFloat(operator,value,resultValue)\
switch (value.typePair.type.type) {\
case TypeFloat:\
*(float *)box = (operator *(float *)value.pointer); break;\
case TypeDouble:\
*(double *)box = (operator *(double *)value.pointer); break;\
default:\
break;\
}\

#define SuffixUnaryExecuteInt(operator,value,resultValue)\
switch (value.typePair.type.type) {\
case TypeUChar:\
(*(unsigned char *)value.pointer operator); break;\
case TypeUShort:\
(*(unsigned short *)value.pointer operator); break;\
case TypeUInt:\
(*(unsigned int *)value.pointer operator); break;\
case TypeULong:\
(*(unsigned long *)value.pointer operator); break;\
case TypeULongLong:\
(*(unsigned long long *)value.pointer operator); break;\
case TypeBOOL:\
(*(BOOL *)value.pointer operator); break;\
case TypeChar:\
(*(char *)value.pointer operator); break;\
case TypeShort:\
(*(short *)value.pointer operator); break;\
case TypeInt:\
(*(int *)value.pointer operator); break;\
case TypeLong:\
(*(long *)value.pointer operator); break;\
case TypeLongLong:\
(*(long long *)value.pointer operator); break;\
default:\
break;\
}\
resultValue.pointer = value.pointer;


#define SuffixUnaryExecuteFloat(operator,value,resultValue)\
switch (value.typePair.type.type) {\
case TypeFloat:\
(*(float *)value.pointer operator); break;\
case TypeDouble:\
(*(double *)value.pointer operator); break;\
default:\
break;\
}\
resultValue.pointer = value.pointer;

#define UnaryExecuteBaseType(resultName,operator,value)\
switch (value.typePair.type.type) {\
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
    switch (value.typePair.type.type) {\
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
switch (leftValue.typePair.type.type) {\
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
switch (leftValue.typePair.type.type) {\
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
    switch (leftValue.typePair.type.type) {\
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

@interface ORTypeVarPair(Convert)
- (const char *)typeEncode;
+ (instancetype)objectTypePair;
+ (instancetype)pointerTypePair;
@end
ORTypeVarPair *typePairWithTypeEncode(const char *tyepEncode);

extern BOOL MFStatementResultTypeIsReturn(MFStatementResultType type);
@interface MFValue : NSObject

@property (assign, nonatomic) MFStatementResultType resultType;
@property (assign, nonatomic) BOOL isReturn;
@property (assign, nonatomic) BOOL isContinue;
@property (assign, nonatomic) BOOL isBreak;
@property (assign, nonatomic) BOOL isNormal;

+ (instancetype)normalEnd;

- (void)assignFrom:(MFValue *)src;
- (MFValue *)subscriptGetWithIndex:(MFValue *)index;
- (void)subscriptSetValue:(MFValue *)value index:(MFValue *)index;

@property (nonatomic,nullable) id objectValue;
@property (nonatomic,assign)void *pointer;
@property (nonatomic,assign)const char* typeEncode;
@property (assign,nonatomic)ORDeclarationModifier modifier;
@property (strong,nonatomic)ORTypeVarPair *typePair;

+ (instancetype)defaultValueWithTypeEncoding:(const char *)typeEncoding;
- (instancetype)initTypeEncode:(const char *)tyepEncode pointer:(nullable void *)pointer;
- (instancetype)initTypeKind:(TypeKind)TypeKind pointer:(void *)pointer;
- (instancetype)initTypePair:(ORTypeVarPair *)typePair pointer:(void *)pointer;

- (BOOL)isPointer;
- (BOOL)isMember;
- (BOOL)isSubtantial;
- (BOOL)isObject;
- (BOOL)isBaseValue;
- (void)setValueType:(TypeKind)type;

- (void)writePointer:(void *)pointer typeEncode:(const char *)typeEncode;

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


@end


@interface ORStructField: NSObject
@property (nonatomic,assign)void *fieldPointer;
@property (nonatomic,copy)NSString *fieldTypeEncode;
- (BOOL)isStruct;
- (BOOL)isStructPointer;
- (MFValue *)value;
- (ORStructField *)fieldForKey:(NSString *)key;
- (ORStructField *)getPointerValueField;
@end

@interface MFValue (Struct)
- (ORStructField *)fieldForKey:(NSString *)key;
@end
NS_ASSUME_NONNULL_END
