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
#import "ORSystemFunctionTable.h"
static void add_gcd_build_in(){
    [MFScopeChain.topScope setValue:[MFValue valueWithBlock:^void(dispatch_once_t *onceTokenPtr,
                                                                  dispatch_block_t _Nullable handler){
        dispatch_once(onceTokenPtr,handler);
    }] withIndentifier:@"dispatch_once"];
    
    [ORSystemFunctionTable reg:@"dispatch_get_main_queue" pointer:&dispatch_get_main_queue];
    [ORSystemFunctionTable reg:@"dispatch_block_notify" pointer:&dispatch_block_notify];
    [ORSystemFunctionTable reg:@"dispatch_block_testcancel" pointer:&dispatch_block_testcancel];
    
    /* queue */
    [MFScopeChain.topScope setValue:[MFValue valueWithLongLong:DISPATCH_QUEUE_PRIORITY_HIGH] withIndentifier:@"DISPATCH_QUEUE_PRIORITY_HIGH"];
    [MFScopeChain.topScope setValue:[MFValue valueWithLongLong:DISPATCH_QUEUE_PRIORITY_DEFAULT] withIndentifier:@"DISPATCH_QUEUE_PRIORITY_DEFAULT"];
    [MFScopeChain.topScope setValue:[MFValue valueWithLongLong:DISPATCH_QUEUE_PRIORITY_LOW] withIndentifier:@"DISPATCH_QUEUE_PRIORITY_LOW"];
    [MFScopeChain.topScope setValue:[MFValue valueWithLongLong:DISPATCH_QUEUE_PRIORITY_BACKGROUND] withIndentifier:@"DISPATCH_QUEUE_PRIORITY_BACKGROUND"];
    
    [MFScopeChain.topScope setValue:[MFValue valueWithObject:DISPATCH_QUEUE_CONCURRENT] withIndentifier:@"DISPATCH_QUEUE_CONCURRENT"];
    [MFScopeChain.topScope setValue:[MFValue valueWithPointer:NULL] withIndentifier:@"DISPATCH_QUEUE_SERIAL"];
    
    /*dispatch_source*/
    [MFScopeChain.topScope setValue:[MFValue valueWithPointer:(void *)DISPATCH_SOURCE_TYPE_PROC] withIndentifier:@"DISPATCH_SOURCE_TYPE_PROC"];
    [MFScopeChain.topScope setValue:[MFValue valueWithPointer:(void *)DISPATCH_SOURCE_TYPE_READ] withIndentifier:@"DISPATCH_SOURCE_TYPE_READ"];
    [MFScopeChain.topScope setValue:[MFValue valueWithPointer:(void *)DISPATCH_SOURCE_TYPE_SIGNAL] withIndentifier:@"DISPATCH_SOURCE_TYPE_SIGNAL"];
    [MFScopeChain.topScope setValue:[MFValue valueWithPointer:(void *)DISPATCH_SOURCE_TYPE_TIMER] withIndentifier:@"DISPATCH_SOURCE_TYPE_TIMER"];
    [MFScopeChain.topScope setValue:[MFValue valueWithPointer:(void *)DISPATCH_SOURCE_TYPE_VNODE] withIndentifier:@"DISPATCH_SOURCE_TYPE_VNODE"];
    [MFScopeChain.topScope setValue:[MFValue valueWithPointer:(void *)DISPATCH_SOURCE_TYPE_WRITE] withIndentifier:@"DISPATCH_SOURCE_TYPE_WRITE"];
}

static void add_build_in_function(){
    [MFScopeChain.topScope setValue:[MFValue valueWithBlock:^ CGAffineTransform(CGFloat a, CGFloat b, CGFloat c, CGFloat d, CGFloat tx, CGFloat ty){
        return CGAffineTransformMake(a, b, c, d, tx, ty);
    }] withIndentifier:@"CGAffineTransformMake"];
    
}
static void add_build_in_var(){
    [MFScopeChain.topScope setValue:[MFValue valueWithObject:NSRunLoopCommonModes] withIndentifier:@"NSRunLoopCommonModes"];
    [MFScopeChain.topScope setValue:[MFValue valueWithObject:NSDefaultRunLoopMode] withIndentifier:@"NSDefaultRunLoopMode"];
    
    [MFScopeChain.topScope setValue:[MFValue valueWithDouble:M_PI] withIndentifier:@"M_PI"];
    [MFScopeChain.topScope setValue:[MFValue valueWithDouble:M_PI_2] withIndentifier:@"M_PI_2"];
    [MFScopeChain.topScope setValue:[MFValue valueWithDouble:M_PI_4] withIndentifier:@"M_PI_4"];
    [MFScopeChain.topScope setValue:[MFValue valueWithDouble:M_1_PI] withIndentifier:@"M_1_PI"];
    [MFScopeChain.topScope setValue:[MFValue valueWithDouble:M_2_PI] withIndentifier:@"M_2_PI"];
    
    UIDevice *device = [UIDevice currentDevice];
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    [MFScopeChain.topScope setValue:[MFValue valueWithObject:device.systemVersion] withIndentifier:@"$systemVersion"];
    [MFScopeChain.topScope setValue:[MFValue valueWithObject:[infoDictionary objectForKey:@"CFBundleShortVersionString"]] withIndentifier:@"$appVersion"];
    [MFScopeChain.topScope setValue:[MFValue valueWithObject:[infoDictionary objectForKey:@"CFBundleVersion"]] withIndentifier:@"$buildVersion"];
    
#if defined(__LP64__) && __LP64__
    BOOL is32BitDevice = NO;
#else
    BOOL is32BitDevice = YES;
#endif
    [MFScopeChain.topScope setValue:[MFValue valueWithBOOL:is32BitDevice ] withIndentifier:@"$is32BitDevice"];;
}
#import "ORInterpreter.h"
void mf_add_built_in(void){
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        add_build_in_function();
        add_build_in_var();
        add_gcd_build_in();
    });
}


