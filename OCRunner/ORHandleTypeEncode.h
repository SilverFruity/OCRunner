//
//  ORHandleTypeEncode.h
//  OCRunner
//
//  Created by Jiang on 2020/7/15.
//  Copyright © 2020 SilverFruity. All rights reserved.
//

#import <Foundation/Foundation.h>

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
