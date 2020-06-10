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
static void add_gcd_build_in(){
	/* queue */
    [MFScopeChain.topScope setValue:[MFValue valueWithLongLong:DISPATCH_QUEUE_PRIORITY_HIGH] withIndentifier:@"DISPATCH_QUEUE_PRIORITY_HIGH"];
    [MFScopeChain.topScope setValue:[MFValue valueWithLongLong:DISPATCH_QUEUE_PRIORITY_DEFAULT] withIndentifier:@"DISPATCH_QUEUE_PRIORITY_DEFAULT"];
    [MFScopeChain.topScope setValue:[MFValue valueWithLongLong:DISPATCH_QUEUE_PRIORITY_LOW] withIndentifier:@"DISPATCH_QUEUE_PRIORITY_LOW"];
    [MFScopeChain.topScope setValue:[MFValue valueWithLongLong:DISPATCH_QUEUE_PRIORITY_BACKGROUND] withIndentifier:@"DISPATCH_QUEUE_PRIORITY_BACKGROUND"];
    
    [MFScopeChain.topScope setValue:[MFValue valueWithObject:DISPATCH_QUEUE_CONCURRENT] withIndentifier:@"DISPATCH_QUEUE_CONCURRENT"];
    [MFScopeChain.topScope setValue:[MFValue valueWithPointer:NULL] withIndentifier:@"DISPATCH_QUEUE_SERIAL"];
    
	[MFScopeChain.topScope setValue:[MFValue valueWithBlock:^id(long identifier, unsigned long flags) {
		return dispatch_get_global_queue(identifier, flags);
	}]withIndentifier:@"dispatch_get_global_queue"];
	
	[MFScopeChain.topScope setValue:[MFValue valueWithBlock:^id() {
		return dispatch_get_main_queue();
	}]withIndentifier:@"dispatch_get_main_queue"];

	[MFScopeChain.topScope setValue:[MFValue valueWithBlock:^id(const char *queueName, dispatch_queue_attr_t attr) {
		dispatch_queue_t queue = dispatch_queue_create(queueName, attr);
		return queue;
	}] withIndentifier:@"dispatch_queue_create"];
	
	
	/* dispatch & dispatch_barrier */
    [MFScopeChain.topScope setValue:[MFValue valueWithBlock:^(dispatch_time_t when, dispatch_queue_t  _Nonnull queue, dispatch_block_t block){
        dispatch_after(when, queue, block);
    }] withIndentifier:@"dispatch_after"];
    
	[MFScopeChain.topScope setValue:[MFValue valueWithBlock:^void(dispatch_queue_t queue, void (^block)(void)) {
		dispatch_async(queue, ^{
			block();
		});
	}] withIndentifier:@"dispatch_async"];
	
	[MFScopeChain.topScope setValue:[MFValue valueWithBlock:^void(dispatch_queue_t queue, void (^block)(void)) {
		dispatch_sync(queue, ^{
			block();
		});
	}] withIndentifier:@"dispatch_sync"];
	
	[MFScopeChain.topScope setValue:[MFValue valueWithBlock:^void(dispatch_queue_t queue, void (^block)(void)) {
		dispatch_barrier_async(queue, ^{
			block();
		});
	}] withIndentifier:@"dispatch_barrier_async"];
	
	[MFScopeChain.topScope setValue:[MFValue valueWithBlock:^void(dispatch_queue_t queue, void (^block)(void)) {
		dispatch_barrier_sync(queue, ^{
			block();
		});
	}] withIndentifier:@"dispatch_barrier_sync"];

	[MFScopeChain.topScope setValue:[MFValue valueWithBlock:^void(size_t iterations, dispatch_queue_t queue, void (^block)(size_t)) {
		dispatch_apply(iterations, queue, ^(size_t index) {
			block(index);
		});
	}] withIndentifier:@"dispatch_apply"];
	
	
	
	/* dispatch_group */
	[MFScopeChain.topScope setValue:[MFValue valueWithBlock:^id() {
		dispatch_group_t group = dispatch_group_create();
		return group;
	}] withIndentifier:@"dispatch_group_create"];
	
	[MFScopeChain.topScope setValue:[MFValue valueWithBlock:^void(dispatch_group_t group, dispatch_queue_t queue, void (^block)(void)) {
		dispatch_group_async(group, queue, ^{
			block();
		});
	}] withIndentifier:@"dispatch_group_async"];
	
	[MFScopeChain.topScope setValue:[MFValue valueWithBlock:^void(dispatch_group_t group,  dispatch_time_t timeout) {
		dispatch_group_wait(group, timeout);
	}] withIndentifier:@"dispatch_group_wait"];
	
	[MFScopeChain.topScope setValue:[MFValue valueWithBlock:^void(dispatch_group_t group, dispatch_queue_t queue, void (^block)(void)) {
		dispatch_group_notify(group, queue, ^{
			block();
		});
	}] withIndentifier:@"dispatch_group_notify"];
	
	[MFScopeChain.topScope setValue:[MFValue valueWithBlock:^void(dispatch_group_t group) {
		dispatch_group_enter(group);
	}] withIndentifier:@"dispatch_group_enter"];
	
	[MFScopeChain.topScope setValue:[MFValue valueWithBlock:^void(dispatch_group_t group) {
		dispatch_group_leave(group);
	}] withIndentifier:@"dispatch_group_leave"];
    
    
    /*dispatch_block*/
    [MFScopeChain.topScope setValue:[MFValue valueWithLongLong:DISPATCH_BLOCK_BARRIER] withIndentifier:@"DISPATCH_BLOCK_BARRIER"];
     [MFScopeChain.topScope setValue:[MFValue valueWithLongLong:DISPATCH_BLOCK_DETACHED] withIndentifier:@"DISPATCH_BLOCK_DETACHED"];
     [MFScopeChain.topScope setValue:[MFValue valueWithLongLong:DISPATCH_BLOCK_ASSIGN_CURRENT] withIndentifier:@"DISPATCH_BLOCK_ASSIGN_CURRENT"];
     [MFScopeChain.topScope setValue:[MFValue valueWithLongLong:DISPATCH_BLOCK_NO_QOS_CLASS] withIndentifier:@"DISPATCH_BLOCK_NO_QOS_CLASS"];
     [MFScopeChain.topScope setValue:[MFValue valueWithLongLong:DISPATCH_BLOCK_INHERIT_QOS_CLASS] withIndentifier:@"DISPATCH_BLOCK_INHERIT_QOS_CLASS"];
     [MFScopeChain.topScope setValue:[MFValue valueWithLongLong:DISPATCH_BLOCK_ENFORCE_QOS_CLASS] withIndentifier:@"DISPATCH_BLOCK_ENFORCE_QOS_CLASS"];
    
    [MFScopeChain.topScope setValue:[MFValue valueWithBlock:^dispatch_block_t(dispatch_block_flags_t flags, dispatch_block_t block){
       return dispatch_block_create(flags, block);
    }] withIndentifier:@"dispatch_block_create"];
    
    [MFScopeChain.topScope setValue:[MFValue valueWithBlock:^dispatch_block_t(dispatch_block_flags_t flags,
                                                                                  dispatch_qos_class_t qos_class, int relative_priority,
                                                                                  dispatch_block_t block){
        return dispatch_block_create_with_qos_class(flags, qos_class, relative_priority, block);
    }] withIndentifier:@"dispatch_block_create_with_qos_class"];
    
    [MFScopeChain.topScope setValue:[MFValue valueWithBlock:^void(dispatch_block_flags_t flags,
                                                                                   dispatch_block_t block){
        dispatch_block_perform(flags, block);
    }] withIndentifier:@"dispatch_block_perform"];
    
    [MFScopeChain.topScope setValue:[MFValue valueWithBlock:^long(dispatch_block_t block, dispatch_time_t timeout){
        return dispatch_block_wait(block, timeout);
    }] withIndentifier:@"dispatch_block_wait"];
    
    [MFScopeChain.topScope setValue:[MFValue valueWithBlock:^void(dispatch_block_t block, dispatch_queue_t queue,
                                                                       dispatch_block_t notification_block){
        dispatch_block_notify(block, queue, notification_block);
    }] withIndentifier:@"dispatch_block_notify"];
    
    [MFScopeChain.topScope setValue:[MFValue valueWithBlock:^long(dispatch_block_t block){
        return dispatch_block_testcancel(block);
    }] withIndentifier:@"dispatch_block_testcancel"];
    
    [MFScopeChain.topScope setValue:[MFValue valueWithBlock:^void(dispatch_block_t block){
         dispatch_block_cancel(block);
    }] withIndentifier:@"dispatch_block_cancel"];
    
    
    /*dispatch_semaphore*/
    [MFScopeChain.topScope setValue:[MFValue valueWithBlock:^id(long value){
        return dispatch_semaphore_create(value);
    }] withIndentifier:@"dispatch_semaphore_create"];
    
    [MFScopeChain.topScope setValue:[MFValue valueWithBlock:^long(dispatch_semaphore_t dsema, dispatch_time_t timeout){
        return dispatch_semaphore_wait(dsema, timeout);
    }] withIndentifier:@"dispatch_semaphore_wait"];

    [MFScopeChain.topScope setValue:[MFValue valueWithBlock:^long(dispatch_semaphore_t dsema){
        return dispatch_semaphore_signal(dsema);
    }] withIndentifier:@"dispatch_semaphore_signal"];
    
    
    /*dispatch_time*/
    [MFScopeChain.topScope setValue:[MFValue valueWithULongLong:NSEC_PER_SEC] withIndentifier:@"NSEC_PER_SEC"];
    [MFScopeChain.topScope setValue:[MFValue valueWithULongLong:NSEC_PER_MSEC] withIndentifier:@"NSEC_PER_MSEC"];
    [MFScopeChain.topScope setValue:[MFValue valueWithULongLong:USEC_PER_SEC] withIndentifier:@"USEC_PER_SEC"];
    [MFScopeChain.topScope setValue:[MFValue valueWithULongLong:NSEC_PER_USEC] withIndentifier:@"NSEC_PER_USEC"];
    
    [MFScopeChain.topScope setValue:[MFValue valueWithULongLong:DISPATCH_TIME_FOREVER] withIndentifier:@"DISPATCH_TIME_FOREVER"];
    [MFScopeChain.topScope setValue:[MFValue valueWithLongLong:DISPATCH_TIME_NOW] withIndentifier:@"DISPATCH_TIME_NOW"];
    
    [MFScopeChain.topScope setValue:[MFValue valueWithBlock:^dispatch_time_t (dispatch_time_t when, int64_t delta){
        return dispatch_time(when, delta);
    }] withIndentifier:@"dispatch_time"];

    
    /*dispatch_object*/
    [MFScopeChain.topScope setValue:[MFValue valueWithBlock:^void(dispatch_object_t object){
        dispatch_resume(object);
    }] withIndentifier:@"dispatch_resume"];
    
    [MFScopeChain.topScope setValue:[MFValue valueWithBlock:^void(dispatch_object_t object){
        dispatch_suspend(object);
    }] withIndentifier:@"dispatch_suspend"];
    
  
    /*dispatch_source*/
    [MFScopeChain.topScope setValue:[MFValue valueWithPointer:(void *)DISPATCH_SOURCE_TYPE_PROC] withIndentifier:@"DISPATCH_SOURCE_TYPE_PROC"];
    [MFScopeChain.topScope setValue:[MFValue valueWithPointer:(void *)DISPATCH_SOURCE_TYPE_READ] withIndentifier:@"DISPATCH_SOURCE_TYPE_READ"];
    [MFScopeChain.topScope setValue:[MFValue valueWithPointer:(void *)DISPATCH_SOURCE_TYPE_SIGNAL] withIndentifier:@"DISPATCH_SOURCE_TYPE_SIGNAL"];
    [MFScopeChain.topScope setValue:[MFValue valueWithPointer:(void *)DISPATCH_SOURCE_TYPE_TIMER] withIndentifier:@"DISPATCH_SOURCE_TYPE_TIMER"];
    [MFScopeChain.topScope setValue:[MFValue valueWithPointer:(void *)DISPATCH_SOURCE_TYPE_VNODE] withIndentifier:@"DISPATCH_SOURCE_TYPE_VNODE"];
    [MFScopeChain.topScope setValue:[MFValue valueWithPointer:(void *)DISPATCH_SOURCE_TYPE_WRITE] withIndentifier:@"DISPATCH_SOURCE_TYPE_WRITE"];
    
    [MFScopeChain.topScope setValue:[MFValue valueWithBlock:^dispatch_source_t (dispatch_source_type_t type,
                                                                                  uintptr_t handle,
                                                                                  unsigned long mask,
                                                                                  dispatch_queue_t _Nullable queue){
        return dispatch_source_create(type, handle, mask, queue);
    }] withIndentifier:@"dispatch_source_create"];
    
    [MFScopeChain.topScope setValue:[MFValue valueWithBlock:^void(dispatch_source_t source,
                                                                                    dispatch_block_t handler){
        dispatch_source_set_event_handler(source, handler);
    }] withIndentifier:@"dispatch_source_set_event_handler"];
    
    [MFScopeChain.topScope setValue:[MFValue valueWithBlock:^void(dispatch_source_t source,
                                                                      dispatch_block_t handler){
        dispatch_source_set_cancel_handler(source, handler);
    }] withIndentifier:@"dispatch_source_set_cancel_handler"];
    
    [MFScopeChain.topScope setValue:[MFValue valueWithBlock:^void(dispatch_source_t source){
        dispatch_source_cancel(source);
    }] withIndentifier:@"dispatch_source_cancel"];
    
    [MFScopeChain.topScope setValue:[MFValue valueWithBlock:^long(dispatch_source_t source){
        return dispatch_source_testcancel(source);
    }] withIndentifier:@"dispatch_source_testcancel"];
    
    [MFScopeChain.topScope setValue:[MFValue valueWithBlock:^uintptr_t(dispatch_source_t source){
        return dispatch_source_get_handle(source);
    }] withIndentifier:@"dispatch_source_get_handle"];
    
    [MFScopeChain.topScope setValue:[MFValue valueWithBlock:^unsigned long(dispatch_source_t source){
        return dispatch_source_get_mask(source);
    }] withIndentifier:@"dispatch_source_get_mask"];
    
    [MFScopeChain.topScope setValue:[MFValue valueWithBlock:^unsigned long(dispatch_source_t source){
        return dispatch_source_get_data(source);
    }] withIndentifier:@"dispatch_source_get_data"];
    
    [MFScopeChain.topScope setValue:[MFValue valueWithBlock:^void(dispatch_source_t source, unsigned long value){
        dispatch_source_merge_data(source,value);
    }] withIndentifier:@"dispatch_source_merge_data"];
    
    [MFScopeChain.topScope setValue:[MFValue valueWithBlock:^void(dispatch_source_t source,
                                                                      dispatch_time_t start,
                                                                      uint64_t interval,
                                                                      uint64_t leeway){
        dispatch_source_set_timer(source, start, interval, leeway);
    }] withIndentifier:@"dispatch_source_set_timer"];
    
    [MFScopeChain.topScope setValue:[MFValue valueWithBlock:^void(dispatch_source_t source,
                                                                      dispatch_block_t _Nullable handler){
        dispatch_source_set_registration_handler(source, handler);
    }] withIndentifier:@"dispatch_source_set_registration_handler"];
    
    
    /*dispatch_once*/
    [MFScopeChain.topScope setValue:[MFValue valueWithBlock:^void(dispatch_once_t *onceTokenPtr,
                                                                      dispatch_block_t _Nullable handler){
        dispatch_once(onceTokenPtr,handler);
    }] withIndentifier:@"dispatch_once"];
    
    
    
    
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
        NSString *path = [[NSBundle bundleForClass:[MFValue class]] pathForResource:@"UIKitRefrences" ofType:nil];
        NSString *data = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
        [ORInterpreter excuteGlobalDeclare:data];
		add_build_in_function();
		add_build_in_var();
		add_gcd_build_in();
	});
}

// for unit test
void or_add_build_in(void){
    NSString *path = [[NSBundle bundleForClass:[MFValue class]] pathForResource:@"UIKitRefrences" ofType:nil];
    NSString *data = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    [ORInterpreter excuteGlobalDeclare:data];
    add_build_in_function();
    add_build_in_var();
    add_gcd_build_in();
}

