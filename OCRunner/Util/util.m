//
//  util.m
//  MangoFix
//
//  Created by jerry.yong on 2018/2/16.
//  Copyright © 2018年 yongpengliang. All rights reserved.
//


#import "util.h"
#import "runenv.h"


const char * mf_str_append(const char *str1, const char *str2){
	size_t len = strlen(str1) + strlen(str2);
	char *ret = malloc(sizeof(char) * (len + 1));
	strcpy(ret, str1);
	strcat(ret, str2);
	return ret;
}

static ffi_type *_ffi_type_with_type_encoding(NSString *typeEncoding){
	char *code = (char *)typeEncoding.UTF8String;
	switch (code[0]) {
		case 'v':
			return &ffi_type_void;
		case 'c':
			return &ffi_type_schar;
		case 'C':
			return &ffi_type_uchar;
		case 's':
			return &ffi_type_sshort;
		case 'S':
			return &ffi_type_ushort;
		case 'i':
			return &ffi_type_sint;
		case 'I':
			return &ffi_type_uint;
		case 'l':
			return &ffi_type_slong;
		case 'L':
			return &ffi_type_ulong;
		case 'q':
			return &ffi_type_sint64;
		case 'Q':
			return &ffi_type_uint64;
		case 'f':
			return &ffi_type_float;
		case 'd':
			return &ffi_type_double;
		case 'D':
			return &ffi_type_longdouble;
		case 'B':
			return &ffi_type_uint8;
        case '*':
            return &ffi_type_pointer;
		case '^':
			return &ffi_type_pointer;
		case '@':
			return &ffi_type_pointer;
		case '#':
			return &ffi_type_pointer;
        case ':':
            return &ffi_type_pointer;
		case '{':
		{
			ffi_type *type = malloc(sizeof(ffi_type));
			type->size = 0;
			type->alignment = 0;
			type->elements = NULL;
			type->type = FFI_TYPE_STRUCT;

			NSString *types = [typeEncoding substringToIndex:typeEncoding.length-1];
			NSUInteger location = [types rangeOfString:@"="].location+1;
			types = [types substringFromIndex:location];
			char *typesCode = (char *)[types UTF8String];


			size_t index = 0;
			size_t subCount = 0;
			NSString *subTypeEncoding;

			while (typesCode[index]) {
				if (typesCode[index] == '{') {
					size_t stackSize = 1;
					size_t end = index + 1;
					for (char c = typesCode[end]; c ; end++, c = typesCode[end]) {
						if (c == '{') {
							stackSize++;
						}else if (c == '}') {
							stackSize--;
							if (stackSize == 0) {
								break;
							}
						}
					}
					subTypeEncoding = [types substringWithRange:NSMakeRange(index, end - index + 1)];
					index = end + 1;
				}else{
					subTypeEncoding = [types substringWithRange:NSMakeRange(index, 1)];
					index++;
				}

				ffi_type *subFfiType = _ffi_type_with_type_encoding(subTypeEncoding);
				type->size += subFfiType->size;
				type->elements = realloc((void*)(type->elements),sizeof(ffi_type *) * (subCount + 1));
				type->elements[subCount] = subFfiType;
				subCount++;
			}

			type->elements = realloc((void*)(type->elements), sizeof(ffi_type *) * (subCount + 1));
			type->elements[subCount] = NULL;
			return type;

		}
	}
	return NULL;
}

ffi_type *mf_ffi_type_with_type_encoding(const char *typeEncoding){
    return _ffi_type_with_type_encoding([NSString stringWithUTF8String:typeEncoding]);
}

size_t mf_size_with_encoding(const char *typeEncoding){
    NSUInteger size;
    NSUInteger alignp;
    NSGetSizeAndAlignment(typeEncoding, &size, &alignp);
    return size;
}


objc_AssociationPolicy mf_AssociationPolicy_with_PropertyModifier(MFPropertyModifier modifier){
    objc_AssociationPolicy associationPolicy = OBJC_ASSOCIATION_RETAIN_NONATOMIC;
    switch (modifier & MFPropertyModifierMemMask) {
        case MFPropertyModifierMemStrong:
        case MFPropertyModifierMemWeak:
        case MFPropertyModifierMemAssign:
            switch (modifier & MFPropertyModifierAtomicMask) {
                case MFPropertyModifierAtomic:
                    associationPolicy = OBJC_ASSOCIATION_RETAIN;
                    break;
                case MFPropertyModifierNonatomic:
                    associationPolicy = OBJC_ASSOCIATION_RETAIN_NONATOMIC;
                    break;
                default:
                    break;
            }
            break;
        case MFPropertyModifierMemCopy:
            switch (modifier & MFPropertyModifierAtomicMask) {
                case MFPropertyModifierAtomic:
                    associationPolicy = OBJC_ASSOCIATION_COPY;
                    break;
                case MFPropertyModifierNonatomic:
                    associationPolicy = OBJC_ASSOCIATION_COPY_NONATOMIC;
                    break;
                default:
                    break;
            }
            break;
            
        default:
            break;
    }
    return associationPolicy;
}

