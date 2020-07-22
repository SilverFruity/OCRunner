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
#import "ORHandleTypeEncode.h"
#import "ORStructDeclare.h"

@implementation ORTypeVarPair (libffi)
- (ffi_type *)libffi_type{
    if (self.var.ptCount > 0) {
        return &ffi_type_pointer;
    }
    if ([self.var isKindOfClass:[ORFuncVariable class]]) {
        return &ffi_type_pointer;;
    }
    switch (self.type.type) {
        case TypeChar:
            return &ffi_type_sint8;
        case TypeShort:
            return &ffi_type_sint16;
        case TypeInt:
            return &ffi_type_sint32;
        case TypeLong:
            return &ffi_type_sint32;
        case TypeLongLong:
            return &ffi_type_sint64;
        case TypeUChar:
            return &ffi_type_uint8;
        case TypeUShort:
            return &ffi_type_uint16;
        case TypeUInt:
            return &ffi_type_uint32;
        case TypeULong:
            return &ffi_type_uint32;
        case TypeULongLong:
            return &ffi_type_uint64;
        case TypeFloat:
            return &ffi_type_float;
        case TypeDouble:
            return &ffi_type_double;
        case TypeBOOL:
            return &ffi_type_uint8;
        case TypeVoid:
            return &ffi_type_void;
        case TypeObject:
        case TypeId:
        case TypeClass:
        case TypeSEL:
        case TypeBlock:
            return &ffi_type_pointer;
        case TypeStruct:
        {
            ffi_type *type = malloc(sizeof(ffi_type));
            type->type = FFI_TYPE_STRUCT;
            NSString *structName = self.type.name;
            assert(structName != nil);
            ORStructDeclare *declare = [[ORStructDeclareTable shareInstance] getStructDeclareWithName:structName];
            type->elements = malloc(sizeof(void *) * (declare.keys.count + 1));
            type->size = sizeOfTypeEncode(declare.typeEncoding);
            for (int i = 0; i < declare.keys.count; i++) {
                NSString *key = declare.keys[i];
                const char *typeEncode = declare.keyTypeEncodes[key].UTF8String;
                ORTypeVarPair *element = ORTypeVarPairForTypeEncode(typeEncode);
                type->elements[i] = element.libffi_type;
            }
            type->elements[declare.keys.count] = NULL;
            return type;
        }
        default:
            break;
    }
    return NULL;
}
@end

#endif

