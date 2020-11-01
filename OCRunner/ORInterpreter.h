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
/// 加载二进制文件补丁
/// @param path 补丁文件的路径
+ (void)excuteBinaryPatchFile:(NSString *)path;

+ (void)excuteNodes:(NSArray *)nodes;
/// 加载json格式的补丁
/// @param path 补丁的路径
/// @param decrptMapPath 解密文件的路径
+ (void)excuteJsonPatchFile:(NSString *)path decrptMapPath:(nullable NSString *)decrptMapPath;
@end

NS_ASSUME_NONNULL_END
