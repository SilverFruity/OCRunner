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

@implementation ORInterpreter
+ (void)excute:(NSString *)string{
    //TODO: 添加内置结构体、函数、变量等
    mf_add_built_in();
    MFScopeChain *scope = [MFScopeChain topScope];
    [OCParser parseSource:string];
    //TODO: 注册Class
    for (id <OCExecute> clazz in OCParser.ast.sortClasses){
        [clazz execute:scope];
    }
    //TODO: 执行全局变量，全局函数声明
    for (id <OCExecute> expression in OCParser.ast.globalStatements) {
        [expression execute:scope];
    }
}
@end
