//
//  ORInterpreter.h
//  OCRunner
//
//  Created by Jiang on 2020/5/23.
//  Copyright © 2020 SilverFruity. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@interface ORInterpreter : NSObject
+ (void)excuteBinaryPatchFile:(NSString *)path;
+ (void)excuteNodes:(NSArray *)nodes;
@end

NS_ASSUME_NONNULL_END
