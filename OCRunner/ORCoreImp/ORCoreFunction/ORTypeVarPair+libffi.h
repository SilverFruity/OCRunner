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
#import <oc2mangoLib/InitialSymbolTableVisitor.h>

NS_ASSUME_NONNULL_BEGIN
@class ocDecl;
ffi_type *ocDecl2ffi_type(ocDecl *decl);
ffi_type *typeEncode2ffi_type(const char *typeencode);

@interface ocDecl (libffi)
- (ffi_type *)libffi_type;
@end
NS_ASSUME_NONNULL_END
#endif
