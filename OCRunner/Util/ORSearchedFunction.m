//
//  ORSearchedFunction.m
//  OCRunner
//
//  Created by Jiang on 2020/6/9.
//  Copyright © 2020 SilverFruity. All rights reserved.
//

#import "ORSearchedFunction.h"
#import "SymbolSearch.h"
#import "RunnerClasses+Execute.h"
#import "ORThreadContext.h"
#import "MFValue.h"
#import "ORTypeVarPair+TypeEncode.h"
#import "ORCoreImp.h"
#import "ORHandleTypeEncode.h"
#import "ORStructDeclare.h"
#import "ORSystemFunctionPointerTable.h"
@implementation ORSearchedFunction
- (ORFuncVariable *)funVar{
    return (ORFuncVariable *)self.funPair.var;
}
+ (instancetype)functionWithName:(NSString *)name{
    ORSearchedFunction *function = [ORSearchedFunction new];
    function.name = name;
    return function;
}
+ (NSDictionary *)functionTableForNames:(NSArray *)names{
    //函数声明去重，解决多次链接的问题，因为最后一次查找始终会为NULL
    names = [[NSSet setWithArray:names] allObjects];
    struct FunctionSearch searches[names.count];
    NSMutableDictionary *table = [NSMutableDictionary dictionary];
    for (int i = 0; i < names.count; i++) {
        NSString *name = names[i];
        ORSearchedFunction *result = [ORSearchedFunction functionWithName:name];
        searches[i] = makeFunctionSearch(name.UTF8String, &result->_pointer);
        table[name] = result;
    }
    search_symbols(searches, names.count);
    return table;
}
- (nullable MFValue *)execute:(nonnull MFScopeChain *)scope {
    NSArray <MFValue *>*args = [ORArgsStack pop];
    const char *org_typeencode = self.funPair.typeEncode;
    if (org_typeencode == NULL) {
        NSLog(@"OCRunner Error: Unknow return type of C function '%@'", self.name);
        return [MFValue nullValue];
    }

    // 根据声明的类型进行转换
    do {
        if (self.funVar == nil) break;
        NSAssert([self.funVar isKindOfClass:[ORFuncVariable class]], @"funVar must be ORFuncVariable");
        ORFuncVariable *funcDecl = self.funVar;
        NSArray <ORTypeVarPair*> *declArgs = funcDecl.pairs;
        // ignore 'void xxx(void)'
        if (declArgs.count == 1 && declArgs[0].type.type == TypeVoid && declArgs[0].var.ptCount == 0) break;
        for (int i = 0; i < declArgs.count; i++) {
            args[i].typeEncode = declArgs[i].typeEncode;
        }
    } while (0);

    MFValue *returnValue = [MFValue defaultValueWithTypeEncoding:org_typeencode];
    void *funcptr = self.pointer != NULL ? self.pointer : [ORSystemFunctionPointerTable pointerForFunctionName:self.name];
    if (funcptr == NULL) {
        NSLog(@"OCRunner Error: Not found the pointer of C function '%@'", self.name);
        return [MFValue nullValue];
    }
    if (!self.funVar.isMultiArgs) {
        invoke_functionPointer(funcptr, args, returnValue);
        //多参数
    }else{
        invoke_functionPointer(funcptr, args, returnValue, self.funVar.pairs.count);
    }
    return returnValue;
}

@end
