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
#import <oc2mangoLib/oc2mangoLib.h>
@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
//    NSString *jsonPatchFilePath = [[NSBundle mainBundle] pathForResource:@"jsonpatch" ofType:nil];
//    [ORInterpreter excuteJsonPatchFile:jsonPatchFilePath];
    
//    NSString *binaryPatchFilePath = [[NSBundle mainBundle] pathForResource:@"binarypatch" ofType:nil];
//    [ORInterpreter excuteBinaryPatchFile:binaryPatchFilePath];

    NSString * source =
    @"long long fibonaccia(long long n){"
    @"    if (n == 1 || n == 2)"
    @"        return 1;"
    @"    long long a = fibonaccia(n - 1); long long b = fibonaccia(n - 2);"
    @"    return a + b;"
    @"}"
    @"int a = fibonaccia(30);";
    AST *ast = [[Parser new] parseSource:source];
    InitialSymbolTableVisitor *visitor = [InitialSymbolTableVisitor new];
    symbolTableRoot = [ocSymbolTable new];
    for (ORNode *node in ast.nodes) {
        [visitor visit:node];
    }
    ast.scope = symbolTableRoot.scope;
    [ORInterpreter shared]->constants = symbolTableRoot->constants;
    [ORInterpreter shared]->constants_size = symbolTableRoot->constants_size;
    void *ctx = thread_current_context();
    for (id exp in ast.globalStatements) {
        eval([ORInterpreter shared], ctx, [MFScopeChain topScope], exp);
    }
    NSLog(@"%d",[[MFScopeChain topScope] getValueWithIdentifier:@"a"].uIntValue);

//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        [ORInterpreter reverse];
//    });
    
#if __x86_64__  &&  TARGET_OS_SIMULATOR  &&  !TARGET_OS_IOSMAC
    NSLog(@"SIMULATOR");
#endif
    return YES;
}


@end
