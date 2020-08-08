//
//  ORInterpreter.h
//  OCRunner
//
//  Created by Jiang on 2020/5/23.
//  Copyright © 2020 SilverFruity. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@class ORClass;
@interface ORInterpreter : NSObject
+ (void)excute:(NSString *)string;
@end

NS_ASSUME_NONNULL_END
