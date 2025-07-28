//
//  AppDelegate.m
//  OCRunnerDemo
//
//  Created by Jiang on 2020/5/23.
//  Copyright © 2020 SilverFruity. All rights reserved.
//

#import "AppDelegate.h"

//#import <ObjcScript/OCRunner.h>
//#import <ObjcScript/TcpServer.h>

#import <OCRunner.h>

@interface AppDelegate ()

@end

@implementation AppDelegate

#ifdef OCRUNNER_OBJC_SOURCE
- (NSString *)stringWithFile:(NSString *)path {
    NSError *error = nil;
    NSData *fileData = [[NSData alloc] initWithContentsOfFile:path options:NSDataReadingUncached error:&error];
    return [[NSString alloc] initWithData:fileData encoding:NSUTF8StringEncoding];
}
- (NSString *)loadSciprtBundleSourceCode {
    NSString *otherBundlePath = [[NSBundle mainBundle] pathForResource:@"Scripts.bundle" ofType:nil];
    NSBundle *otherBundle = [NSBundle bundleWithPath:otherBundlePath];
    NSString *gcdPath = [otherBundle pathForResource:@"GCDRefrences" ofType:nil];
    NSString *uikitPath = [otherBundle pathForResource:@"UIKitRefrences" ofType:nil];
    NSMutableString *sourceCode = [NSMutableString new];
    [sourceCode appendString:[self stringWithFile:gcdPath]];
    [sourceCode appendString:[self stringWithFile:uikitPath]];
    return [sourceCode copy];
}
#endif

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

// only for #import <ObjcScript/OCRunner.h>
#ifdef OCRUNNER_OBJC_SOURCE

    ObjcScriptRunExeServer();

    NSString *file0Path = [[NSBundle mainBundle] pathForResource:@"ViewController1" ofType:nil];
    NSString *file1Path = [[NSBundle mainBundle] pathForResource:@"HotViewcontroller" ofType:nil];

    NSMutableString *sourceCode = [NSMutableString new];
    [sourceCode appendString:[self loadSciprtBundleSourceCode]];
    [sourceCode appendString:[self stringWithFile:file0Path]];
    [sourceCode appendString:[self stringWithFile:file1Path]];
    [ORInterpreter executeSourceCode:sourceCode];
#else
    NSString *binaryPatchFilePath = [[NSBundle mainBundle] pathForResource:@"binarypatch" ofType:nil];
    [ORInterpreter excuteBinaryPatchFile:binaryPatchFilePath];
#endif

//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        [ORInterpreter reverse];
//    });
    
#if __x86_64__  &&  TARGET_OS_SIMULATOR  &&  !TARGET_OS_IOSMAC
    NSLog(@"SIMULATOR");
#endif
    return YES;
}


@end
