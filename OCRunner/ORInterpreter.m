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

@implementation ORInterpreter
+ (void)excute:(NSString *)string{
    //添加内置结构体、函数、变量等
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
    //执行全局变量，全局函数声明
    NSMutableArray <ORTypeVarPair *>*funcVars = [NSMutableArray array];
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
        [expression execute:scope];
    }
    //获取函数指针
    NSDictionary *table = [ORSearchedFunction functionTableForNames:names];
    for (ORTypeVarPair *pair in funcVars) {
        ORSearchedFunction *function = table[pair.var.varname];
        function.funPair = pair;
        [scope setValue:[MFValue valueWithObject:function] withIndentifier:function.name];
    }
    #if DEBUG
    NSMutableString *build_ins = [@"\n" mutableCopy];
    for (ORTypeVarPair *pair in funcVars){
        NSString *name = pair.var.varname;
        NSString *build_in_declare = [NSString stringWithFormat:@"[ORSystemFunctionTable reg:@\"%@\" pointer:&%@];\n",name,name];
        [build_ins appendString:build_in_declare];
    }
    NSLog(@"%@", build_ins);
    #endif
}
@end
