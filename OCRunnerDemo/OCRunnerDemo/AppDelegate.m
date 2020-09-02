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
#if DEBUG
    NSString *patchFilePath = [[NSBundle mainBundle] pathForResource:@"binarypatch" ofType:nil];
#else
    NSURL *serverFileUrl = [NSURL URLWithString:@"http://127.0.0.1:8086/binarypatch"];
    NSString *patchFilePath = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
    patchFilePath = [patchFilePath stringByAppendingPathComponent:@"BinaryPatchFile"];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:serverFileUrl];
    req.timeoutInterval = 5;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    [[[NSURLSession sharedSession] downloadTaskWithRequest:req completionHandler:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSURL *dest = [NSURL fileURLWithPath:patchFilePath];
        if ([[NSFileManager defaultManager] fileExistsAtPath:dest.path]) {
            [[NSFileManager defaultManager] replaceItemAtURL:dest withItemAtURL:location backupItemName:nil options:0 resultingItemURL:nil error:&error];
        }else{
            [[NSFileManager defaultManager] moveItemAtURL:location toURL:dest error:&error];
        }
        if (error) {
            NSLog(@"%@",error);
        }
        dispatch_semaphore_signal(semaphore);
    }] resume] ;
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
#endif
    [ORInterpreter excuteBinaryPatchFile:patchFilePath];
    
#if __x86_64__  &&  TARGET_OS_SIMULATOR  &&  !TARGET_OS_IOSMAC
    NSLog(@"SIMULATOR");
#endif
    return YES;
}


#pragma mark - UISceneSession lifecycle


- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options {
    // Called when a new scene session is being created.
    // Use this method to select a configuration to create the new scene with.
    return [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:connectingSceneSession.role];
}


- (void)application:(UIApplication *)application didDiscardSceneSessions:(NSSet<UISceneSession *> *)sceneSessions {
    // Called when the user discards a scene session.
    // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
    // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
}


@end
