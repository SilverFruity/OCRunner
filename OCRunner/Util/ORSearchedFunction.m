//
//  ORSearchedFunction.m
//  OCRunner
//
//  Created by Jiang on 2020/6/9.
//  Copyright © 2020 SilverFruity. All rights reserved.
//

#import "ORSearchedFunction.h"
#import "SymbolSearch.h"
#import "RunnerClasses.h"
#import "ORArgsStack.h"
#import "MFValue.h"
#import "ORTypeVarPair+TypeEncode.h"
#import "ORCoreImp.h"
#import "ORHandleTypeEncode.h"
#import "ORStructDeclare.h"
#import "ORSystemFunctionTable.h"
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
    NSString *typeName = self.funPair.type.name;
    ORTypeVarPair *registerPair = [[ORTypeSymbolTable shareInstance] typePairForTypeName:typeName];
    const char *typeEncode = self.funPair.typeEncode;
    if (registerPair) {
        if (registerPair.type.type == TypeStruct) {
            ORStructDeclare *declare = [[ORStructDeclareTable shareInstance] getStructDeclareWithName:typeName];
            typeEncode = declare.typeEncoding;
        }else{
            typeEncode = registerPair.typeEncode;
        }
    }
    MFValue *returnValue = [MFValue defaultValueWithTypeEncoding:typeEncode];
    void *funcptr = self.pointer;
    if (funcptr == NULL) {
        funcptr = [ORSystemFunctionTable pointerForFunctionName:self.name];
    }
#if DEBUG
    if (funcptr == NULL) {
        NSLog(@"\n****************************************\n"
              @"❕you need add the code in the application:\n"
              @"[ORSystemFunctionTable reg:@\"%@\" pointer:&%@];\n"
              @"****************************************\n",self.name,self.name);
    }
#endif
    NSAssert(funcptr != NULL, @"not found function %@", self.name);
    if (!self.funVar.isMultiArgs) {
        invoke_functionPointer(funcptr, args, returnValue);
        //多参数
    }else{
        invoke_functionPointer(funcptr, args, returnValue, self.funVar.pairs.count);
    }
    return returnValue;
}

@end
