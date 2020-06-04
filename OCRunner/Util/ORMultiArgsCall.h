//
//  ORMultiArgsCall.h
//  OCRunner
//
//  Created by Jiang on 2020/6/4.
//  Copyright © 2020 SilverFruity. All rights reserved.
//

#ifndef ORMultiArgsCall_h
#define ORMultiArgsCall_h

/*
 Example:
 int value1 = 1;
 int value2 = 2;
 int value3 = 3;
 char *format = "printf%d %d %d xxx\n";
 void *a[4] = {&format, &value1, &value2, &value3};
 ORMultiArgsCFunCall(a, 4, &printf);
 NOTE: 目前只支持(xx a, ...) 一个固定参数的情况
 */
extern void ORMultiArgsCFunCall(void **args, NSUInteger count, void *funcPt);

/*
 Example:
 NSString *format1 = @"%d %f method";
 int value4 = 1000;
 double value5 = 22.22;
 void *b[3] = {&format1, &value4, &value5};
 NSString *value = (__bridge NSString *)(ORMultiArgsMethodCall([NSString class], @selector(stringWithFormat:), b, 3, &objc_msgSend));
 NSLog(@"%@",value);
 NOTE: 目前只支持(xx a, ...) 一个固定参数的情况
*/
extern void * ORMultiArgsMethodCall(id target,SEL sel,void **args, NSUInteger count, void *funcPt);

#endif /* ORMultiArgsCall_h */
