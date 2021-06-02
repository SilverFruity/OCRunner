//
//  ORHandleTypeEncode.h
//  OCRunner
//
//  Created by Jiang on 2020/7/15.
//  Copyright © 2020 SilverFruity. All rights reserved.
//

#import <Foundation/Foundation.h>
typedef enum: char {
    OCTypeChar = 'c',
    OCTypeShort = 's',
    OCTypeInt = 'i',
    OCTypeLong = 'l',
    OCTypeLongLong = 'q',

    OCTypeUChar = 'C',
    OCTypeUShort = 'S',
    OCTypeUInt = 'I',
    OCTypeULong = 'L',
    OCTypeULongLong = 'Q',
    OCTypeBOOL = 'B',

    OCTypeFloat = 'f',
    OCTypeDouble = 'd',

    OCTypeVoid = 'v',
    OCTypeCString = '*',
    OCTypeObject = '@',
    OCTypeClass = '#',
    OCTypeSEL = ':',

    OCTypeArray = '[',
    OCTypeStruct = '{',
    OCTypeUnion = '(',
    OCTypeBit = 'b',

    OCTypePointer = '^',
    OCTypeUnknown = '?'
}OCType;

#define ExternOCTypeString(Type) static const char OCTypeString##Type[2] = {OCType##Type, '\0'};
ExternOCTypeString(Char)
ExternOCTypeString(Short)
ExternOCTypeString(Int)
ExternOCTypeString(Long)
ExternOCTypeString(LongLong)

ExternOCTypeString(UChar)
ExternOCTypeString(UShort)
ExternOCTypeString(UInt)
ExternOCTypeString(ULong)
ExternOCTypeString(ULongLong)
ExternOCTypeString(BOOL)

ExternOCTypeString(Float)
ExternOCTypeString(Double)
ExternOCTypeString(Void)
ExternOCTypeString(CString)
ExternOCTypeString(Object)
ExternOCTypeString(Class)
ExternOCTypeString(SEL)

ExternOCTypeString(Array)
ExternOCTypeString(Struct)
ExternOCTypeString(Union)
ExternOCTypeString(Bit)

ExternOCTypeString(Pointer)
ExternOCTypeString(Unknown)




//NOTE: ignore bit 'b'
#define TypeEncodeIsBaseType(code) (('a'<= *code && *code <= 'z') || ('A'<= *code && *code <= 'Z'))

static const char *OCTypeStringBlock = "@?";


NSString *startRemovePointerOfTypeEncode(const char *typeEncode);
NSUInteger startDetectPointerCount(const char *typeEncode);
NSString *startStructNameDetect(const char *typeEncode);
NSString *startUnionNameDetect(const char *typeEncode);
NSMutableArray * startStructDetect(const char *typeEncode);
NSMutableArray * startUnionDetect(const char *typeEncode);
NSMutableArray * startArrayDetect(const char *typeEncode);
NSString * detectStructMemeryLayoutEncodeCode(const char *typeEncode);
NSMutableArray *detectStructFieldTypeEncodes(const char *typeEncode);
NSMutableArray *detectFieldTypeEncodes(const char *structMemeryLayoutEncodeCode);
BOOL isHomogeneousFloatingPointAggregate(const char *typeEncode);
NSUInteger fieldCountInStructMemeryLayoutEncode(const char *typeEncode);
BOOL isStructWithTypeEncode(const char *typeEncode);
BOOL isStructPointerWithTypeEncode(const char *typeEncode);
BOOL isStructOrStructPointerWithTypeEncode(const char *typeEncode);
BOOL isHFAStructWithTypeEncode(const char *typeEncode);
NSUInteger totalFieldCountWithTypeEncode(const char *typeEncode);
BOOL isIntegerWithTypeEncode(const char *typeEncode);
BOOL isFloatWithTypeEncode(const char *typeEncode);
BOOL isObjectWithTypeEncode(const char *typeEncode);
BOOL isPointerWithTypeEncode(const char *typeEncode);
NSUInteger sizeOfTypeEncode(const char *typeEncode);
