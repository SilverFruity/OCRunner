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
#import "ORTypeVarPair+TypeEncode.h"
@implementation ORInterpreter
+ (void)excute:(NSString *)string{
    //添加内置结构体、函数、变量等
    mf_add_built_in();
    MFScopeChain *scope = [MFScopeChain topScope];
    AST *abstractAst = [OCParser parseSource:string];
    
    //执行Class, Protcol, 全局变量，全局函数声明, typdef, struct, enum等
    for (ORNode *node in abstractAst.nodes){
        //跳过系统函数声明，防止向全局作用域注册变量
        if ([node isKindOfClass:[ORDeclareExpression class]]) {
            ORTypeVarPair *pair = [(ORDeclareExpression *)node pair];
            if ([pair.var isKindOfClass:[ORFuncVariable class]]
                && !pair.var.isBlock
                && pair.var.ptCount == 0) {
                continue;
            }
        }
        [node execute:scope];
    }
    
    //获取系统函数指针
    [self linkSystemFunctionsWithNodes:abstractAst.nodes scope:scope];
    
    //执行main函数
    MFValue *mainValue = [scope getValueWithIdentifier:@"main"];
    if (mainValue != nil && [mainValue.objectValue isKindOfClass:[ORFunctionImp class]]) {
        ORFunctionImp *mainFunction = mainValue.objectValue;
        //模拟传参
        NSMutableArray *args = [NSMutableArray array];
        for (ORTypeVarPair *pair in mainFunction.declare.funVar.pairs){
            [args addObject:[MFValue defaultValueWithTypeEncoding:[pair typeEncode]]];
        }
        [ORArgsStack push:args];
        [(ORFunctionImp *)mainFunction execute:scope];
    }
}

+ (void)linkSystemFunctionsWithNodes:(NSArray <ORNode *>*)nodes scope:(MFScopeChain *)scope{
    NSMutableArray <ORTypeVarPair *>*funcVars = [NSMutableArray array];
    NSMutableArray *names = [NSMutableArray array];
    for (id <OCExecute> expression in nodes) {
        if ([expression isKindOfClass:[ORDeclareExpression class]]) {
            ORTypeVarPair *pair = [(ORDeclareExpression *)expression pair];
            //不能是Block声明或者是函数指针声明
            if ([pair.var isKindOfClass:[ORFuncVariable class]]
                && !pair.var.isBlock
                && pair.var.ptCount == 0) {
                [funcVars addObject:pair];
                [names addObject:pair.var.varname];
            }
        }
    }
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
        NSAssert(NO, @"");
    }
#endif
}
@end
