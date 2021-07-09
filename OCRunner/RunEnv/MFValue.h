//
//  MFValue .h
//  MangoFix
//
//  Created by jerry.yong on 2018/2/28.
//  Copyright © 2018年 yongpengliang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RunnerClasses+Execute.h"
#import <oc2mangoLib/ocHandleTypeEncode.h>
#import "or_value.h"


NS_ASSUME_NONNULL_BEGIN

@class ORTypeVarPair;


ORTypeVarPair *typePairWithTypeEncode(const char *tyepEncode);

@interface MFValue : NSObject <NSCopying>
{
    @public
    or_value_box realBaseValue;
    @protected
    __strong id _strongObjectValue;
    __weak id _weakObjectValue;
}
@property (assign,nonatomic)DeclarationModifier modifier;
@property (assign,nonatomic)OCType type;
@property (strong,nonatomic)NSString *typeName;
@property (assign,nonatomic)NSInteger pointerCount;
@property (nonatomic,assign)const char* typeEncode;
@property (nonatomic,assign, nullable)void *pointer;
- (void)setValuePointerWithNoCopy:(void *)pointer;
- (void)setDefaultValue;
- (BOOL)isBlockValue;

+ (instancetype)defaultValueWithTypeEncoding:(const char *)typeEncoding;
+ (instancetype)valueWithTypeEncode:(const char *)typeEncode pointer:(nullable void *)pointer;
+ (instancetype)valueWithORCaculateValue:(or_value)value;
- (instancetype)initTypeEncode:(const char *)tyepEncode pointer:(nullable void *)pointer;

- (void)writePointer:(void *)pointer typeEncode:(const char *)typeEncode;
- (void)setTypeInfoWithValue:(MFValue *)value;

- (void)assignWithNewValue:(MFValue *)src;

- (BOOL)isPointer;
- (BOOL)isSubtantial;
- (BOOL)isInteger;
- (BOOL)isFloat;
- (BOOL)isObject;
- (NSUInteger)memerySize;
- (MFValue *)subscriptGetWithIndex:(MFValue *)index;
- (void)subscriptSetValue:(MFValue *)value index:(MFValue *)index;

///  仅仅针对函数指针变量的调用，记录签名信息， int (*xxx)(int a ) = &x;  xxxx();
@property (nonatomic,strong)ORFunctionDeclNode *funDecl;
@end

@interface MFValue (Struct)
- (BOOL)isStruct;
- (BOOL)isStructPointer;
- (BOOL)isStructValueOrPointer;
- (BOOL)isHFAStruct;
- (NSUInteger)structLayoutFieldCount;
- (void)setFieldWithValue:(MFValue *)value forKey:(NSString *)key;
- (MFValue *)fieldForKey:(NSString *)key;
- (MFValue *)fieldNoCopyForKey:(NSString *)key;
- (MFValue *)getResutlInPointer;
- (void)enumerateStructFieldsUsingBlock:(void (^)(MFValue *field, NSUInteger idx, BOOL *stop))block;
@end

@interface MFValue (Union)
- (void)setUnionFieldWithValue:(MFValue *)value forKey:(NSString *)key;
- (MFValue *)unionFieldForKey:(NSString *)key;
@end

@interface MFValue  (CArray)
- (MFValue *)cArraySubscriptGetValueWithIndex:(MFValue *)index;
- (void)cArraySubscriptSetValue:(MFValue *)value index:(MFValue *)index;
@end


@interface MFValue (ValueType)


@property (assign, nonatomic, readonly) unsigned char uCharValue;
@property (assign, nonatomic, readonly) unsigned short uShortValue;
@property (assign, nonatomic, readonly) unsigned int uIntValue;
@property (assign, nonatomic, readonly) unsigned long uLongValue;
@property (assign, nonatomic, readonly) unsigned long long uLongLongValue;

@property (assign, nonatomic, readonly) char charValue;
@property (assign, nonatomic, readonly) short shortValue;
@property (assign, nonatomic, readonly) int intValue;
@property (assign, nonatomic, readonly) long longValue;
@property (assign, nonatomic, readonly) long long longlongValue;

@property (assign, nonatomic, readonly) BOOL boolValue;

@property (assign, nonatomic, readonly) float floatValue;
@property (assign, nonatomic, readonly) double doubleValue;

@property (nonatomic, nullable, readonly) id objectValue;
@property (nonatomic, nullable, readonly) void *classValue;
@property (nonatomic, nullable, readonly) SEL selValue;
@property (nonatomic, nullable, readonly) char *cStringValue;
+ (instancetype)nullValue;
+ (instancetype)voidValue;
+ (instancetype)valueWithBOOL:(BOOL)boolValue;
+ (instancetype)valueWithUChar:(unsigned char)uCharValue;
+ (instancetype)valueWithUShort:(unsigned short)uShortValue;
+ (instancetype)valueWithUInt:(unsigned int)uIntValue;
+ (instancetype)valueWithULong:(unsigned long)uLongValue;
+ (instancetype)valueWithULongLong:(unsigned long long)uLongLongValue;
+ (instancetype)valueWithChar:(char)charValue;
+ (instancetype)valueWithShort:(short)shortValue;
+ (instancetype)valueWithInt:(int)intValue;
+ (instancetype)valueWithLong:(long)longValue;
+ (instancetype)valueWithLongLong:(long long)longLongValue;
+ (instancetype)valueWithFloat:(float)floatValue;
+ (instancetype)valueWithDouble:(double)doubleValue;
+ (instancetype)valueWithObject:(nullable id)objValue;
+ (instancetype)valueWithUnownedObject:(nullable id)objValue;
+ (instancetype)valueWithWeakObject:(nullable id)objValue;
+ (instancetype)valueWithBlock:(nullable id)blockValue;
+ (instancetype)valueWithClass:(nullable Class)clazzValue;
+ (instancetype)valueWithSEL:(SEL)selValue;
+ (instancetype)valueWithCString:(char *)pointerValue;
+ (instancetype)valueWithPointer:(nullable void *)pointerValue;
@end
NS_ASSUME_NONNULL_END
