//
//  ANEStack.h
//  MangoFix
//
//  Created by jerry.yong on 2018/2/28.
//  Copyright © 2018年 yongpengliang. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class MFValue;

@interface MFStack : NSObject
+ (instancetype)argsStack;
- (void)push:(NSMutableArray <MFValue *> *)value;
- (NSMutableArray <MFValue *> *)pop;
- (BOOL)isEmpty;
- (NSUInteger)size;

@end

NS_ASSUME_NONNULL_END
