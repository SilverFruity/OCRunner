//
//  ORTypeVarPair+TypeEncode.m
//  OCRunner
//
//  Created by Jiang on 2020/5/26.
//  Copyright © 2020 SilverFruity. All rights reserved.
//

#import "ORTypeVarPair+TypeEncode.h"

@implementation ORTypeVarPair (TypeEncode)
- (const char *)typeEncode{
    char encoding[20];
    memset(encoding, 0, 20);
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
    char * result = malloc(sizeof(char) * 20);
    strcpy(result, encoding);
    return result;
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
