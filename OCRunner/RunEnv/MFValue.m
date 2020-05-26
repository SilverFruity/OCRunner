//
//  MFValue .m
//  MangoFix
//
//  Created by jerry.yong on 2018/2/28.
//  Copyright © 2018年 yongpengliang. All rights reserved.
//

#import "MFValue.h"
#import "RunnerClasses.h"
#import "util.h"
#import "ORStructDeclare.h"
#import "ORTypeVarPair+TypeEncode.h"

extern BOOL MFStatementResultTypeIsReturn(MFStatementResultType type){
    return type & MFStatementResultTypeReturnMask;
}
@interface MFValue()
@end

@implementation MFValue
+ (instancetype)defaultValueWithTypeEncoding:(const char *)typeEncoding{
    typeEncoding = removeTypeEncodingPrefix((char *)typeEncoding);
    MFValue *value = [[MFValue alloc] initTypeEncode:typeEncoding pointer:NULL];
    *(NSUInteger *)value.pointer = 0;
    return value;
}
+ (instancetype)valueWithTypeKind:(TypeKind)TypeKind pointer:(void *)pointer{
    return [MFValue valueWithTypePair:[ORTypeVarPair typePairWithTypeKind:TypeKind] pointer:pointer];
}
+ (instancetype)valueWithTypePair:(ORTypeVarPair *)typePair pointer:(void *)pointer{
    return [[[self class] alloc] initTypeEncode:typePair.typeEncode pointer:pointer];
}
- (instancetype)initTypeEncode:(const char *)typeEncoding pointer:(void *)pointer{
    self = [super init];
    self.typeEncode = typeEncoding;
    if (pointer != NULL) {
        self.pointer = pointer;
    }else{
        _pointer = NULL;
    }
    return self;
}
- (void)setPointer:(void *)pointer{
    if (_pointer != NULL) {
        free(pointer);
    }
    NSUInteger size;
    NSGetSizeAndAlignment(self.typeEncode, &size, NULL);
    void *dst = malloc(size);
    memcpy(dst, pointer, size);
    _pointer = dst;
}
- (id)objectValue{
    return *(__strong id *)self.pointer;
}

- (void)dealloc{
    if (self.pointer != NULL) {
        free(self.pointer);
    }
}
- (void)setTypeEncode:(const char *)typeEncode{
    _typeEncode = typeEncode;
    if (strcmp(typeEncode, "@?") == 0) {
        self.type = TypeBlock;
        return;
    }
    self.pointerCount = (NSInteger)startDetectPointerCount(typeEncode);
    const char *removedPointerEncode = startRemovePointerOfTypeEncode(typeEncode).UTF8String;
    switch (*removedPointerEncode) {
        case 'c': self.type = TypeChar; break;
        case 'i': self.type = TypeInt; break;
        case 's': self.type = TypeShort; break;
        case 'l': self.type = TypeLong; break;
        case 'q': self.type = TypeLongLong; break;
        case 'C': self.type = TypeUChar; break;
        case 'I': self.type = TypeUInt; break;
        case 'S': self.type = TypeUShort; break;
        case 'L': self.type = TypeULong; break;
        case 'Q': self.type = TypeULongLong; break;
        case 'B': self.type = TypeBOOL; break;
        case 'f': self.type = TypeFloat; break;
        case 'd': self.type = TypeDouble; break;
        case ':': self.type = TypeSEL; break;
        case '*':{
            self.type = TypeChar;
            self.pointerCount += 1;
            break;
        }
        case '#':{
            self.typeName = @"Class";
            self.type = TypeClass;
            break;
        }
        case '@':{
            self.type = TypeObject;
            break;
        }
        case '{':{
            self.type = TypeStruct;
            self.typeName = startStructNameDetect(typeEncode);
            break;
        }
        default:
            break;
    }
}

- (BOOL)isSubtantial{
    BOOL result = NO;
    UnaryExecute(result, !, self);
    return !result;
}

- (BOOL)isMember{
    return self.type & TypeBaseMask;
}

- (BOOL)isPointer{
    return *self.typeEncode == '^';
}
- (MFValue *)subscriptGetWithIndex:(MFValue *)index{
    if (index.type & TypeBaseMask) {
        return [MFValue valueWithObject:self.objectValue[*(long long *)index.pointer]];
    }
    switch (index.type) {
        case TypeBlock:
        case TypeObject:
            return [MFValue valueWithObject:self.objectValue[index.objectValue]];
            break;
        case TypeClass:
            return [MFValue valueWithObject:self.objectValue[*(Class *)index.pointer]];
            break;
        default:
            //            NSCAssert(0, @"line:%zd, index operator can not use type: %@",expr.bottomExpr.lineNumber, bottomValue.type.typeName);
            break;
    }
    return nil;
}
- (void)subscriptSetValue:(MFValue *)value index:(MFValue *)index{
    if (index.type & TypeBaseMask) {
        self.objectValue[*(long long *)index.pointer] = value.objectValue;
    }
    switch (index.type) {
        case TypeBlock:
        case TypeObject:
            self.objectValue[index.objectValue] = value.objectValue;
            break;
        case TypeClass:
            self.objectValue[(id <NSCopying>)*(Class *)index.pointer] = value.objectValue;
            break;
        default:
            //            NSCAssert(0, @"line:%zd, index operator can not use type: %@",expr.bottomExpr.lineNumber, bottomValue.type.typeName);
            break;
    }
}

- (void)setTypeInfoWithValue:(MFValue *)value{
    self.typeEncode = value.typeEncode;
    self.type = value.type;
    self.typeName = value.typeName;
    self.pointerCount = value.pointerCount;
}
- (void)setTypeInfoWithTypePair:(ORTypeVarPair *)typePair{
    self.typeName = typePair.type.name;
    self.typeEncode = typePair.typeEncode;
    self.type = typePair.type.type;
    self.pointerCount = typePair.var.ptCount;
}

- (void)assignFrom:(MFValue *)src{
    [self setTypeInfoWithValue:src];
    self.pointer = src.pointer;
}

//FIXME: 编码问题以及引用相关问题，指针数转换..
- (void)writePointer:(void *)pointer typeEncode:(const char *)typeEncode{
    NSUInteger size;
    NSGetSizeAndAlignment(typeEncode, &size, NULL);
    memcpy(pointer, self.pointer, size);
}


@end

@implementation MFValue (Struct)
- (BOOL)isStruct{
    NSString *encode = [NSString stringWithUTF8String:self.typeEncode];
    NSString *ignorePointer = [encode stringByReplacingOccurrencesOfString:@"^" withString:@""];
    return *ignorePointer.UTF8String == '{';
}
- (BOOL)isStructPointer{
    return [self isStruct] && (*self.typeEncode == '^');
}
- (MFValue *)getPointerValueField{
    MFValue *field = [MFValue new];
    NSUInteger pointerCount = startDetectPointerCount(self.typeEncode);
    void *fieldPointer = self.pointer;
    while (pointerCount != 0) {
        fieldPointer = *(void **)fieldPointer;
        pointerCount--;
    }
    field.pointer = fieldPointer;
    field.typeEncode = startRemovePointerOfTypeEncode(self.typeEncode).UTF8String;
    field.pointerCount = 0;
    if (*field.typeEncode == '{') {
        NSString *encode = [NSString stringWithUTF8String:field.typeEncode];
        NSString *structName = [encode substringWithRange:NSMakeRange(1, strlen(field.typeEncode) - 2)];
        ORStructDeclare *declare = [[ORStructDeclareTable shareInstance] getStructDeclareWithName:structName];
        field.typeEncode = declare.typeEncoding;
        field.type = TypeStruct;
        field.typeName = structName;
    }
    return field;
}
- (MFValue *)fieldForKey:(NSString *)key{
    NSCAssert(self.type == TypeStruct, @"must be struct");
    NSString *structName = self.typeName;
    ORStructDeclare *declare = [[ORStructDeclareTable shareInstance] getStructDeclareWithName:structName];
    NSUInteger offset = declare.keyOffsets[key].unsignedIntegerValue;
    return [[MFValue alloc] initTypeEncode:declare.keyTypeEncodes[key].UTF8String pointer:self.pointer + offset];;
}
@end

@implementation MFValue (MFStatementResultType)
- (BOOL)isReturn{
    return MFStatementResultTypeIsReturn(self.resultType);
}
- (BOOL)isContinue{
    return self.resultType == MFStatementResultTypeContinue;
}
- (BOOL)isBreak{
    return self.resultType == MFStatementResultTypeBreak;
}
- (BOOL)isNormal{
    return self.resultType == MFStatementResultTypeNormal;
}
+ (instancetype)normalEnd{
    MFValue *value = [MFValue new];
    value.resultType = MFStatementResultTypeNormal;
    return value;
}

@end


@implementation MFValue (ValueType)
- (unsigned char)uCharValue{
    return *(unsigned char *)self.pointer;
}
- (unsigned short)uShortValue{
    return *(unsigned short *)self.pointer;
}
- (unsigned int)uIntValue{
    return *(unsigned int *)self.pointer;
}
- (unsigned long)uLongValue{
    return *(unsigned long *)self.pointer;
}
- (unsigned long long)uLongLongValue{
    return *(unsigned long long *)self.pointer;
}

- (char)charValue{
    return *(char *)self.pointer;
}
- (short)shortValue{
    return *(short *)self.pointer;
}
- (int)intValue{
    return *(int *)self.pointer;
}
- (long)longValue{
    return *(long *)self.pointer;
}
- (long long)longLongValue{
    return *(long long *)self.pointer;
}

- (BOOL)boolValue{
    return *(BOOL *)self.pointer;
}

- (float)floatValue{
    return *(float *)self.pointer;
}
- (double)doubleValue{
    return *(double *)self.pointer;
}
- (id)objectValue{
    return *(__strong id *)self.pointer;
}
- (Class)classValue{
    return *(Class *)self.pointer;
}
- (SEL)selValue{
    return *(SEL *)self.pointer;
}
+ (instancetype)voidValue{
    return [MFValue valueWithTypeKind:TypeVoid pointer:NULL];;
}

+ (instancetype)valueWithBOOL:(BOOL)boolValue{
    return [MFValue valueWithTypeKind:TypeChar pointer:&boolValue];
}
+ (instancetype)valueWithUChar:(unsigned char)uCharValue{
    return [MFValue valueWithTypeKind:TypeUChar pointer:&uCharValue];
}
+ (instancetype)valueWithUShort:(unsigned short)uShortValue{
    return [MFValue valueWithTypeKind:TypeUShort pointer:&uShortValue];
}
+ (instancetype)valueWithUInt:(unsigned int)uIntValue{
    return [MFValue valueWithTypeKind:TypeUInt pointer:&uIntValue];
}
+ (instancetype)valueWithULong:(unsigned long)uLongValue{
    return [MFValue valueWithTypeKind:TypeULong pointer:&uLongValue];
}
+ (instancetype)valueWithULongLong:(unsigned long long)uLongLongValue{
    return [MFValue valueWithTypeKind:TypeULongLong pointer:&uLongLongValue];
}
+ (instancetype)valueWithChar:(char)charValue{
    return [MFValue valueWithTypeKind:TypeChar pointer:&charValue];
}
+ (instancetype)valueWithShort:(short)shortValue{
    return [MFValue valueWithTypeKind:TypeShort pointer:&shortValue];
}
+ (instancetype)valueWithInt:(int)intValue{
    return [MFValue valueWithTypeKind:TypeInt pointer:&intValue];
}
+ (instancetype)valueWithLong:(long)longValue{
    return [MFValue valueWithTypeKind:TypeLong pointer:&longValue];
}
+ (instancetype)valueWithLongLong:(long long)longLongValue{
    return [MFValue valueWithTypeKind:TypeLongLong pointer:&longLongValue];
}
+ (instancetype)valueWithFloat:(float)floatValue{
    return [MFValue valueWithTypeKind:TypeFloat pointer:&floatValue];
}
+ (instancetype)valueWithDouble:(double)doubleValue{
    return [MFValue valueWithTypeKind:TypeDouble pointer:&doubleValue];
}
+ (instancetype)valueWithObject:(id)objValue{
    return [MFValue valueWithTypeKind:TypeObject pointer:&objValue];
}
+ (instancetype)valueWithBlock:(id)blockValue{
    return [MFValue valueWithTypeKind:TypeBlock pointer:&blockValue];
}
+ (instancetype)valueWithClass:(Class)clazzValue{
    return [MFValue valueWithTypeKind:TypeSEL pointer:&clazzValue];
}
+ (instancetype)valueWithSEL:(SEL)selValue{
    return [MFValue valueWithTypeKind:TypeSEL pointer:&selValue];
}
+ (instancetype)valueWithCString:(char *)pointerValue{
    return [[MFValue alloc] initTypeEncode:"*" pointer:&pointerValue];
}
+ (instancetype)valueWithPointer:(void *)pointerValue{
    return [[MFValue alloc] initTypeEncode:"^" pointer:&pointerValue];
}

@end
