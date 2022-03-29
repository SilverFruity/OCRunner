//
//  ORTypeVarPair+libffi.h
//  OCRunner
//
//  Created by Jiang on 2020/7/21.
//  Copyright © 2020 SilverFruity. All rights reserved.
//

#import "RunnerClasses+Execute.h"
#if __has_include("ffi.h")
#import "ffi.h"

struct ORFuncCallFFiTypeFreeList {
    void *_Nullable *_Nonnull list;
    int maxLength;
    int cursor;
};

NS_ASSUME_NONNULL_BEGIN

__attribute__((overloadable))
ffi_type *_Nullable typeEncode2ffi_type(const char *typeencode);

ffi_type *_Nullable typeEncode2ffi_type(const char *typeencode,
                              struct ORFuncCallFFiTypeFreeList *_Nullable destroyList);
NS_ASSUME_NONNULL_END
#endif
