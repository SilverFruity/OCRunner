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
static const char *baseTypeEncode(ORTypeSpecial *typeSpecial, ORVariable *var){
    TypeKind type = typeSpecial.type;
    char encoding[128];
    memset(encoding, 0, 128);
#define append(str) strcat(encoding,str)
    NSInteger tmpPtCount = var.ptCount;
    while (tmpPtCount > 0) {
        if (type == TypeBlock) {
            break;
        }
        if (type == TypeChar && tmpPtCount == 1) {
            break;
        }
        if (type == TypeObject && tmpPtCount == 1) {
            break;
        }
        append("^");
        tmpPtCount--;
    }
    
#define CaseTypeEncoding(type,code)\
case type:\
append(code); break;
    
    switch (type) {
        case TypeChar:
        {
            if (var.ptCount > 0)
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
static const char *cArrayTypeEncode(ORTypeSpecial *typeSpecial, ORCArrayVariable *var);
static const char *typeEncode(ORTypeSpecial *typeSpecial, ORVariable *var){
    TypeKind type = typeSpecial.type;
    if ([var isKindOfClass:[ORFuncVariable class]]) {
        // Block的typeEncode
        if (var.isBlock) {
            return @"@?".UTF8String;
        }
    }else if ([var isKindOfClass:[ORCArrayVariable class]]){
        ORSymbolItem *item = [[ORTypeSymbolTable shareInstance] symbolItemForNode:var];
        if (item) {
            return item.typeEncode.UTF8String;
        }
        const char *result = cArrayTypeEncode(typeSpecial, (ORCArrayVariable *)var);
        [[ORTypeSymbolTable shareInstance] addCArray:(ORCArrayVariable *)var typeEncode:result];
        return result;
    }
    ORSymbolItem *item = [[ORTypeSymbolTable shareInstance] symbolItemForTypeName:typeSpecial.name];
    if (item) {
        return item.typeEncode.UTF8String;
    }
    if (var.ptCount == 0 && type == TypeObject){
        ORSymbolItem *item = [[ORTypeSymbolTable shareInstance] symbolItemForTypeName:typeSpecial.name];
        if (item) {
            return item.typeEncode.UTF8String;
        }
    }
    return baseTypeEncode(typeSpecial, var);
}
static const char *cArrayTypeEncode(ORTypeSpecial *typeSpecial, ORCArrayVariable *var){
    if ([(ORIntegerValue *)var.capacity value] == 0) {
        return [NSString stringWithFormat:@"^%s",typeEncode(typeSpecial, nil)].UTF8String;
    }
    ORCArrayVariable *tmp = var;
    NSMutableArray *nodes = [NSMutableArray array];
    while (tmp) {
        [nodes insertObject:tmp atIndex:0];
        tmp = tmp.prev;
    }
    char result[100] = {0};
    char buffer[50]  = {0};
    char rights[20]  = {0};
    for (int i = 0; i < nodes.count; i++) {
        ORCArrayVariable *item = nodes[i];
        sprintf(buffer, "[%lld", [(ORIntegerValue *)item.capacity value]);
        strcat(result, buffer);
        if (i != nodes.count - 1) {
            strcat(rights, "]");
        }else{
            sprintf(buffer, "%s]", typeEncode(typeSpecial, nil));
            strcat(result, buffer);
        }
    }
    strcat(result, rights);
    NSString *str = [NSString stringWithUTF8String:result];
    return str.UTF8String;
}

@implementation ORTypeVarPair (TypeEncode)
- (const char *)baseTypeEncode{
    return baseTypeEncode(self.type, self.var);;
}
- (const char *)blockSignature{
    ORFuncVariable *var = (ORFuncVariable *)self.var;
    if ([var isKindOfClass:[ORFuncVariable class]] && var.isBlock) {
        const char *returnEncode = [self baseTypeEncode];
        __autoreleasing NSMutableString *result = [[NSString stringWithFormat:@"%s@?",returnEncode] mutableCopy];
        for (ORTypeVarPair *arg in var.pairs) {
            [result appendFormat:@"%s",arg.typeEncode];
        }
        return result.UTF8String;
    }
    return [self typeEncode];
}
- (const char *)typeEncode{
    return typeEncode(self.type, self.var);
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
