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
#import <oc2mangoLib/oc2mangoLib.h>
#import "ORSystemFunctionPointerTable.h"
#import "MFStaticVarTable.h"
#import "ORffiResultCache.h"

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

+ (void)excuteNodes:(NSArray <ORNode *>*)nodes{
    
    InitialSymbolTableVisitor *visitor = [InitialSymbolTableVisitor new];
    symbolTableRoot = [ocSymbolTable new];
    for (ORNode *node in nodes) {
        [visitor visit:node];
    }
    
    [ORInterpreter shared]->constants = symbolTableRoot->constants;
    [ORInterpreter shared]->constants_size = symbolTableRoot->constants_size;
    
    ORInterpreter.shared.currentNodes = nodes;
    
    MFScopeChain *scope = [MFScopeChain topScope];
    
    //添加函数、变量等
    mf_add_built_in(scope);
    
    //链接函数指针，过滤一次
    nodes = [self linkFunctions:nodes scope:scope];
    void *ctx = thread_current_context();
    //注册Protcol 注册Class 全局函数声明等
    for (ORNode *node in nodes) {
        eval((ORInterpreter *)self, ctx, scope, node);
    }
    
}
+ (NSArray *)linkFunctions:(NSArray *)nodes scope:(MFScopeChain *)scope{
    NSMutableArray <ORDeclaratorNode *>*funcVars = [NSMutableArray array];
    NSMutableArray *normalStatements = [NSMutableArray array];
    NSMutableArray *names = [NSMutableArray array];
    for (id expression in nodes) {
        
        if ([expression isKindOfClass:[ORInitDeclaratorNode class]]) {
            ORDeclaratorNode *pair = [(ORInitDeclaratorNode *)expression declarator];
            NSString *name = pair.var.varname;
            if ([pair isKindOfClass:[ORFunctionDeclNode class]]) {
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
    for (ORDeclaratorNode *pair in funcVars) {
        ORSearchedFunction *function = table[pair.var.varname];
        function.funPair = pair;
        // 将每个ORSearchedFunction都保存在ORGlobalFunctionTable中，保证不会被释放。
        // 因为在SymbolSearch.c中，将会给它的pointer成员变量赋值，如果在赋值前，对象被释放了，那么在给function->pointer赋值时将会得到一个访问已经被释放内存的错误。
        [[ORGlobalFunctionTable shared] setFunctionNode:function WithName:function.name];
    }
    #if DEBUG
    NSMutableArray *functionNames = [NSMutableArray array];
    for (ORDeclaratorNode *pair in funcVars){
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
//        [[ORTypeSymbolTable shareInstance] clear];
    }
    ORInterpreter.shared.currentNodes = [NSArray array];
}
@end
