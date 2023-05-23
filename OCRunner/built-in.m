//
//  built-in.m
//  MangoFix
//
//  Created by jerry.yong on 2018/2/28.
//  Copyright © 2018年 yongpengliang. All rights reserved.
//

#import "MFValue.h"
#import "MFScopeChain.h"
#import "ORStructDeclare.h"
#import <UIKit/UIKit.h>
#import "ORSystemFunctionPointerTable.h"
static void add_gcd_build_in(MFScopeChain *scope){
    [scope setValue:[MFValue valueWithBlock:^void(dispatch_once_t *onceTokenPtr,
                                                                  dispatch_block_t _Nullable handler){
        dispatch_once(onceTokenPtr,handler);
    }] withIndentifier:@"dispatch_once"];
    
    [ORSystemFunctionPointerTable reg:@"dispatch_get_main_queue" pointer:&dispatch_get_main_queue];
    [ORSystemFunctionPointerTable reg:@"dispatch_block_notify" pointer:&dispatch_block_notify];
    [ORSystemFunctionPointerTable reg:@"dispatch_block_testcancel" pointer:&dispatch_block_testcancel];
    [ORSystemFunctionPointerTable reg:@"CATransform3DIsIdentity" pointer:&CATransform3DIsIdentity];
    [ORSystemFunctionPointerTable reg:@"CATransform3DEqualToTransform" pointer:&CATransform3DEqualToTransform];
    [ORSystemFunctionPointerTable reg:@"CATransform3DMakeTranslation" pointer:&CATransform3DMakeTranslation];
    [ORSystemFunctionPointerTable reg:@"CATransform3DMakeRotation" pointer:&CATransform3DMakeRotation];
    [ORSystemFunctionPointerTable reg:@"CATransform3DTranslate" pointer:&CATransform3DTranslate];
    [ORSystemFunctionPointerTable reg:@"CATransform3DRotate" pointer:&CATransform3DRotate];
    [ORSystemFunctionPointerTable reg:@"CATransform3DConcat" pointer:&CATransform3DConcat];
    [ORSystemFunctionPointerTable reg:@"CATransform3DInvert" pointer:&CATransform3DInvert];
    [ORSystemFunctionPointerTable reg:@"CGAffineTransformMake" pointer:&CGAffineTransformMake];
    [ORSystemFunctionPointerTable reg:@"CGPointEqualToPoint" pointer:&CGPointEqualToPoint];
    [ORSystemFunctionPointerTable reg:@"CGSizeEqualToSize" pointer:&CGSizeEqualToSize];
    [ORSystemFunctionPointerTable reg:@"dispatch_block_perform" pointer:&dispatch_block_perform];

    /* queue */
    [scope setValue:[MFValue valueWithLongLong:DISPATCH_QUEUE_PRIORITY_HIGH] withIndentifier:@"DISPATCH_QUEUE_PRIORITY_HIGH"];
    [scope setValue:[MFValue valueWithLongLong:DISPATCH_QUEUE_PRIORITY_DEFAULT] withIndentifier:@"DISPATCH_QUEUE_PRIORITY_DEFAULT"];
    [scope setValue:[MFValue valueWithLongLong:DISPATCH_QUEUE_PRIORITY_LOW] withIndentifier:@"DISPATCH_QUEUE_PRIORITY_LOW"];
    [scope setValue:[MFValue valueWithLongLong:DISPATCH_QUEUE_PRIORITY_BACKGROUND] withIndentifier:@"DISPATCH_QUEUE_PRIORITY_BACKGROUND"];
    
    [scope setValue:[MFValue valueWithObject:DISPATCH_QUEUE_CONCURRENT] withIndentifier:@"DISPATCH_QUEUE_CONCURRENT"];
    [scope setValue:[MFValue nullValue] withIndentifier:@"DISPATCH_QUEUE_SERIAL"];
    
    /*dispatch_source*/
    [scope setValue:[MFValue valueWithPointer:(void *)DISPATCH_SOURCE_TYPE_PROC] withIndentifier:@"DISPATCH_SOURCE_TYPE_PROC"];
    [scope setValue:[MFValue valueWithPointer:(void *)DISPATCH_SOURCE_TYPE_READ] withIndentifier:@"DISPATCH_SOURCE_TYPE_READ"];
    [scope setValue:[MFValue valueWithPointer:(void *)DISPATCH_SOURCE_TYPE_SIGNAL] withIndentifier:@"DISPATCH_SOURCE_TYPE_SIGNAL"];
    [scope setValue:[MFValue valueWithPointer:(void *)DISPATCH_SOURCE_TYPE_TIMER] withIndentifier:@"DISPATCH_SOURCE_TYPE_TIMER"];
    [scope setValue:[MFValue valueWithPointer:(void *)DISPATCH_SOURCE_TYPE_VNODE] withIndentifier:@"DISPATCH_SOURCE_TYPE_VNODE"];
    [scope setValue:[MFValue valueWithPointer:(void *)DISPATCH_SOURCE_TYPE_WRITE] withIndentifier:@"DISPATCH_SOURCE_TYPE_WRITE"];
}

static void add_build_in_function(MFScopeChain *scope){

    
}
static void add_build_in_var(MFScopeChain *scope){
    [scope setValue:[MFValue valueWithObject:NSRunLoopCommonModes] withIndentifier:@"NSRunLoopCommonModes"];
    [scope setValue:[MFValue valueWithObject:NSDefaultRunLoopMode] withIndentifier:@"NSDefaultRunLoopMode"];
    
    [scope setValue:[MFValue valueWithDouble:M_PI] withIndentifier:@"M_PI"];
    [scope setValue:[MFValue valueWithDouble:M_PI_2] withIndentifier:@"M_PI_2"];
    [scope setValue:[MFValue valueWithDouble:M_PI_4] withIndentifier:@"M_PI_4"];
    [scope setValue:[MFValue valueWithDouble:M_1_PI] withIndentifier:@"M_1_PI"];
    [scope setValue:[MFValue valueWithDouble:M_2_PI] withIndentifier:@"M_2_PI"];
    
    UIDevice *device = [UIDevice currentDevice];
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    [scope setValue:[MFValue valueWithObject:device.systemVersion] withIndentifier:@"$systemVersion"];
    [scope setValue:[MFValue valueWithObject:[infoDictionary objectForKey:@"CFBundleShortVersionString"]] withIndentifier:@"$appVersion"];
    [scope setValue:[MFValue valueWithObject:[infoDictionary objectForKey:@"CFBundleVersion"]] withIndentifier:@"$buildVersion"];
    
#if defined(__LP64__) && __LP64__
    BOOL is32BitDevice = NO;
#else
    BOOL is32BitDevice = YES;
#endif
    [scope setValue:[MFValue valueWithBOOL:is32BitDevice ] withIndentifier:@"$is32BitDevice"];;
}
#import "ORInterpreter.h"
void mf_add_built_in(MFScopeChain *scope){
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        add_build_in_function(scope);
        add_build_in_var(scope);
        add_gcd_build_in(scope);
    });
}


