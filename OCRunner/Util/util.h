//
//  util.h
//  MangoFix
//
//  Created by jerry.yong on 2018/2/16.
//  Copyright © 2018年 yongpengliang. All rights reserved.
//

#ifndef util_h
#define util_h
#import <Foundation/Foundation.h>
#include <objc/runtime.h>
#import "RunnerClasses+Execute.h"

inline static  char *removeTypeEncodingPrefix(char *typeEncoding){
    if(typeEncoding == NULL) return NULL;
	while (*typeEncoding == 'r' || // const
		   *typeEncoding == 'n' || // in
		   *typeEncoding == 'N' || // inout
		   *typeEncoding == 'o' || // out
		   *typeEncoding == 'O' || // bycopy
		   *typeEncoding == 'R' || // byref
		   *typeEncoding == 'V') { // oneway
		typeEncoding++; // cutoff useless prefix
	}
	return typeEncoding;
}

FOUNDATION_EXPORT const char * mf_str_append(const char *str1, const char *str2);

FOUNDATION_EXPORT size_t mf_size_with_encoding(const char *typeEncoding);

FOUNDATION_EXPORT NSString * mf_struct_name_with_encoding(const char *typeEncoding);

//void mf_struct_data_with_dic(void *structData, NSDictionary *dic, MFStructDeclare *declare);

FOUNDATION_EXPORT objc_AssociationPolicy mf_AssociationPolicy_with_PropertyModifier(MFPropertyModifier);

#endif /* util_h */
