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
+ (instancetype)shared;
#ifdef OCRUNNER_OBJC_SOURCE
+ (void)executeSourceCode:(NSString *)sourceCode;
#else
+ (void)excuteBinaryPatchFile:(NSString *)path;
+ (void)excuteJsonPatchFile:(NSString *)path;
#endif
+ (void)excuteNodes:(NSArray *)nodes;
+ (void)recover;
+ (void)recoverWithClearEnvironment:(BOOL)clear;
@end

NS_ASSUME_NONNULL_END
