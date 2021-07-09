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
result.typeEncode = cal_result.typeencode;\
result->realBaseValue = cal_result.box;\

#define PrefixUnaryExecuteInt(operator,value)\
cal_result.typeencode = value.typeencode;\
switch (*value.typeencode) {\
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
cal_result.typeencode = value.typeencode;\
switch (*value.typeencode) {\
case OCTypeFloat:\
cal_result.box.floatValue = (operator *(float *)value.pointer); break;\
case OCTypeDouble:\
cal_result.box.doubleValue = (operator *(double *)value.pointer); break;\
default:\
break;\
}\

#define SuffixUnaryExecuteInt(operator,value)\
cal_result.typeencode = value.typeencode;\
switch (*value.typeencode) {\
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
cal_result.typeencode = value.typeencode;\
switch (*value.typeencode) {\
case OCTypeFloat:\
cal_result.box.floatValue = ((*(float *)value.pointer) operator); break;\
case OCTypeDouble:\
cal_result.box.doubleValue = ((*(double *)value.pointer) operator); break;\
default:\
break;\
}\

#define UnaryExecuteBaseType(resultName,operator,value)\
switch (*value.typeencode) {\
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
    if (isPointerWithTypeEncode(value.typeencode)) {\
        resultName = operator (value.pointer);\
        break;\
    }\
    UnaryExecuteBaseType(resultName,operator,value)\
    switch (*value.typeencode) {\
    case OCTypeObject:\
    resultName = operator (*value.pointer); break;\
    case OCTypeSEL:\
    resultName = operator (*value.pointer); break;\
    case OCTypeClass:\
    resultName = operator (*value.pointer); break;\
    default:\
    break;\
    }\
}while(0)

#define BinaryExecute(value_type,leftValue,operator,rightValue)\
( (*(value_type *)leftValue.pointer) operator (*(value_type *)rightValue.pointer) ); break;

#define BinaryExecuteInt(leftValue,operator,rightValue)\
cal_result.typeencode = leftValue.typeencode;\
switch (*leftValue.typeencode) {\
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
cal_result.box.value_type = leftValue.box.value_type operator rightValue.box.value_type

#define CalculateExecuteRight(value_type,leftValue,operator,rightValue)\
leftValue.value_type operator rightValue.value_type

#define CalculateExecute(leftValue,operator,rightValue)\
OCType result_type = *leftValue.typeencode;\
cal_result.typeencode = leftValue.typeencode;\
if (*leftValue.typeencode != *rightValue.typeencode\
    && (*leftValue.typeencode == OCTypeFloat || *leftValue.typeencode == OCTypeDouble\
    || *rightValue.typeencode == OCTypeFloat || *rightValue.typeencode == OCTypeDouble )){\
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
    OCType compare_type = *leftValue.typeencode;\
    if (*leftValue.typeencode != *rightValue.typeencode\
        && (*leftValue.typeencode == OCTypeFloat || *leftValue.typeencode == OCTypeDouble\
        || *rightValue.typeencode == OCTypeFloat || *rightValue.typeencode == OCTypeDouble )){\
        compare_type = OCTypeDouble;\
    }\
    switch (compare_type) {\
    case OCTypeUChar:\
        logicResultValue = leftValue.box.uCharValue operator rightValue.box.uCharValue;  break;\
    case OCTypeUShort:\
        logicResultValue = leftValue.box.uShortValue operator rightValue.box.uShortValue;  break;\
    case OCTypeUInt:\
        logicResultValue = leftValue.box.uIntValue operator rightValue.box.uIntValue;  break;\
    case OCTypeULong:\
        logicResultValue = leftValue.box.uLongValue operator rightValue.box.uLongValue;  break;\
    case OCTypeULongLong:\
        logicResultValue = leftValue.box.uLongLongValue operator rightValue.box.uLongLongValue;  break;\
    case OCTypeBOOL:\
        logicResultValue = leftValue.box.boolValue operator rightValue.box.boolValue;  break;\
    case OCTypeChar:\
        logicResultValue = leftValue.box.charValue operator rightValue.box.charValue;  break;\
    case OCTypeShort:\
        logicResultValue = leftValue.box.shortValue operator rightValue.box.shortValue;  break;\
    case OCTypeInt:\
        logicResultValue = leftValue.box.intValue operator rightValue.box.intValue;  break;\
    case OCTypeLong:\
        logicResultValue = leftValue.box.longValue operator rightValue.box.longValue;  break;\
    case OCTypeLongLong:\
        logicResultValue = leftValue.box.longlongValue operator rightValue.box.longlongValue;  break;\
    case OCTypeFloat:\
        logicResultValue = leftValue.box.floatValue operator rightValue.box.floatValue;  break;\
    case OCTypeDouble:\
        logicResultValue = leftValue.box.doubleValue operator rightValue.box.doubleValue;  break;\
    case OCTypeObject:\
        logicResultValue = BinaryExecute(void *,leftValue,operator,rightValue); break;\
    case OCTypeSEL:\
        logicResultValue = BinaryExecute(void *,leftValue,operator,rightValue);  break;\
    case OCTypeClass:\
        logicResultValue = BinaryExecute(void *,leftValue,operator,rightValue);  break;\
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
    void **pointer;
    const char *typeencode;
}or_value;


or_value or_value_create(const char *typeencode, void *pointer);
size_t or_value_mem_size(or_value *value);
void or_value_convert(or_value *value, const char *aim_typeencode, void **dst);
void or_value_set_typeencode(or_value *value, const char *typeencode);
void or_value_set_pointer(or_value *value, void *pointer);
void or_value_write_to(or_value value, void *dst, const char *aim_typeencode);
BOOL or_value_isSubtantial(or_value value);

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
