//
//  AppDelegate.m
//  OCRunnerDemo
//
//  Created by Jiang on 2020/5/23.
//  Copyright © 2020 SilverFruity. All rights reserved.
//

#import "AppDelegate.h"
#import <OCRunner.h>
#import <objc/message.h>

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    NSString *binaryPatchFilePath = [[NSBundle mainBundle] pathForResource:@"binarypatch" ofType:nil];
    NSString *jsonPatchFilePath = [[NSBundle mainBundle] pathForResource:@"jsonpatch" ofType:nil];
    [ORInterpreter excuteBinaryPatchFile:binaryPatchFilePath];
    [ORInterpreter excuteJsonPatchFile:jsonPatchFilePath];
    
#if __x86_64__  &&  TARGET_OS_SIMULATOR  &&  !TARGET_OS_IOSMAC
    NSLog(@"SIMULATOR");
#endif
    return YES;
}


@end
