//
//  ORHandleTypeEncode.h
//  OCRunner
//
//  Created by Jiang on 2020/7/15.
//  Copyright © 2020 SilverFruity. All rights reserved.
//

#import <Foundation/Foundation.h>
static const char OCTypeEncodeChar = 'c';
static const char OCTypeEncodeShort = 's';
static const char OCTypeEncodeInt = 'i';
static const char OCTypeEncodeLong = 'l';
static const char OCTypeEncodeLongLong = 'q';

static const char OCTypeEncodeUChar = 'C';
static const char OCTypeEncodeUShort = 'S';
static const char OCTypeEncodeUInt = 'I';
static const char OCTypeEncodeULong = 'L';
static const char OCTypeEncodeULongLong = 'Q';
static const char OCTypeEncodeBOOL = 'B';

static const char OCTypeEncodeFloat = 'f';
static const char OCTypeEncodeDouble = 'd';

static const char OCTypeEncodeVoid = 'v';
static const char OCTypeEncodeCString = '*';
static const char OCTypeEncodeObject = '@';
static const char OCTypeEncodeClass = '#';
static const char OCTypeEncodeSEL = ':';

static const char OCTypeEncodeArray = '[';
static const char OCTypeEncodeStruct = '{';
static const char OCTypeEncodeUnion = '(';
static const char OCTypeEncodeBit = 'b';

static const char OCTypeEncodePointer = '^';
static const char OCTypeEncodeUnknown = '?';

#define ExternTypeEncodeString(Type) static const char OCTypeEncodeString##Type[2] = {OCTypeEncode##Type, '\0'};
ExternTypeEncodeString(Char)
ExternTypeEncodeString(Short)
ExternTypeEncodeString(Int)
ExternTypeEncodeString(Long)
ExternTypeEncodeString(LongLong)

ExternTypeEncodeString(UChar)
ExternTypeEncodeString(UShort)
ExternTypeEncodeString(UInt)
ExternTypeEncodeString(ULong)
ExternTypeEncodeString(ULongLong)
ExternTypeEncodeString(BOOL)

ExternTypeEncodeString(Float)
ExternTypeEncodeString(Double)
ExternTypeEncodeString(Void)
ExternTypeEncodeString(CString)
ExternTypeEncodeString(Object)
ExternTypeEncodeString(Class)
ExternTypeEncodeString(SEL)

ExternTypeEncodeString(Array)
ExternTypeEncodeString(Struct)
ExternTypeEncodeString(Union)
ExternTypeEncodeString(Bit)

ExternTypeEncodeString(Pointer)
ExternTypeEncodeString(Unknown)




//NOTE: ignore bit 'b'
#define OCTypeEncodeIsBaseType(code) (('a'<= code && code <= 'z') || ('A'<= code && code <= 'Z'))

static const char *OCTypeEncodeBlock = "@?";


NSString *startRemovePointerOfTypeEncode(const char *typeEncode);
NSUInteger startDetectPointerCount(const char *typeEncode);
NSString *startStructNameDetect(const char *typeEncode);
NSMutableArray * startStructDetect(const char *typeEncode);
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
