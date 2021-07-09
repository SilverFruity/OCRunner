//
//  or_value.h
//  OCRunner
//
//  Created by APPLE on 2021/7/9.
//

#import <Foundation/Foundation.h>

#define START_BOX \
or_value cal_result;\

#define END_BOX(result)\
result.typeEncode = cal_result.typeEncode;\
result->realBaseValue = cal_result.box;\

#define PrefixUnaryExecuteInt(operator,value)\
cal_result.typeencode = value.typeEncode;\
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
cal_result.typeencode = value.typeEncode;\
switch (value.type) {\
case OCTypeFloat:\
cal_result.box.floatValue = (operator *(float *)value.pointer); break;\
case OCTypeDouble:\
cal_result.box.doubleValue = (operator *(double *)value.pointer); break;\
default:\
break;\
}\

#define SuffixUnaryExecuteInt(operator,value)\
cal_result.typeencode = value.typeEncode;\
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
cal_result.typeencode = value.typeEncode;\
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
cal_result.typeencode = leftValue.typeEncode;\
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
cal_result.typeencode = leftValue.typeEncode;\
if (leftValue.type != rightValue.type\
    && (leftValue.type == OCTypeFloat || leftValue.type == OCTypeDouble\
    || rightValue.type == OCTypeFloat || rightValue.type == OCTypeDouble )){\
    result_type = OCTypeDouble;\
    cal_result.typeencode = OCTypeStringDouble;\
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
}or_value_box;

typedef struct{
    or_value_box box;
    void *pointer;
    const char *typeencode;
}or_value;


or_value or_value_create(const char *typeencode, void *pointer);
size_t or_value_mem_size(or_value *value);
void or_value_convert(or_value *value, const char *aim_typeencode, void **dst);
void or_value_set_typeencode(or_value *value, const char *typeencode);
void or_value_set_pointer(or_value *value, void *pointer);

or_value or_nullValue(void);
or_value or_voidValue(void);
or_value or_BOOL_value(BOOL boolValue);
or_value or_UChar_value(unsigned char uCharValue);
or_value or_UShort_value(unsigned short uShortValue);
or_value or_UInt_value(unsigned int uIntValue);
or_value or_ULong_value(unsigned long uLongValue);
or_value or_ULongLong_value(unsigned long long uLongLongValue);
or_value or_Char_value(char charValue);
or_value or_Short_value(short shortValue);
or_value or_Int_value(int intValue);
or_value or_Long_value(long longValue);
or_value or_LongLong_value(long long longLongValue);
or_value or_Float_value(float floatValue);
or_value or_Double_value(double doubleValue);
or_value or_Object_value(id objValue);
or_value or_Block_value(id blockValue);
or_value or_Class_value(Class clazzValue);
or_value or_SEL_value(SEL selValue);
or_value or_CString_value(char * pointerValue);
or_value or_Pointer_value(void * pointerValue);
