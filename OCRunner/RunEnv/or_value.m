//
//  or_value.c
//  OCRunner
//
//  Created by APPLE on 2021/7/9.
//

#include "or_value.h"
#import <oc2mangoLib/ocHandleTypeEncode.h>
#import <ORPatchFile/ORPatchFile.h>

#define or_value_bridge(target, typeencode, resultType)\
resultType result;\
switch (*typeencode) {\
    case OCTypeUChar: result = (resultType)target.uCharValue; break;\
    case OCTypeUInt: result = (resultType)target.uIntValue; break;\
    case OCTypeUShort: result = (resultType)target.uShortValue; break;\
    case OCTypeULong: result = (resultType)target.uLongValue; break;\
    case OCTypeULongLong: result = (resultType)target.uLongLongValue; break;\
    case OCTypeBOOL: result = (resultType)target.boolValue; break;\
    case OCTypeChar: result = (resultType)target.charValue; break;\
    case OCTypeShort: result = (resultType)target.shortValue; break;\
    case OCTypeInt: result = (resultType)target.intValue; break;\
    case OCTypeLong: result = (resultType)target.longValue; break;\
    case OCTypeLongLong: result = (resultType)target.longlongValue; break;\
    case OCTypeFloat: result = (resultType)target.floatValue; break;\
    case OCTypeDouble: result = (resultType)target.doubleValue; break;\
    default: result = 0;\
}


size_t or_value_mem_size(or_value *value){
    NSUInteger size;
    NSGetSizeAndAlignment(value->typeencode, &size, NULL);
    return size;
}
or_value or_value_create(const char *typeencode, void *pointer){
    or_value value =  { 0 };
    or_value_set_typeencode(&value, typeencode);
    or_value_set_pointer(&value, pointer);
    return value;
}
void or_value_convert(or_value *value, const char *aim_typeencode, void **dst){
    do {
        if ((TypeEncodeIsBaseType(aim_typeencode)) == 0) break;
        if (*value->typeencode == *aim_typeencode) break;
        if (value->pointer == NULL) break;
        //基础类型转换
        switch (*aim_typeencode) {
            case OCTypeUChar:{
                or_value_bridge(value->box, value->typeencode, unsigned char)
                memcpy(dst, &result, sizeof(unsigned char));
                break;
            }
            case OCTypeUInt:{
                or_value_bridge(value->box, value->typeencode, unsigned int)
                memcpy(dst, &result, sizeof(unsigned int));
                break;
            }
            case OCTypeUShort:{
                or_value_bridge(value->box, value->typeencode, unsigned short)
                memcpy(dst, &result, sizeof(unsigned short));
                break;
            }
            case OCTypeULong:{
                or_value_bridge(value->box, value->typeencode, unsigned long)
                memcpy(dst, &result, sizeof(unsigned long));
                break;
            }
            case OCTypeULongLong:{
                or_value_bridge(value->box, value->typeencode, unsigned long long)
                memcpy(dst, &result, sizeof(unsigned long long));
                break;
            }
            case OCTypeBOOL:{
                or_value_bridge(value->box, value->typeencode, BOOL)
                memcpy(dst, &result, sizeof(BOOL));
                break;
            }
            case OCTypeChar:{
                or_value_bridge(value->box, value->typeencode, char)
                memcpy(dst, &result, sizeof(char));
                break;
            }
            case OCTypeShort:{
                or_value_bridge(value->box, value->typeencode, short)
                memcpy(dst, &result, sizeof(short));
                break;
            }
            case OCTypeInt:{
                or_value_bridge(value->box, value->typeencode, int)
                memcpy(dst, &result, sizeof(int));
                break;
            }
            case OCTypeLong:{
                or_value_bridge(value->box, value->typeencode, long)
                memcpy(dst, &result, sizeof(long));
                break;
            }
            case OCTypeLongLong:{
                or_value_bridge(value->box, value->typeencode, long long)
                memcpy(dst, &result, sizeof(long long));
                break;
            }
            case OCTypeFloat:{
                or_value_bridge(value->box, value->typeencode, float)
                memcpy(dst, &result, sizeof(float));
                break;
            }
            case OCTypeDouble:{
                or_value_bridge(value->box, value->typeencode, double)
                memcpy(dst, &result, sizeof(double));
                break;
            }
            default: break;
        }
    } while (0);
}
void or_value_set_typeencode(or_value *value, const char *typeencode){
    if (typeencode == NULL) {
        typeencode = OCTypeStringULongLong;
    }
    if (value->typeencode == NULL) {
        value->typeencode = typeencode;
        return;
    }
    //基础类型转换
    if (strlen(typeencode) == 1) {
        //类型相同时，直接跳过
        if (*typeencode == *value->typeencode) {
            return;
        }
        void *result = NULL;
        or_value_convert(value, typeencode, &result);
        value->typeencode = typeencode;
        if (result != NULL) {
            or_value_set_pointer(value, &result);
        }
        return;
    }
    value->typeencode = typeencode;
}

void or_value_set_pointer(or_value *value, void *pointer){

    assert(value->typeencode != NULL);
    void *replace = NULL;
    if (pointer == NULL) {
        pointer = &replace;
    }
    switch (*value->typeencode) {
        case OCTypeUChar:
            value->box.uCharValue = *(unsigned char *)pointer;
            break;
        
        case OCTypeUInt:
            value->box.uIntValue = *(unsigned int *)pointer;
            break;
        
        case OCTypeUShort:
            value->box.uShortValue = *(unsigned short *)pointer;
            break;
        
        case OCTypeULong:
            value->box.uLongValue = *(unsigned long *)pointer;
            break;
        
        case OCTypeULongLong:
            value->box.uLongLongValue = *(unsigned long long *)pointer;
            break;
        
        case OCTypeBOOL:
            value->box.boolValue = *(BOOL *)pointer;
            break;
        
        case OCTypeChar:
            value->box.charValue = *(char *)pointer;
            break;
        
        case OCTypeShort:
            value->box.shortValue = *(short *)pointer;
            break;
        
        case OCTypeInt:
            value->box.intValue = *(int *)pointer;
            break;
        
        case OCTypeLong:
            value->box.longValue = *(long *)pointer;
            break;
        
        case OCTypeLongLong:
            value->box.longlongValue = *(long long *)pointer;
            break;
        
        case OCTypeFloat:
            value->box.floatValue = *(float *)pointer;
            break;
        
        case OCTypeDouble:
            value->box.doubleValue = *(double *)pointer;
            break;
        
        case OCTypeCString:
            value->box.pointerValue = pointer;
            break;
        
        case OCTypeObject:
        case OCTypeClass:
        case OCTypeSEL:
            value->box.pointerValue = *(void **)pointer;
            break;
            
        case OCTypeArray:
        case OCTypeUnion:
        case OCTypeStruct:
            value->box.pointerValue = pointer;
            break;
        case OCTypePointer:
            value->box.pointerValue = *(void **)pointer;
            break;
        default:
            value->box.uLongLongValue = 0;
            break;
    }
    value->pointer = pointer;

}
void or_value_write_to(or_value value, void *dst, const char *aim_typeencode){
    aim_typeencode = aim_typeencode == NULL ? OCTypeStringPointer : aim_typeencode;
    if (dst == NULL) {
        return;
    }
    NSUInteger resultSize;
    NSGetSizeAndAlignment(aim_typeencode, &resultSize, NULL);
    memset(dst, 0, resultSize);
    NSUInteger currentSize;
    NSGetSizeAndAlignment(value.typeencode, &currentSize, NULL);
    void *copySource = value.pointer;
    void *convertResult = NULL;
    or_value_convert(&value, aim_typeencode, &convertResult);
    if (convertResult != NULL) {
        copySource = &convertResult;
    }
    if (currentSize < resultSize){
        memcpy(dst, copySource, currentSize);
    }else{
        memcpy(dst, copySource, resultSize);
    }
}
BOOL or_value_isSubtantial(or_value value){
    BOOL result = NO;
    UnaryExecute(result, !, value);
    return !result;
}

or_value or_nullValue(void){
    return or_value_create(OCTypeStringPointer , NULL);
}
or_value or_voidValue(void){
    return or_value_create(OCTypeStringVoid , NULL);
}
or_value or_BOOL_value(BOOL boolValue){
    return or_value_create(OCTypeStringBOOL , &boolValue);
}
or_value or_UChar_value(unsigned char uCharValue){
    return or_value_create(OCTypeStringUChar , &uCharValue);
}
or_value or_UShort_value(unsigned short uShortValue){
    return or_value_create(OCTypeStringUShort , &uShortValue);
}
or_value or_UInt_value(unsigned int uIntValue){
    return or_value_create(OCTypeStringUInt , &uIntValue);
}
or_value or_ULong_value(unsigned long uLongValue){
    return or_value_create(OCTypeStringULong , &uLongValue);
}
or_value or_ULongLong_value(unsigned long long uLongLongValue){
    return or_value_create(OCTypeStringULongLong , &uLongLongValue);
}
or_value or_Char_value(char charValue){
    return or_value_create(OCTypeStringChar , &charValue);
}
or_value or_Short_value(short shortValue){
    return or_value_create(OCTypeStringShort , &shortValue);
}
or_value or_Int_value(int intValue){
    return or_value_create(OCTypeStringInt , &intValue);
}
or_value or_Long_value(long longValue){
    return or_value_create(OCTypeStringLong , &longValue);
}
or_value or_LongLong_value(long long longLongValue){
    return or_value_create(OCTypeStringLongLong , &longLongValue);
}
or_value or_Float_value(float floatValue){
    return or_value_create(OCTypeStringFloat , &floatValue);
}
or_value or_Double_value(double doubleValue){
    return or_value_create(OCTypeStringDouble , &doubleValue);
}
or_value or_Object_value(id objValue){
    return or_value_create(OCTypeStringObject , &objValue);
}
or_value or_Block_value(id blockValue){
    return or_value_create(OCTypeStringBlock , &blockValue);
}
or_value or_Class_value(Class clazzValue){
    return or_value_create(OCTypeStringClass , &clazzValue);
}
or_value or_SEL_value(SEL selValue){
    return or_value_create(OCTypeStringSEL , &selValue);
}
or_value or_CString_value(char * pointerValue){
    return or_value_create(OCTypeStringCString , &pointerValue);
}
or_value or_Pointer_value(void * pointerValue){
    return or_value_create(OCTypeStringPointer , &pointerValue);
}
