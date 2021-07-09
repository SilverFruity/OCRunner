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
@class ORThreadContext;

or_value eval(ORInterpreter *inter, ORThreadContext *ctx, MFScopeChain *scope, ORNode *node);


NS_ASSUME_NONNULL_END

