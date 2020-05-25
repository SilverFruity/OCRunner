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
void classLevelDetect(ORClass *class, int *level){
    if ([class.superClassName isEqualToString:@"NSObject"] || NSClassFromString(class.superClassName) != nil) {
        return;
    }
    ORClass *superClass = OCParser.ast.classCache[class.superClassName];
    if (superClass) {
        (*level)++;
    }else{
        return;
    }
    classLevelDetect(superClass, level);
}
@implementation ORInterpreter
+ (void)excute:(NSString *)string{
    //TODO: 添加内置结构体、函数、变量等
    mf_add_built_in();
    
    MFScopeChain *scope = [MFScopeChain topScope];
    [OCParser parseSource:string];
    //TODO: 根据Class继承关系，进行排序
    NSMutableDictionary <NSString *, NSNumber *>*classProrityDict = [@{@"NSObject":@(0)} mutableCopy];
    for (ORClass *clazz in OCParser.ast.classCache.allValues) {
        int prority = 0;
        classLevelDetect(clazz, &prority);
        classProrityDict[clazz.className] = @(prority);
    }
    NSArray *classes = OCParser.ast.classCache.allValues;
    [classes sortedArrayUsingComparator:^NSComparisonResult(ORClass *obj1, ORClass *obj2) {
        return classProrityDict[obj1.className].intValue < classProrityDict[obj1.className].intValue;
    }];
    //TODO: 注册Class
    for (id <OCExecute> clazz in classes){
        [clazz execute:scope];
    }
    //TODO: 执行全局变量，全局函数声明
    for (id <OCExecute> expression in OCParser.ast.globalStatements) {
        [expression execute:scope];
    }
}
@end
