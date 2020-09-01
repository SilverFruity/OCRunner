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
NS_ASSUME_NONNULL_BEGIN

 ffi_type *_Nullable typeEncode2ffi_type(const char *typeencode);

@interface ORTypeVarPair (libffi)
- (ffi_type *)libffi_type;
@end
NS_ASSUME_NONNULL_END
#endif
