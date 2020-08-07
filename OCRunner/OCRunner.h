//
//  OCRunner.h
//  OCRunner
//
//  Created by Jiang on 2020/5/8.
//  Copyright © 2020 SilverFruity. All rights reserved.
//

#import <Foundation/Foundation.h>

//! Project version number for OCRunner.
FOUNDATION_EXPORT double OCRunnerVersionNumber;

//! Project version string for OCRunner.
FOUNDATION_EXPORT const unsigned char OCRunnerVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <OCRunner/PublicHeader.h>
#if __has_include("ffi.h")
#import <OCRunner/MFBlock.h>
#import <OCRunner/MFValue.h>
#import <OCRunner/MFScopeChain.h>
#import <OCRunner/RunnerClasses+Execute.h>
#import <OCRunner/ORInterpreter.h>
#import <OCRunner/ORStructDeclare.h>
#else
#import <OCRunnerArm64/MFBlock.h>
#import <OCRunnerArm64/MFValue.h>
#import <OCRunnerArm64/MFScopeChain.h>
#import <OCRunnerArm64/RunnerClasses+Execute.h>
#import <OCRunnerArm64/ORInterpreter.h>
#import <OCRunnerArm64/ORStructDeclare.h>
#endif
