//
//  ORSystemFunctionTable.h
//  OCRunner
//
//  Created by Jiang on 2020/7/17.
//  Copyright © 2020 SilverFruity. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ORSystemFunctionTable : NSObject
+ (void)reg:(NSString *)name pointer:(void *)pointer;
+ (void *)pointerForFunctionName:(NSString *)name;
@end

NS_ASSUME_NONNULL_END
