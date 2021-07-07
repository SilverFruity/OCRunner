//
//  ORTypeVarPair+libffi.m
//  OCRunner
//
//  Created by Jiang on 2020/7/21.
//  Copyright © 2020 SilverFruity. All rights reserved.
//
#if __has_include("ffi.h")
#import "ORTypeVarPair+libffi.h"
#import "ORTypeVarPair+TypeEncode.h"
#import <oc2mangoLib/ocHandleTypeEncode.h>

ffi_type *typeEncode2ffi_type(const char *typeencode){
    //TypeEncode不能为空
    assert(typeencode != nil);
    switch (*typeencode) {
        case OCTypeChar:
            return &ffi_type_sint8;
        case OCTypeShort:
            return &ffi_type_sint16;
        case OCTypeInt:
            return &ffi_type_sint32;
        case OCTypeLong:
            return &ffi_type_sint32;
        case OCTypeLongLong:
            return &ffi_type_sint64;
            
        case OCTypeUChar:
            return &ffi_type_uint8;
        case OCTypeUShort:
            return &ffi_type_uint16;
        case OCTypeUInt:
            return &ffi_type_uint32;
        case OCTypeULong:
            return &ffi_type_uint32;
        case OCTypeULongLong:
            return &ffi_type_uint64;
            
        case OCTypeFloat:
            return &ffi_type_float;
        case OCTypeDouble:
            return &ffi_type_double;
            
        case OCTypeBOOL:
            return &ffi_type_uint8;
            
        case OCTypeVoid:
            return &ffi_type_void;
            
        case OCTypeObject:
        case OCTypeClass:
        case OCTypeSEL:
        case OCTypePointer:
        case OCTypeCString:
        case OCTypeArray:
        case OCTypeUnion:
            return &ffi_type_pointer;
            
        case OCTypeStruct:
        {
            ffi_type *type = malloc(sizeof(ffi_type));
//            type->type = FFI_TYPE_STRUCT;
//            type->alignment = 0;
//            NSString *structName = startStructNameDetect(typeencode);
//            assert(structName != nil);
//            ORStructDeclare *declare = [[ORTypeSymbolTable shareInstance] symbolItemForTypeName:structName].declare;
//            type->elements = malloc(sizeof(void *) * (declare.keys.count + 1));
//            type->size = sizeOfTypeEncode(declare.typeEncoding);
//            for (int i = 0; i < declare.keys.count; i++) {
//                type->elements[i] = typeEncode2ffi_type(declare.keyTypeEncodes[declare.keys[i]].UTF8String);
//            }
//            type->elements[declare.keys.count] = NULL;
            return type;
        }
    }
    //不支持的类型
    assert(false);
    return NULL;
}
@implementation ORDeclaratorNode (libffi)
- (ffi_type *)libffi_type{
    return typeEncode2ffi_type(self.typeEncode);
}
@end

#endif

