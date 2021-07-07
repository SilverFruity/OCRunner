//
//  ORDeclaratorNode+TypeEncode.m
//  OCRunner
//
//  Created by Jiang on 2020/5/26.
//  Copyright © 2020 SilverFruity. All rights reserved.
//

#import "ORTypeVarPair+TypeEncode.h"
#import <oc2mangoLib/ocHandleTypeEncode.h>

@implementation ORDeclaratorNode (TypeEncode)
//- (const char *)baseTypeEncode{
//    return baseTypeEncode(self.type, self.var);;
//}
//- (const char *)blockSignature{
//    ORDeclaratorNode *var = (ORDeclaratorNode *)self.var;
//    if ([self isKindOfClass:[ORFunctionDeclNode class]] && self.var.isBlock) {
//        const char *returnEncode = [self baseTypeEncode];
//        __autoreleasing NSMutableString *result = [[NSString stringWithFormat:@"%s@?",returnEncode] mutableCopy];
//        for (ORDeclaratorNode *arg in var.pairs) {
//            [result appendFormat:@"%s",arg.typeEncode];
//        }
//        return result.UTF8String;
//    }
//    return [self typeEncode];
//}
//- (const char *)typeEncode{
//    return typeEncode(self.type, self.var);
//}
@end






@implementation ORDeclaratorNode(Instance)
+ (instancetype)typePairWithTypeKind:(OCType)type{
    ORDeclaratorNode *typePair = [ORDeclaratorNode new];
    typePair.type = [ORTypeNode new];
    typePair.type.type = type;
    typePair.var = [ORVariableNode new];
    return typePair;
}
+ (instancetype)objectTypePair{
    return [ORDeclaratorNode typePairWithTypeKind:OCTypeObject];
}
+ (instancetype)pointerTypePair{
    ORDeclaratorNode *typePair = [ORDeclaratorNode typePairWithTypeKind:OCTypeObject];
    typePair.var.ptCount = 1;
    return typePair;
}
@end

ORDeclaratorNode * ORDeclaratorNodeForTypeEncode(const char *typeEncode){
    OCType type = OCTypeVoid;
    ORDeclaratorNode *pair = [ORDeclaratorNode new];
    pair.var = [ORVariableNode new];
    pair.type = [ORTypeNode new];
    NSUInteger pointerCount;
    pointerCount = (NSInteger)startDetectPointerCount(typeEncode);
    NSString *typename = nil;
    const char *removedPointerEncode = startRemovePointerOfTypeEncode(typeEncode).UTF8String;
    switch (*removedPointerEncode) {
        case OCTypeChar: type =OCTypeChar; break;
        case OCTypeInt: type =OCTypeInt; break;
        case OCTypeShort: type =OCTypeShort; break;
        case OCTypeLong: type =OCTypeLong; break;
        case OCTypeLongLong: type =OCTypeLongLong; break;
        case OCTypeUChar: type =OCTypeUChar; break;
        case OCTypeUInt: type =OCTypeUInt; break;
        case OCTypeUShort: type =OCTypeUShort; break;
        case OCTypeULong: type =OCTypeULong; break;
        case OCTypeULongLong: type =OCTypeULongLong; break;
        case OCTypeBOOL: type =OCTypeBOOL; break;
        case OCTypeFloat: type =OCTypeFloat; break;
        case OCTypeDouble: type =OCTypeDouble; break;
        case OCTypeSEL: type =OCTypeSEL; break;
        case OCTypeCString:{
            type =OCTypeChar;
            pointerCount += 1;
            break;
        }
        case OCTypeClass:{
            type =OCTypeClass;
            typename = @"Class";
            break;
        }
        case OCTypeObject:{
            type =OCTypeObject;
            break;
        }
        case OCTypeStruct:{
            type =OCTypeStruct;
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
