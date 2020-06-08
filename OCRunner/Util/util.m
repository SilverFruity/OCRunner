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

