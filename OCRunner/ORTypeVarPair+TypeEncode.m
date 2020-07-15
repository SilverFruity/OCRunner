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
                append("*");
            else
                append("c");
            break;
        }
            CaseTypeEncoding(TypeInt, "i")
            CaseTypeEncoding(TypeShort, "s")
            CaseTypeEncoding(TypeLong, "l")
            CaseTypeEncoding(TypeLongLong, "q")
            CaseTypeEncoding(TypeUChar, "C")
            CaseTypeEncoding(TypeUInt, "I")
            CaseTypeEncoding(TypeUShort, "S")
            CaseTypeEncoding(TypeULong, "L")
            CaseTypeEncoding(TypeULongLong, "Q")
            CaseTypeEncoding(TypeFloat, "f")
            CaseTypeEncoding(TypeDouble, "d")
            CaseTypeEncoding(TypeBOOL, "B")
            CaseTypeEncoding(TypeVoid, "v")
            CaseTypeEncoding(TypeObject, "@")
            CaseTypeEncoding(TypeId, "@")
            CaseTypeEncoding(TypeClass, "#")
            CaseTypeEncoding(TypeSEL, ":")
            CaseTypeEncoding(TypeBlock, "@?")
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
        case 'c': type =TypeChar; break;
        case 'i': type =TypeInt; break;
        case 's': type =TypeShort; break;
        case 'l': type =TypeLong; break;
        case 'q': type =TypeLongLong; break;
        case 'C': type =TypeUChar; break;
        case 'I': type =TypeUInt; break;
        case 'S': type =TypeUShort; break;
        case 'L': type =TypeULong; break;
        case 'Q': type =TypeULongLong; break;
        case 'B': type =TypeBOOL; break;
        case 'f': type =TypeFloat; break;
        case 'd': type =TypeDouble; break;
        case ':': type =TypeSEL; break;
        case '*':{
            type =TypeChar;
            pointerCount += 1;
            break;
        }
        case '#':{
            type =TypeClass;
            typename = @"Class";
        }
        case '@':{
            type =TypeObject;
            break;
        }
        case '{':{
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
