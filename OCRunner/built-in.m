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
static void add_built_in_struct_declare(){
	ORStructDeclareTable *table = [ORStructDeclareTable shareInstance];
    
	[table addStructDeclare:[ORStructDeclare structDecalre:@encode(CGPoint) keys:@[@"x",@"y"]]];
    [table addStructDeclare:[ORStructDeclare structDecalre:@encode(CGSize) keys:@[@"width",@"height"]]];
    [table addStructDeclare:[ORStructDeclare structDecalre:@encode(CGRect) keys:@[@"origin",@"size"]]];
    [table addStructDeclare:[ORStructDeclare structDecalre:@encode(CGAffineTransform) keys:@[@"a",@"b",@"c", @"d", @"tx", @"ty"]]];
    [table addStructDeclare:[ORStructDeclare structDecalre:@encode(CGVector) keys:@[@"dx",@"dy"]]];
    [table addStructDeclare:[ORStructDeclare structDecalre:@encode(NSRange) keys:@[@"location",@"length"]]];
    [table addAlias:@"NSRange" forTypeEncode:@encode(NSRange)]; // @encode(NSRange) -> _NSRange
    [table addStructDeclare:[ORStructDeclare structDecalre:@encode(UIOffset) keys:@[@"horizontal",@"vertical"]]];
    [table addStructDeclare:[ORStructDeclare structDecalre:@encode(UIEdgeInsets) keys:@[@"top",@"left",@"bottom",@"right"]]];
    [table addStructDeclare:[ORStructDeclare structDecalre:@encode(CATransform3D) keys:@[@"m11",@"m12",@"m13",@"m14",@"m21",@"m22",@"m23",@"m24",@"m31",@"m32",@"m33",@"m34",@"41",@"m42",@"m43",@"m44"]]];
}

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
	[MFScopeChain.topScope setValue:[MFValue valueWithBlock:^CGPoint(CGFloat x, CGFloat y){
		return CGPointMake(x, y);
	}] withIndentifier:@"CGPointMake"];
	
	[MFScopeChain.topScope setValue:[MFValue valueWithBlock:^CGSize(CGFloat width, CGFloat height){
		return CGSizeMake(width, height);
	}] withIndentifier:@"CGSizeMake"];
	
	
	[MFScopeChain.topScope setValue:[MFValue valueWithBlock:^CGRect (CGFloat x, CGFloat y, CGFloat width, CGFloat height){
		return CGRectMake(x, y, width, height);
	}] withIndentifier:@"CGRectMake"];
	
	[MFScopeChain.topScope setValue:[MFValue valueWithBlock:^NSRange(NSUInteger loc, NSUInteger len){
		return NSMakeRange(loc, len);
	}] withIndentifier:@"NSMakeRange"];
	
	[MFScopeChain.topScope setValue:[MFValue valueWithBlock:^UIOffset(CGFloat horizontal, CGFloat vertical){
		return UIOffsetMake(horizontal, vertical);
	}] withIndentifier:@"UIOffsetMake"];
	
	[MFScopeChain.topScope setValue:[MFValue valueWithBlock:^UIEdgeInsets(CGFloat top, CGFloat left, CGFloat bottom, CGFloat right){
		return UIEdgeInsetsMake(top, left, bottom, right);
	}] withIndentifier:@"UIEdgeInsetsMake"];
	
	[MFScopeChain.topScope setValue:[MFValue valueWithBlock:^CGVector(CGFloat dx, CGFloat dy){
		return CGVectorMake(dx, dy);
	}] withIndentifier:@"CGVectorMake"];
	
	[MFScopeChain.topScope setValue:[MFValue valueWithBlock:^ CGAffineTransform(CGFloat a, CGFloat b, CGFloat c, CGFloat d, CGFloat tx, CGFloat ty){
		return CGAffineTransformMake(a, b, c, d, tx, ty);
	}] withIndentifier:@"CGAffineTransformMake"];
	
	[MFScopeChain.topScope setValue:[MFValue valueWithBlock:^CGAffineTransform(CGFloat sx, CGFloat sy){
		return CGAffineTransformMakeScale(sx, sy);
	}] withIndentifier:@"CGAffineTransformMakeScale"];
	
	[MFScopeChain.topScope setValue:[MFValue valueWithBlock:^CGAffineTransform(CGFloat angle){
		return CGAffineTransformMakeRotation(angle);
	}] withIndentifier:@"CGAffineTransformMakeRotation"];
	
	[MFScopeChain.topScope setValue:[MFValue valueWithBlock:^CGAffineTransform(CGFloat tx, CGFloat ty){
		return CGAffineTransformMakeTranslation(tx, ty);
	}] withIndentifier:@"CGAffineTransformMakeTranslation"];
	
	[MFScopeChain.topScope setValue:[MFValue valueWithBlock:^CGAffineTransform(CGAffineTransform t, CGFloat angle){
		return CGAffineTransformRotate(t, angle);
	}] withIndentifier:@"CGAffineTransformRotate"];
	
	[MFScopeChain.topScope setValue:[MFValue valueWithBlock:^CGAffineTransform(CGAffineTransform t1, CGAffineTransform t2){
		return CGAffineTransformConcat(t1,t2);
	}] withIndentifier:@"CGAffineTransformConcat"];
	
	
	[MFScopeChain.topScope setValue:[MFValue valueWithBlock:^CGAffineTransform(CGAffineTransform t, CGFloat sx, CGFloat sy){
		return CGAffineTransformScale(t, sx, sy);
	}] withIndentifier:@"CGAffineTransformScale"];
	
	[MFScopeChain.topScope setValue:[MFValue valueWithBlock:^CGAffineTransform(CGAffineTransform t, CGFloat tx, CGFloat ty){
		return CGAffineTransformTranslate(t, tx, ty);
	}] withIndentifier:@"CGAffineTransformTranslate"];

	[MFScopeChain.topScope setValue:[MFValue valueWithBlock:^CGAffineTransform(NSString * _Nonnull string){
		return CGAffineTransformFromString(string);
	}] withIndentifier:@"CGAffineTransformFromString"];

	[MFScopeChain.topScope setValue:[MFValue valueWithBlock:^CATransform3D(CGFloat sx, CGFloat sy, CGFloat sz){
		return CATransform3DMakeScale(sx, sy, sz);
	}] withIndentifier:@"CATransform3DMakeScale"];
	
	
	[MFScopeChain.topScope setValue:[MFValue valueWithBlock:^void (id obj){
		NSLog(@"%@",obj);
	}] withIndentifier:@"NSLog"];
    	
}
static void add_build_in_var(){
	[MFScopeChain.topScope setValue:[MFValue valueWithObject:NSRunLoopCommonModes] withIndentifier:@"NSRunLoopCommonModes"];
	[MFScopeChain.topScope setValue:[MFValue valueWithObject:NSDefaultRunLoopMode] withIndentifier:@"NSDefaultRunLoopMode"];

	[MFScopeChain.topScope setValue:[MFValue valueWithDouble:M_PI] withIndentifier:@"M_PI"];
	[MFScopeChain.topScope setValue:[MFValue valueWithDouble:M_PI_2] withIndentifier:@"M_PI_2"];
	[MFScopeChain.topScope setValue:[MFValue valueWithDouble:M_PI_4] withIndentifier:@"M_PI_4"];
	[MFScopeChain.topScope setValue:[MFValue valueWithDouble:M_1_PI] withIndentifier:@"M_1_PI"];
	[MFScopeChain.topScope setValue:[MFValue valueWithDouble:M_2_PI] withIndentifier:@"M_2_PI"];
    
    [MFScopeChain.topScope setValue:[MFValue valueWithULongLong:UIControlEventTouchDown] withIndentifier:@"UIControlEventTouchDown"];
    [MFScopeChain.topScope setValue:[MFValue valueWithULongLong:UIControlEventTouchDownRepeat] withIndentifier:@"UIControlEventTouchDownRepeat"];
    [MFScopeChain.topScope setValue:[MFValue valueWithULongLong:UIControlEventTouchDragInside] withIndentifier:@"UIControlEventTouchDragInside"];
    [MFScopeChain.topScope setValue:[MFValue valueWithULongLong:UIControlEventTouchDragOutside] withIndentifier:@"UIControlEventTouchDragOutside"];
    [MFScopeChain.topScope setValue:[MFValue valueWithULongLong:UIControlEventTouchDragEnter] withIndentifier:@"UIControlEventTouchDragEnter"];
    [MFScopeChain.topScope setValue:[MFValue valueWithULongLong:UIControlEventTouchDragExit] withIndentifier:@"UIControlEventTouchDragExit"];
    [MFScopeChain.topScope setValue:[MFValue valueWithULongLong:UIControlEventTouchUpInside] withIndentifier:@"UIControlEventTouchUpInside"];
    [MFScopeChain.topScope setValue:[MFValue valueWithULongLong:UIControlEventTouchUpOutside] withIndentifier:@"UIControlEventTouchUpOutside"];
    [MFScopeChain.topScope setValue:[MFValue valueWithULongLong:UIControlEventTouchCancel] withIndentifier:@"UIControlEventTouchCancel"];
    [MFScopeChain.topScope setValue:[MFValue valueWithULongLong:UIControlEventValueChanged] withIndentifier:@"UIControlEventValueChanged"];
    [MFScopeChain.topScope setValue:[MFValue valueWithULongLong:1 << 13] withIndentifier:@"UIControlEventPrimaryActionTriggered"];
    [MFScopeChain.topScope setValue:[MFValue valueWithULongLong:UIControlEventEditingDidBegin] withIndentifier:@"UIControlEventEditingDidBegin"];
    [MFScopeChain.topScope setValue:[MFValue valueWithULongLong:UIControlEventEditingChanged] withIndentifier:@"UIControlEventEditingChanged"];
    [MFScopeChain.topScope setValue:[MFValue valueWithULongLong:UIControlEventEditingDidEnd] withIndentifier:@"UIControlEventEditingDidEnd"];
    [MFScopeChain.topScope setValue:[MFValue valueWithULongLong:UIControlEventEditingDidEndOnExit] withIndentifier:@"UIControlEventEditingDidEndOnExit"];
    [MFScopeChain.topScope setValue:[MFValue valueWithULongLong:UIControlEventAllTouchEvents] withIndentifier:@"UIControlEventAllTouchEvents"];
    [MFScopeChain.topScope setValue:[MFValue valueWithULongLong:UIControlEventAllEditingEvents] withIndentifier:@"UIControlEventAllEditingEvents"];
    [MFScopeChain.topScope setValue:[MFValue valueWithULongLong:UIControlEventApplicationReserved] withIndentifier:@"UIControlEventApplicationReserved"];
    [MFScopeChain.topScope setValue:[MFValue valueWithULongLong:UIControlEventSystemReserved] withIndentifier:@"UIControlEventSystemReserved"];
    [MFScopeChain.topScope setValue:[MFValue valueWithULongLong:UIControlEventAllEvents] withIndentifier:@"UIControlEventAllEvents"];
    
    [MFScopeChain.topScope setValue:[MFValue valueWithLongLong:UIControlContentVerticalAlignmentCenter] withIndentifier:@"UIControlContentVerticalAlignmentCenter"];
    [MFScopeChain.topScope setValue:[MFValue valueWithLongLong:UIControlContentVerticalAlignmentTop] withIndentifier:@"UIControlContentVerticalAlignmentTop"];
    [MFScopeChain.topScope setValue:[MFValue valueWithLongLong:UIControlContentVerticalAlignmentBottom] withIndentifier:@"UIControlContentVerticalAlignmentBottom"];
    [MFScopeChain.topScope setValue:[MFValue valueWithLongLong:UIControlContentVerticalAlignmentFill] withIndentifier:@"UIControlContentVerticalAlignmentFill"];
    
    [MFScopeChain.topScope setValue:[MFValue valueWithLongLong:UIControlContentHorizontalAlignmentCenter] withIndentifier:@"UIControlContentHorizontalAlignmentCenter"];
    [MFScopeChain.topScope setValue:[MFValue valueWithLongLong:UIControlContentHorizontalAlignmentLeft] withIndentifier:@"UIControlContentHorizontalAlignmentLeft"];
    [MFScopeChain.topScope setValue:[MFValue valueWithLongLong:UIControlContentHorizontalAlignmentRight] withIndentifier:@"UIControlContentHorizontalAlignmentRight"];
    [MFScopeChain.topScope setValue:[MFValue valueWithLongLong:UIControlContentHorizontalAlignmentFill] withIndentifier:@"UIControlContentHorizontalAlignmentFill"];
    [MFScopeChain.topScope setValue:[MFValue valueWithLongLong:4] withIndentifier:@"UIControlContentHorizontalAlignmentLeading"];
    [MFScopeChain.topScope setValue:[MFValue valueWithLongLong:5] withIndentifier:@"UIControlContentHorizontalAlignmentTrailing"];
    
    [MFScopeChain.topScope setValue:[MFValue valueWithULongLong:UIControlStateNormal] withIndentifier:@"UIControlStateNormal"];
    [MFScopeChain.topScope setValue:[MFValue valueWithULongLong:UIControlStateHighlighted] withIndentifier:@"UIControlStateHighlighted"];
    [MFScopeChain.topScope setValue:[MFValue valueWithULongLong:UIControlStateDisabled] withIndentifier:@"UIControlStateDisabled"];
    [MFScopeChain.topScope setValue:[MFValue valueWithULongLong:UIControlStateSelected] withIndentifier:@"UIControlStateSelected"];
    [MFScopeChain.topScope setValue:[MFValue valueWithULongLong:1 << 3] withIndentifier:@"UIControlStateFocused"];
    [MFScopeChain.topScope setValue:[MFValue valueWithULongLong:UIControlStateApplication] withIndentifier:@"UIControlStateApplication"];
    [MFScopeChain.topScope setValue:[MFValue valueWithULongLong:UIControlStateReserved] withIndentifier:@"UIControlStateReserved"];
	
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

void mf_add_built_in(void){
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		add_built_in_struct_declare();
		add_build_in_function();
		add_build_in_var();
		add_gcd_build_in();
	});
}
