//
//  ORInterpreter.m
//  OCRunner
//
//  Created by Jiang on 2020/5/23.
//  Copyright © 2020 SilverFruity. All rights reserved.
//

#import "ORInterpreter.h"
#import "RunnerClasses+Execute.h"
#import "RunnerClasses+Recover.h"
#import "MFScopeChain.h"
#import "ORSearchedFunction.h"
#import "MFValue.h"
#import "ORStructDeclare.h"
#import "ORSystemFunctionPointerTable.h"
#import "MFStaticVarTable.h"
#import "ORffiResultCache.h"

#ifdef OCRUNNER_OBJC_SOURCE
#import <oc2mangoLib/oc2mangoLib.h>
#endif

@interface ORInterpreter()
@property (nonatomic, copy)NSArray *currentNodes;
@end

@implementation ORInterpreter

+ (instancetype)shared{
    static dispatch_once_t onceToken;
    static ORInterpreter *_instance = nil;
    dispatch_once(&onceToken, ^{
        _instance = [ORInterpreter new];
    });
    return _instance;
}

#ifdef OCRUNNER_OBJC_SOURCE
+ (void)executeSourceCode:(NSString *)sourceCode {
    AST *ast = [[Parser shared] parseSource:sourceCode];
    [self excuteNodes: ast.nodes];
}
#else
+ (void)excuteBinaryPatchFile:(NSString *)path{
    //加载补丁文件
    ORPatchFile *file = [ORPatchFile loadBinaryPatch:path];
    
    //如果版本判断未通过，则为nil
    if (file == nil) {
        return;
    }
    [self excuteNodes:file.nodes];
}

+ (void)excuteJsonPatchFile:(NSString *)path{
    //加载补丁文件
    ORPatchFile *file = [ORPatchFile loadJsonPatch:path];
    
    //如果版本判断未通过，则为nil
    if (file == nil) {
        return;
    }
    [self excuteNodes:file.nodes];
}
#endif

+ (void)excuteNodes:(NSArray <ORNode *>*)nodes{
    
    ORInterpreter.shared.currentNodes = nodes;
    
    MFScopeChain *scope = [MFScopeChain topScope];
    
    //添加函数、变量等
    mf_add_built_in(scope);
    
    //链接函数指针，过滤一次
    nodes = [self linkFunctions:nodes scope:scope];
    
    //注册Protcol 注册Class 全局函数声明等
    for (ORNode *node in nodes) {
        [node execute:scope];
    }
}
+ (NSArray *)linkFunctions:(NSArray *)nodes scope:(MFScopeChain *)scope{
    NSMutableArray <ORTypeVarPair *>*funcVars = [NSMutableArray array];
    NSMutableArray *normalStatements = [NSMutableArray array];
    NSMutableArray *names = [NSMutableArray array];
    for (id <OCExecute> expression in nodes) {
        if ([expression isKindOfClass:[ORDeclareExpression class]]) {
            ORTypeVarPair *pair = [(ORDeclareExpression *)expression pair];
            NSString *name = pair.var.varname;
            if ([pair.var isKindOfClass:[ORFuncVariable class]]) {
                if ([ORGlobalFunctionTable.shared getFunctionNodeWithName:name] == nil) {
                    [funcVars addObject:pair];
                    [names addObject:name];
                }
                continue;
            }
        }
        //过滤 link functions
        [normalStatements addObject:expression];
    }
    //获取函数指针
    NSDictionary *table = [ORSearchedFunction functionTableForNames:names];
    for (ORTypeVarPair *pair in funcVars) {
        ORSearchedFunction *function = table[pair.var.varname];
        function.funPair = pair;
        // 将每个ORSearchedFunction都保存在ORGlobalFunctionTable中，保证不会被释放。
        // 因为在SymbolSearch.c中，将会给它的pointer成员变量赋值，如果在赋值前，对象被释放了，那么在给function->pointer赋值时将会得到一个访问已经被释放内存的错误。
        [[ORGlobalFunctionTable shared] setFunctionNode:function WithName:function.name];
    }
    #if DEBUG
    NSMutableArray *functionNames = [NSMutableArray array];
    for (ORTypeVarPair *pair in funcVars){
        NSString *functionName = pair.var.varname;
        ORSearchedFunction *function = table[functionName];
        if (function.pointer == NULL
            && [ORSystemFunctionPointerTable pointerForFunctionName:functionName] == NULL
            && [[MFScopeChain topScope] getValueWithIdentifier:functionName] == nil) {
            [functionNames addObject:functionName];
        }
    }
    if (functionNames.count > 0) {
        NSMutableString *build_ins = [@"" mutableCopy];
        [build_ins appendString:@"\n|----------------------------------------------|"];
        [build_ins appendString:@"\n|❕you need add ⬇️ code in the application file|"];
        [build_ins appendString:@"\n|----------------------------------------------|\n"];
        for (NSString *name in functionNames) {
            NSString *build_in_declare = [NSString stringWithFormat:@"[ORSystemFunctionPointerTable reg:@\"%@\" pointer:&%@];\n",name,name];
            [build_ins appendString:build_in_declare];
        }
        [build_ins appendString:@"-----------------------------------------------"];
        NSLog(@"%@", build_ins);
    }
    #endif
    return normalStatements;
}

+ (void)recover{
    [self recoverWithClearEnvironment:YES];
}
+ (void)recoverWithClearEnvironment:(BOOL)clear{
    if (ORInterpreter.shared.currentNodes == nil) {
        return;
    }
    for (ORNode *node in ORInterpreter.shared.currentNodes) {
        [node recover];
    }
    [[ORffiResultCache shared] clear];
    if (clear) {
        [[MFScopeChain topScope] clear];
        [[MFStaticVarTable shareInstance] clear];
        [[ORTypeSymbolTable shareInstance] clear];
    }
    ORInterpreter.shared.currentNodes = [NSArray array];
}
@end
