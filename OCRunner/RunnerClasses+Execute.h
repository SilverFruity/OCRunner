//
//  ORunner+Execute.h
//  MangoFix
//
//  Created by Jiang on 2020/5/8.
//  Copyright © 2020 yongpengliang. All rights reserved.
//

#import <ORPatchFile/ORPatchFile.h>
//#import <oc2mangoLib/oc2mangoLib.h>
#import <objc/runtime.h>
#import "or_value.h"

NS_ASSUME_NONNULL_BEGIN

@class MFValue;
@class MFScopeChain;
@class ORInterpreter;

#ifdef __cplusplus
extern "C" {
#endif //__cplusplus

void *thread_current_context();

void eval(ORInterpreter *inter, void *ctx, MFScopeChain *scope, ORNode *node);

#ifdef __cplusplus
}
#endif //__cplusplus

NS_ASSUME_NONNULL_END

