//
//  ORTypeVarPair+TypeEncode.m
//  OCRunner
//
//  Created by Jiang on 2020/5/26.
//  Copyright © 2020 SilverFruity. All rights reserved.
//

#import "ORTypeVarPair+TypeEncode.h"
#import "ORHandleTypeEncode.h"

@implementation ORTypeVarPair (TypeEncode)
- (const char *)typeEncode{
    if ([self.var isKindOfClass:[ORFuncVariable class]]) {
        __autoreleasing NSString *string = self.var.isBlock ? @"@?" : @"^";
        return string.UTF8String;
    }
    char encoding[128];
    memset(encoding, 0, 128);
#define append(str) strcat(encoding,str)
    NSInteger pointCount = self.var.ptCount;
    TypeKind type = self.type.type;
    while (pointCount > 0) {
        if (type == TypeBlock) {
            break;
        }
        if (type == TypeChar && pointCount == 1) {
            break;
        }
        if (type == TypeObject && pointCount == 1) {
            break;
        }
        append("^");
        pointCount--;
    }
    
#define CaseTypeEncoding(type,code)\
case type:\
append(code); break;
    
    switch (type) {
        case TypeChar:
        {
            if (self.var.ptCount > 0)
                append(OCTypeEncodeStringCString);
            else
                append(OCTypeEncodeStringChar);
            break;
        }
            CaseTypeEncoding(TypeInt, OCTypeEncodeStringInt)
            CaseTypeEncoding(TypeShort, OCTypeEncodeStringShort)
            CaseTypeEncoding(TypeLong, OCTypeEncodeStringLong)
            CaseTypeEncoding(TypeLongLong, OCTypeEncodeStringLongLong)
            CaseTypeEncoding(TypeUChar, OCTypeEncodeStringUChar)
            CaseTypeEncoding(TypeUInt, OCTypeEncodeStringUInt)
            CaseTypeEncoding(TypeUShort, OCTypeEncodeStringUShort)
            CaseTypeEncoding(TypeULong, OCTypeEncodeStringULong)
            CaseTypeEncoding(TypeULongLong, OCTypeEncodeStringULongLong)
            CaseTypeEncoding(TypeFloat, OCTypeEncodeStringFloat)
            CaseTypeEncoding(TypeDouble, OCTypeEncodeStringDouble)
            CaseTypeEncoding(TypeBOOL, OCTypeEncodeStringBOOL)
            CaseTypeEncoding(TypeVoid, OCTypeEncodeStringVoid)
            CaseTypeEncoding(TypeObject, OCTypeEncodeStringObject)
            CaseTypeEncoding(TypeId, OCTypeEncodeStringObject)
            CaseTypeEncoding(TypeClass, OCTypeEncodeStringClass)
            CaseTypeEncoding(TypeSEL, OCTypeEncodeStringSEL)
            CaseTypeEncoding(TypeBlock, OCTypeEncodeBlock)
        default:
            break;
    }
    append("\0");
    __autoreleasing NSString *resultValue = [NSString stringWithUTF8String:encoding];
    return resultValue.UTF8String;
}
@end






@implementation ORTypeVarPair(Instance)
+ (instancetype)typePairWithTypeKind:(TypeKind)type{
    ORTypeVarPair *typePair = [ORTypeVarPair new];
    typePair.type = [ORTypeSpecial new];
    typePair.type.type = type;
    typePair.var = [ORVariable new];
    return typePair;
}
+ (instancetype)objectTypePair{
    return [ORTypeVarPair typePairWithTypeKind:TypeObject];
}
+ (instancetype)pointerTypePair{
    ORTypeVarPair *typePair = [ORTypeVarPair typePairWithTypeKind:TypeObject];
    typePair.var.ptCount = 1;
    return typePair;
}
@end

ORTypeVarPair * ORTypeVarPairForTypeEncode(const char *typeEncode){
    TypeKind type = TypeVoid;
    ORTypeVarPair *pair = [ORTypeVarPair new];
    pair.var = [ORVariable new];
    pair.type = [ORTypeSpecial new];
    NSUInteger pointerCount;
    pointerCount = (NSInteger)startDetectPointerCount(typeEncode);
    NSString *typename = nil;
    const char *removedPointerEncode = startRemovePointerOfTypeEncode(typeEncode).UTF8String;
    switch (*removedPointerEncode) {
        case OCTypeEncodeChar: type =TypeChar; break;
        case OCTypeEncodeInt: type =TypeInt; break;
        case OCTypeEncodeShort: type =TypeShort; break;
        case OCTypeEncodeLong: type =TypeLong; break;
        case OCTypeEncodeLongLong: type =TypeLongLong; break;
        case OCTypeEncodeUChar: type =TypeUChar; break;
        case OCTypeEncodeUInt: type =TypeUInt; break;
        case OCTypeEncodeUShort: type =TypeUShort; break;
        case OCTypeEncodeULong: type =TypeULong; break;
        case OCTypeEncodeULongLong: type =TypeULongLong; break;
        case OCTypeEncodeBOOL: type =TypeBOOL; break;
        case OCTypeEncodeFloat: type =TypeFloat; break;
        case OCTypeEncodeDouble: type =TypeDouble; break;
        case OCTypeEncodeSEL: type =TypeSEL; break;
        case OCTypeEncodeCString:{
            type =TypeChar;
            pointerCount += 1;
            break;
        }
        case OCTypeEncodeClass:{
            type =TypeClass;
            typename = @"Class";
            break;
        }
        case OCTypeEncodeObject:{
            type =TypeObject;
            break;
        }
        case OCTypeEncodeStruct:{
            type =TypeStruct;
            typename = startStructNameDetect(typeEncode);
        }
        default:
            break;
    }
    pair.type.type = type;
    pair.var.ptCount = pointerCount;
    pair.type.name = typename;
    return pair;
}
