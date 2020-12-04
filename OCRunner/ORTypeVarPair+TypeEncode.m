//
//  ORTypeVarPair+TypeEncode.m
//  OCRunner
//
//  Created by Jiang on 2020/5/26.
//  Copyright © 2020 SilverFruity. All rights reserved.
//

#import "ORTypeVarPair+TypeEncode.h"
#import "ORHandleTypeEncode.h"
#import "ORStructDeclare.h"

@implementation ORTypeVarPair (TypeEncode)
- (const char *)typeEncode{
    TypeKind type = self.type.type;
    if ([self.var isKindOfClass:[ORFuncVariable class]]) {
        // Block的typeEncode
        if (self.var.isBlock) {
            return @"@?".UTF8String;
        }
    }
    if (type == TypeStruct && self.var.ptCount == 0) {
        ORStructDeclare *declare = [[ORStructDeclareTable shareInstance] getStructDeclareWithName:self.type.name];
        return declare.typeEncoding;
    }
    char encoding[128];
    memset(encoding, 0, 128);
#define append(str) strcat(encoding,str)
    NSInteger pointCount = self.var.ptCount;
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
                append(OCTypeStringCString);
            else
                append(OCTypeStringChar);
            break;
        }
            CaseTypeEncoding(TypeInt, OCTypeStringInt)
            CaseTypeEncoding(TypeShort, OCTypeStringShort)
            CaseTypeEncoding(TypeLong, OCTypeStringLong)
            CaseTypeEncoding(TypeLongLong, OCTypeStringLongLong)
            CaseTypeEncoding(TypeUChar, OCTypeStringUChar)
            CaseTypeEncoding(TypeUInt, OCTypeStringUInt)
            CaseTypeEncoding(TypeUShort, OCTypeStringUShort)
            CaseTypeEncoding(TypeULong, OCTypeStringULong)
            CaseTypeEncoding(TypeULongLong, OCTypeStringULongLong)
            CaseTypeEncoding(TypeFloat, OCTypeStringFloat)
            CaseTypeEncoding(TypeDouble, OCTypeStringDouble)
            CaseTypeEncoding(TypeBOOL, OCTypeStringBOOL)
            CaseTypeEncoding(TypeVoid, OCTypeStringVoid)
            CaseTypeEncoding(TypeObject, OCTypeStringObject)
            CaseTypeEncoding(TypeId, OCTypeStringObject)
            CaseTypeEncoding(TypeClass, OCTypeStringClass)
            CaseTypeEncoding(TypeSEL, OCTypeStringSEL)
            CaseTypeEncoding(TypeBlock, OCTypeStringBlock)
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
        case OCTypeChar: type =TypeChar; break;
        case OCTypeInt: type =TypeInt; break;
        case OCTypeShort: type =TypeShort; break;
        case OCTypeLong: type =TypeLong; break;
        case OCTypeLongLong: type =TypeLongLong; break;
        case OCTypeUChar: type =TypeUChar; break;
        case OCTypeUInt: type =TypeUInt; break;
        case OCTypeUShort: type =TypeUShort; break;
        case OCTypeULong: type =TypeULong; break;
        case OCTypeULongLong: type =TypeULongLong; break;
        case OCTypeBOOL: type =TypeBOOL; break;
        case OCTypeFloat: type =TypeFloat; break;
        case OCTypeDouble: type =TypeDouble; break;
        case OCTypeSEL: type =TypeSEL; break;
        case OCTypeCString:{
            type =TypeChar;
            pointerCount += 1;
            break;
        }
        case OCTypeClass:{
            type =TypeClass;
            typename = @"Class";
            break;
        }
        case OCTypeObject:{
            type =TypeObject;
            break;
        }
        case OCTypeStruct:{
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
