//
//  ORInterpreter.m
//  OCRunner
//
//  Created by Jiang on 2020/5/23.
//  Copyright © 2020 SilverFruity. All rights reserved.
//

#import "ORInterpreter.h"
#import <oc2mangoLib/oc2mangoLib.h>
#import "RunnerClasses+Execute.h"
#import "MFScopeChain.h"
#import "ORSearchedFunction.h"
#import "MFValue.h"
#import "ORStructDeclare.h"
#import "ORSystemFunctionTable.h"
@implementation ORInterpreter
+ (void)excute:(NSString *)string{
    //添加函数、变量等
    mf_add_built_in();
    MFScopeChain *scope = [MFScopeChain topScope];
    AST *abstractAst = [OCParser parseSource:string];
    //注册Protcol
    for (id <OCExecute> protcol in abstractAst.protcolCache.allValues){
        [protcol execute:scope];
    }
    //注册Class
    for (id <OCExecute> clazz in abstractAst.sortClasses){
        [clazz execute:scope];
    }
    
    //链接函数指针
    [self linkFunctions:abstractAst scope:scope];
    
    // 执行全局函数声明等
    for (id <OCExecute> expression in abstractAst.globalStatements) {
        [expression execute:scope];
    }
}

+ (void)linkFunctions:(AST *)abstractAst scope:(MFScopeChain *)scope{
    NSMutableArray <ORTypeVarPair *>*funcVars = [NSMutableArray array];
    NSMutableArray *normalStatements = [NSMutableArray array];
    NSMutableArray *names = [NSMutableArray array];
    for (id <OCExecute> expression in abstractAst.globalStatements) {
        if ([expression isKindOfClass:[ORDeclareExpression class]]) {
            ORTypeVarPair *pair = [(ORDeclareExpression *)expression pair];
            if ([pair.var isKindOfClass:[ORFuncVariable class]]) {
                [funcVars addObject:pair];
                [names addObject:pair.var.varname];
                continue;
            }
        }
        [normalStatements addObject:expression];
    }
    //过滤 link functions
    abstractAst.globalStatements = normalStatements;
    
    //获取函数指针
    NSDictionary *table = [ORSearchedFunction functionTableForNames:names];
    for (ORTypeVarPair *pair in funcVars) {
        ORSearchedFunction *function = table[pair.var.varname];
        function.funPair = pair;
        if ([scope getValueWithIdentifier:function.name] == nil) {
            [scope setValue:[MFValue valueWithObject:function] withIndentifier:function.name];
        }
    }
    #if DEBUG
    NSMutableArray *functionNames = [NSMutableArray array];
    for (ORTypeVarPair *pair in funcVars){
        NSString *functionName = pair.var.varname;
        ORSearchedFunction *function = table[functionName];
        if (function.pointer == NULL
            && [ORSystemFunctionTable pointerForFunctionName:functionName] == NULL) {
            MFValue *value = [[MFScopeChain topScope] getValueWithIdentifier:functionName];
            if (value == nil || [value.objectValue isKindOfClass:[ORSearchedFunction class]]) {
                [functionNames addObject:functionName];
            }
        }
    }
    if (functionNames.count > 0) {
        NSMutableString *build_ins = [@"" mutableCopy];
        [build_ins appendString:@"\n|----------------------------------------------|"];
        [build_ins appendString:@"\n|❕you need add ⬇️ code in the application file|"];
        [build_ins appendString:@"\n|----------------------------------------------|\n"];
        for (NSString *name in functionNames) {
            NSString *build_in_declare = [NSString stringWithFormat:@"[ORSystemFunctionTable reg:@\"%@\" pointer:&%@];\n",name,name];
            [build_ins appendString:build_in_declare];
        }
        [build_ins appendString:@"-----------------------------------------------"];
        NSLog(@"%@", build_ins);
    }
    #endif
}
@end
