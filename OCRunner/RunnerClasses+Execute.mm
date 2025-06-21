//
//  ORunner+Execute.m
//  MangoFix
//
//  Created by Jiang on 2020/5/8.
//  Copyright © 2020 yongpengliang. All rights reserved.
//

#import "RunnerClasses+Execute.h"
#import "MFScopeChain.h"
#import "util.h"
#import "MFMethodMapTable.h"
#import "MFPropertyMapTable.h"
#import "MFVarDeclareChain.h"
#import "MFBlock.h"
#import "MFValue.h"
#import "MFStaticVarTable.h"
#import "ORStructDeclare.h"
#import <objc/message.h>
#import "ORTypeVarPair+TypeEncode.h"
#import "ORCoreImp.h"
#import "ORSearchedFunction.h"
#import "ORffiResultCache.h"
#import "ORThreadContext.h"

static MFValue * invoke_MFBlockValue(MFValue *blockValue, NSArray *args){
    id block = blockValue.objectValue;
#if DEBUG
    if (block == nil) {
        NSLog(@"%@",[ORCallFrameStack history]);
    }
#endif
    assert(block != nil);
    const char *blockTypeEncoding = NSBlockGetSignature(block);
    NSMethodSignature *sig = [NSMethodSignature signatureWithObjCTypes:blockTypeEncoding];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:sig];
    [invocation setTarget:block];
    NSUInteger numberOfArguments = [sig numberOfArguments];
    if (numberOfArguments - 1 != args.count) {
        return [MFValue valueWithObject:nil];
    }
    //根据MFValue的type传入值的原因: 模拟在OC中的调用
    for (NSUInteger i = 1; i < numberOfArguments; i++) {
        MFValue *argValue = args[i -1];
        // 基础类型转换
        argValue.typeEncode = [sig getArgumentTypeAtIndex:i];
        [invocation setArgument:argValue.pointer atIndex:i];
    }
    [invocation invoke];
    const char *retType = [sig methodReturnType];
    retType = removeTypeEncodingPrefix((char *)retType);
    if (*retType == 'v') {
        return [MFValue voidValue];
    }
    void *retValuePtr = alloca(mf_size_with_encoding(retType));
    [invocation getReturnValue:retValuePtr];
    return [[MFValue alloc] initTypeEncode:retType pointer:retValuePtr];;
}
void or_method_replace(BOOL isClassMethod, Class clazz, SEL sel, IMP imp, const char *typeEncode){
    Method ocMethod;
    if (isClassMethod) {
        ocMethod = class_getClassMethod(clazz, sel);
    }else{
        ocMethod = class_getInstanceMethod(clazz, sel);
    }
    if (ocMethod) {
        typeEncode = method_getTypeEncoding(ocMethod);
    }
    Class c2 = isClassMethod ? objc_getMetaClass(class_getName(clazz)) : clazz;
    if (class_respondsToSelector(c2, sel)) {
        NSString *orgSelName = [NSString stringWithFormat:@"ORG%@", NSStringFromSelector(sel)];
        SEL orgSel = NSSelectorFromString(orgSelName);
        if (!class_respondsToSelector(c2, orgSel)) {
            class_addMethod(c2, orgSel, method_getImplementation(ocMethod), typeEncode);
        }
    }
    class_replaceMethod(c2, sel, imp, typeEncode);
}
static void replace_method(Class clazz, ORMethodImplementation *methodImp){
    const char *typeEncoding = methodImp.declare.returnType.typeEncode;
    typeEncoding = mf_str_append(typeEncoding, "@:"); //add node and _cmd
    for (ORTypeVarPair *pair in methodImp.declare.parameterTypes) {
        const char *paramTypeEncoding = pair.typeEncode;
        const char *beforeTypeEncoding = typeEncoding;
        typeEncoding = mf_str_append(typeEncoding, paramTypeEncoding);
        free((void *)beforeTypeEncoding);
    }
    Class c2 = methodImp.declare.isClassMethod ? objc_getMetaClass(class_getName(clazz)) : clazz;
    MFMethodMapTableItem *item = [[MFMethodMapTableItem alloc] initWithClass:c2 method:methodImp];
    [[MFMethodMapTable shareInstance] addMethodMapTableItem:item];
    ORMethodDeclare *declare = methodImp.declare;
    or_ffi_result *result = register_method(&methodIMP, declare.parameterTypes, declare.returnType, (__bridge_retained void *)methodImp);
    [[ORffiResultCache shared] saveffiResult:result WithKey:[NSValue valueWithPointer:(__bridge void *)methodImp]];
    SEL sel = NSSelectorFromString(methodImp.declare.selectorName);
    or_method_replace(methodImp.declare.isClassMethod, clazz, sel, (IMP)result->function_imp, typeEncoding);
    free((void *)typeEncoding);
}

static void replace_getter_method(Class clazz, ORPropertyDeclare *prop){
    SEL getterSEL = NSSelectorFromString(prop.var.var.varname);
    const char *retTypeEncoding  = prop.var.typeEncode;
    const char * typeEncoding = mf_str_append(retTypeEncoding, "@:");
    or_ffi_result *result = register_method(&getterImp, @[], prop.var, (__bridge  void *)prop);
    [[ORffiResultCache shared] saveffiResult:result WithKey:[NSValue valueWithPointer:(__bridge void *)prop]];
    or_method_replace(NO, clazz, getterSEL, (IMP)result->function_imp, typeEncoding);
    free((void *)typeEncoding);
}

static void replace_setter_method(Class clazz, ORPropertyDeclare *prop){
    NSString *name = prop.var.var.varname;
    NSString *str1 = [[name substringWithRange:NSMakeRange(0, 1)] uppercaseString];
    NSString *str2 = name.length > 1 ? [name substringFromIndex:1] : @"";
    SEL setterSEL = NSSelectorFromString([NSString stringWithFormat:@"set%@%@:",str1,str2]);
    const char *prtTypeEncoding  = prop.var.typeEncode;
    const char * typeEncoding = mf_str_append("v@:", prtTypeEncoding);
    or_ffi_result *result = register_method(&setterImp, @[prop.var], [ORTypeVarPair typePairWithTypeKind:TypeVoid],(__bridge_retained  void *)prop);
    or_method_replace(NO, clazz, setterSEL, (IMP)result->function_imp, typeEncoding);
    free((void *)typeEncoding);
}

static void copy_undef_var(ORNode * exprOrStatement, MFVarDeclareChain *chain, MFScopeChain *fromScope, MFScopeChain *destScope);

void copy_undef_vars(NSArray *exprOrStatements, MFVarDeclareChain *chain, MFScopeChain *fromScope, MFScopeChain *destScope){
    for (ORNode * exprOrStatement in exprOrStatements) {
        copy_undef_var(exprOrStatement, chain, fromScope, destScope);
    }
}

/// Block执行时的外部变量捕获
static void copy_undef_var(ORNode *exprOrStatement, MFVarDeclareChain *chain, MFScopeChain *fromScope, MFScopeChain *destScope){
    if (!exprOrStatement) {
        return;
    }
    AstEnum nodeType = exprOrStatement.nodeType;
    if (nodeType == AstEnumValueExpression) {
        ORValueExpression *expr = (ORValueExpression *)exprOrStatement;
        switch (expr.value_type) {
            case OCValueNSNumber:{
                copy_undef_var(expr.value, chain, fromScope, destScope);
                break;
            }
            case OCValueDictionary:{
                for (NSArray *kv in expr.value) {
                    ORNode *keyExp = kv.firstObject;
                    ORNode *valueExp = kv.lastObject;
                    copy_undef_var(keyExp, chain, fromScope, destScope);
                    copy_undef_var(valueExp, chain, fromScope, destScope);
                }
                break;
            }
            case OCValueArray:{
                for (ORNode *valueExp in expr.value) {
                    copy_undef_var(valueExp, chain, fromScope, destScope);
                }
                break;
            }
            case OCValueSelf:
            case OCValueSuper:{
                destScope.instance = fromScope.instance;
                break;
            }
            case OCValueVariable:{
                NSString *identifier = expr.value;
                if (![chain isInChain:identifier]) {
                   MFValue *value = [fromScope recursiveGetValueWithIdentifier:identifier];
                    if (value) {
                        [destScope setValue:value withIndentifier:identifier];
                    }
                }
            }
            default:
                break;
        }
    }else if (nodeType == AstEnumAssignExpression) {
        ORAssignExpression *expr = (ORAssignExpression *)exprOrStatement;
        copy_undef_var(expr.value, chain, fromScope, destScope);
        copy_undef_var(expr.expression, chain, fromScope, destScope);
        return;
    }else if (nodeType == AstEnumBinaryExpression){
        ORBinaryExpression *expr = (ORBinaryExpression *)exprOrStatement;
        copy_undef_var(expr.left, chain, fromScope, destScope);
        copy_undef_var(expr.right, chain, fromScope, destScope);
        return;
    }else if (nodeType == AstEnumTernaryExpression){
        ORTernaryExpression *expr = (ORTernaryExpression *)exprOrStatement;
        copy_undef_var(expr.expression, chain, fromScope, destScope);
        copy_undef_vars(expr.values, chain, fromScope, destScope);
        return;
    }else if (nodeType == AstEnumUnaryExpression){
        ORUnaryExpression *expr = (ORUnaryExpression *)exprOrStatement;
        copy_undef_var(expr.value, chain, fromScope, destScope);
        return;
    }else if (nodeType == AstEnumCFuncCall){
        ORCFuncCall *expr = (ORCFuncCall *)exprOrStatement;
        copy_undef_var(expr.caller, chain, fromScope, destScope);
        copy_undef_vars(expr.expressions, chain, fromScope, destScope);
        return;
    }else if (nodeType == AstEnumSubscriptExpression){
        ORSubscriptExpression *expr = (ORSubscriptExpression *)exprOrStatement;
        copy_undef_var(expr.caller, chain, fromScope, destScope);
        copy_undef_var(expr.keyExp, chain, fromScope, destScope);
        return;
    }else if (nodeType == AstEnumMethodCall){
        ORMethodCall *expr = (ORMethodCall *)exprOrStatement;
        copy_undef_var(expr.caller, chain, fromScope, destScope);
        copy_undef_vars(expr.values, chain, fromScope, destScope);
        return;
    }else if (nodeType == AstEnumFunctionImp){
        ORFunctionImp *expr = (ORFunctionImp *)exprOrStatement;
        ORFuncDeclare *funcDeclare = expr.declare;
        MFVarDeclareChain *funcChain = [MFVarDeclareChain varDeclareChainWithNext:chain];
        NSArray <ORTypeVarPair *>*params = funcDeclare.funVar.pairs;
        for (ORTypeVarPair *param in params) {
            [funcChain addIndentifer:param.var.varname];
        }
        copy_undef_var(expr.scopeImp, funcChain, fromScope, destScope);
        return;
    }else if (nodeType == AstEnumScopeImp){
        ORScopeImp *scopeImp = (ORScopeImp *)exprOrStatement;
        MFVarDeclareChain *scopeChain = [MFVarDeclareChain varDeclareChainWithNext:chain];
        copy_undef_vars(scopeImp.statements, scopeChain, fromScope, destScope);
        return;
    }
    else if (nodeType == AstEnumDeclareExpression){
        ORDeclareExpression *expr = (ORDeclareExpression *)exprOrStatement;
        NSString *name = expr.pair.var.varname;
        [chain addIndentifer:name];
        copy_undef_var(expr.expression, chain, fromScope, destScope);
        return;
        
    }else if (nodeType == AstEnumIfStatement){
        ORIfStatement *ifStatement = (ORIfStatement *)exprOrStatement;
        copy_undef_var(ifStatement.condition, chain, fromScope, destScope);
        MFVarDeclareChain *ifChain = [MFVarDeclareChain varDeclareChainWithNext:chain];
        copy_undef_var(ifStatement.scopeImp, ifChain, fromScope, destScope);
        copy_undef_var(ifStatement.last, chain, fromScope, destScope);
        return;
    }else if (nodeType == AstEnumSwitchStatement){
        ORSwitchStatement *swithcStatement = (ORSwitchStatement *)exprOrStatement;
        copy_undef_var(swithcStatement.value, chain, fromScope, destScope);
        copy_undef_vars(swithcStatement.cases, chain, fromScope, destScope);
        MFVarDeclareChain *defChain = [MFVarDeclareChain varDeclareChainWithNext:chain];
        copy_undef_var(swithcStatement.scopeImp, defChain, fromScope, destScope);
        return;
        
    }else if (nodeType == AstEnumCaseStatement){
        ORCaseStatement *caseStatement = (ORCaseStatement *)exprOrStatement;
        copy_undef_var(caseStatement.value, chain, fromScope, destScope);
        MFVarDeclareChain *caseChain = [MFVarDeclareChain varDeclareChainWithNext:chain];
        copy_undef_var(caseStatement.scopeImp, caseChain, fromScope, destScope);
        return;
    }else if (nodeType == AstEnumForStatement){
        ORForStatement *forStatement = (ORForStatement *)exprOrStatement;
        MFVarDeclareChain *forChain = [MFVarDeclareChain varDeclareChainWithNext:chain];
        copy_undef_vars(forStatement.varExpressions, forChain, fromScope, destScope);
        copy_undef_var(forStatement.condition, forChain, fromScope, destScope);
        copy_undef_vars(forStatement.expressions, forChain, fromScope, destScope);
        copy_undef_var(forStatement.scopeImp, forChain, fromScope, destScope);
    }else if (nodeType == AstEnumForInStatement){
        ORForInStatement *forEachStatement = (ORForInStatement *)exprOrStatement;
        MFVarDeclareChain *forEachChain = [MFVarDeclareChain varDeclareChainWithNext:chain];
        copy_undef_var(forEachStatement.expression, forEachChain, fromScope, destScope);
        copy_undef_var(forEachStatement.value, forEachChain, fromScope, destScope);
        copy_undef_var(forEachStatement.scopeImp, forEachChain, fromScope, destScope);
    }else if (nodeType == AstEnumWhileStatement){
        ORWhileStatement *whileStatement = (ORWhileStatement *)exprOrStatement;
        copy_undef_var(whileStatement.condition, chain, fromScope, destScope);
        MFVarDeclareChain *whileChain = [MFVarDeclareChain varDeclareChainWithNext:chain];
        copy_undef_var(whileStatement.scopeImp, whileChain, fromScope, destScope);
    }else if (nodeType == AstEnumDoWhileStatement){
        ORDoWhileStatement *doWhileStatement = (ORDoWhileStatement *)exprOrStatement;
        copy_undef_var(doWhileStatement.condition, chain, fromScope, destScope);
        MFVarDeclareChain *doWhileChain = [MFVarDeclareChain varDeclareChainWithNext:chain];
        copy_undef_var(doWhileStatement.scopeImp, doWhileChain, fromScope, destScope);
    }else if (nodeType == AstEnumReturnStatement){
        ORReturnStatement *returnStatement = (ORReturnStatement *)exprOrStatement;
        copy_undef_var(returnStatement.expression, chain, fromScope, destScope);
    }else if (nodeType == AstEnumContinueStatement){
        
    }else if (nodeType == AstEnumBreakStatement){
        
    }
}

MFValue * evalORFuncVariable (ORFuncVariable  *node, MFScopeChain * scope) {
    return [MFValue voidValue];
}

MFValue * evalORFuncDeclare(ORFuncDeclare *node, MFScopeChain * scope) {
    NSMutableArray <MFValue *>*parameters = [ORArgsStack pop];
    // 类型转换
    do {
        NSArray <ORTypeVarPair *>*declArgs = node.funVar.pairs;
        // ignore 'void xxx(void)'
        if (declArgs.count == 1 && declArgs[0].type.type == TypeVoid && declArgs[0].var.ptCount == 0) break;
        for (int i = 0; i < declArgs.count; i++) {
            parameters[i].typeEncode = declArgs[i].typeEncode;
        }
    } while (0);

    [parameters enumerateObjectsUsingBlock:^(MFValue * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [scope setValue:obj withIndentifier:node.funVar.pairs[idx].var.varname];
    }];
    return nil;
}

MFValue * evalORValueExpression (ORValueExpression  *node, MFScopeChain * scope) {
    switch (node.value_type) {
        case OCValueVariable:{
            MFValue *value = [scope recursiveGetValueWithIdentifier:node.value];
            if (value != nil) return value;
            Class clazz = NSClassFromString(node.value);
            if (clazz) {
                value = [MFValue valueWithClass:clazz];
            }else{
#if DEBUG
                if (node.value) {
                    NSLog(@"\
\n---------OCRunner Error---------\n\
*Unknown variable or class: '%@'*\n\
%@\n\
you should add a (enum declare / global variable or others) in OCRunner scripts.\n\
for example:\n\
if it is a UIControlStateNormal, you should add a enum declare in Script\n\
```\n\
typedef NS_OPTIONS(NSUInteger, UIControlState) {\n\
  UIControlStateNormal       = 0,\n\
  UIControlStateHighlighted  = 1 << 0,\n\
  UIControlStateDisabled     = 1 << 1\n\
};\n\
```\n\
if it is a UIApplicationDidBecomeActiveNotification, then add a 'NSString *' global variable\n\
```\n\
NSString *UIApplicationDidBecomeActiveNotification = @\"UIApplicationDidBecomeActiveNotification\";\n\
```\n\
if it is a CGRectZero, then add a 'CGRect' global variable\n\
```\n\
CGRect CGRectZero = CGRectMake(0, 0, 0, 0);\n\
```\n\
-----------------------------------", node.value, [ORCallFrameStack history]);
//                    NSAssert(false, @"as mentioned above");
                }
#endif
                value = [MFValue nullValue];
            }
            return value;
        }
        case OCValueSelf:
        case OCValueSuper:{
            return scope.instance;
        }
        case OCValueSelector:{
            //SEL 作为参数时，在OC中，是以NSString传递的，1.0.4前的ORMethodCall只使用libffi调用objc_msgSend时，就会出现objc_retain的崩溃
            NSString *value = node.value;
            return [MFValue valueWithSEL:NSSelectorFromString(value)];
        }
        case OCValueProtocol:{
            return [MFValue valueWithObject:NSProtocolFromString(node.value)];
        }
        case OCValueDictionary:{
            NSMutableArray *exps = node.value;
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            for (NSMutableArray <ORNode *>*kv in exps) {
                ORNode *keyExp = kv.firstObject;
                ORNode *valueExp = kv.lastObject;
                id key = evalORNode(keyExp, scope).objectValue;
                id value = evalORNode(valueExp, scope).objectValue;
                if (key && value){
                    dict[key] = value;
                }else{
                    NSLog(@"OCRunner Error: the key '%@' or value '%@' of NSDictionary can't be nil", key?:@"null", value?:@"null");
                }
            }
            return [MFValue valueWithObject:[dict copy]];
        }
        case OCValueArray:{
            NSMutableArray *exps = node.value;
            NSMutableArray *array = [NSMutableArray array];
            for (ORNode *exp in exps) {
                id value = evalORNode(exp, scope).objectValue;
                if (value) {
                    [array addObject:value];
                }else{
                    NSLog(@"OCRunner Error: the value of NSArray can't be nil, %@", array);
                }
            }
            return [MFValue valueWithObject:[array copy]];
        }
        case OCValueNSNumber:{
            MFValue *value = evalORNode(node.value, scope);
            NSNumber *result = nil;
            UnaryExecuteBaseType(result, @, value);
            return [MFValue valueWithObject:result];
        }
        case OCValueString:{
            return [MFValue valueWithObject:node.value];
        }
        case OCValueCString:{
            NSString *value = node.value;
            return [MFValue valueWithCString:(char *)value.UTF8String];
        }
        case OCValueNil:{
            return [MFValue valueWithObject:nil];
        }
        case OCValueNULL:{
            return [MFValue nullValue];
        }
        default:
            break;
    }
    return [MFValue valueWithObject:nil];
}


MFValue * evalORIntegerValue (ORIntegerValue  *node, MFScopeChain * scope) {
    return [MFValue valueWithLongLong:node.value];;
}


MFValue * evalORUIntegerValue (ORUIntegerValue  *node, MFScopeChain * scope) {
    return [MFValue valueWithULongLong:node.value];;
}


MFValue * evalORDoubleValue (ORDoubleValue  *node, MFScopeChain * scope) {
    return [MFValue valueWithDouble:node.value];;
}

MFValue * evalORBoolValue (ORBoolValue  *node, MFScopeChain * scope) {
    return [MFValue valueWithBOOL:node.value];;
}


MFValue * evalORMethodCall(ORMethodCall *node, MFScopeChain * scope) {
    if ([node.caller isKindOfClass:[ORMethodCall class]]) {
        [(ORMethodCall *)node.caller setIsAssignedValue:node.isAssignedValue];
    }

    // we don't invoke [node ORGdealloc] and [super dealloc] immediately under script's dealloc method,
    // we will invoke them when we when exit dealloc method scope.
    if (scope.entryCtx.isDeallocScope && [node.caller isKindOfClass:[ORValueExpression class]] ) {
        ORValueExpression *value = (ORValueExpression *)node.caller;
        SEL sel = NSSelectorFromString(node.selectorName);
        if (value.value_type == OCValueSuper && sel == NSSelectorFromString(@"dealloc")) {
            // call [super dealloc]
            scope.entryCtx.deferCallSuperDealloc = YES;
            return [MFValue voidValue];
        } else if (value.value_type == OCValueSelf && sel == NSSelectorFromString(@"ORGdealloc")) {
            // call [node ORGdealloc]
            scope.entryCtx.deferCallOrigDealloc = YES;
            return [MFValue voidValue];
        }
    }

    MFValue *variable = evalORNode(node.caller, scope);
    if (variable.type == OCTypeStruct || variable.type == OCTypeUnion) {
        if ([node.names.firstObject hasPrefix:@"set"]) {
            NSString *setterName = node.names.firstObject;
            ORNode *valueExp = node.values.firstObject;
            NSString *fieldKey = [setterName substringFromIndex:3];
            NSString *first = [[fieldKey substringToIndex:1] lowercaseString];
            NSString *other = setterName.length > 1 ? [fieldKey substringFromIndex:1] : @"";
            fieldKey = [NSString stringWithFormat:@"%@%@", first, other];
            MFValue *value = evalORNode(valueExp, scope);
            if (variable.type == OCTypeStruct) {
                [variable setFieldWithValue:value forKey:fieldKey];
            }else{
                [variable setUnionFieldWithValue:value forKey:fieldKey];
            }
            return [MFValue voidValue];
        }else{
            if (variable.type == OCTypeStruct) {
                if (node.isAssignedValue) {
                    return [variable fieldNoCopyForKey:node.names.firstObject];
                }else{
                    return [variable fieldForKey:node.names.firstObject];
                }
            }else{
                return [variable unionFieldForKey:node.names.firstObject];;
            }
        }
    }
    id instance = variable.objectValue;
    SEL sel = NSSelectorFromString(node.selectorName);
    NSMutableArray <MFValue *>*argValues = [NSMutableArray array];
    for (ORValueExpression *exp in node.values){
        [argValues addObject:evalORNode(exp, scope)];
    }
    // instance为nil时，依然要执行参数相关的表达式
    if ([node.caller isKindOfClass:[ORValueExpression class]]) {
        ORValueExpression *value = (ORValueExpression *)node.caller;
        if (value.value_type == OCValueSuper) {
            return invoke_sueper_values(instance, sel, scope.classNode, argValues);
        }
    }
    if (instance == nil) {
        return [MFValue nullValue];
    }
    
    //如果在方法缓存表的中已经找到相关方法，直接调用，省去一次中间类型转换问题。优化性能，在方法递归时，调用耗时减少33%，0.15s -> 0.10s
    BOOL isClassMethod = object_isClass(instance);
    Class clazz = isClassMethod ? objc_getMetaClass(class_getName(instance)) : [instance class];
    MFMethodMapTableItem *map = [[MFMethodMapTable shareInstance] getMethodMapTableItemWith:clazz classMethod:isClassMethod sel:sel];
    if (map) {
        MFScopeChain *newScope = [MFScopeChain scopeChainWithNext:scope];
        newScope.instance = isClassMethod ? [MFValue valueWithClass:instance] : [MFValue valueWithUnRetainedObject:instance];
        newScope.entryCtx = [OREntryContext contextWithClass:map.methodImp.classNode];
        [ORArgsStack push:argValues];
        return evalORNode(map.methodImp, newScope);
    }
    NSMethodSignature *sig = [instance methodSignatureForSelector:sel];
    if (sig == nil) {
#if DEBUG
        NSLog(@"%@", [node unrecognizedSelectorTip:instance]);
//        NSAssert(false, @"As mentioned above");
#endif
        return [MFValue nullValue];
    }
    NSUInteger argCount = [sig numberOfArguments];
    //解决多参数调用问题
    if (argValues.count + 2 > argCount && sig != nil) {
        NSMutableArray *methodArgs = [@[[MFValue valueWithUnRetainedObject:instance],
                                       [MFValue valueWithSEL:sel]] mutableCopy];
        [methodArgs addObjectsFromArray:argValues];
        MFValue *result = [MFValue defaultValueWithTypeEncoding:[sig methodReturnType]];
        void *msg_send = (void *)&objc_msgSend;
        invoke_functionPointer(msg_send, methodArgs, result, argCount);
        return result;
    }else{
        void *retValuePointer = alloca([sig methodReturnLength]);
        char *returnType = (char *)[sig methodReturnType];
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:sig];
        invocation.target = instance;
        invocation.selector = sel;
        for (NSUInteger i = 2; i < argCount; i++) {
            MFValue *value = argValues[i-2];
            // 基础类型转换
            value.typeEncode = [sig getArgumentTypeAtIndex:i];
            [invocation setArgument:value.pointer atIndex:i];
        }
        // func replaceIMP execute
        [invocation invoke];
        returnType = removeTypeEncodingPrefix(returnType);
        if (*returnType == 'v') {
            return [MFValue voidValue];
        }
        [invocation getReturnValue:retValuePointer];
        MFValue *value = [[MFValue alloc] initTypeEncode:returnType pointer:retValuePointer];
        // 针对一下方法调用，需要和CF一样，最终都要release. 与JSPatch和Mango中的__bridge_transfer效果相同
        if (sel == @selector(alloc) || sel == @selector(new)||
            sel == @selector(copy) || sel == @selector(mutableCopy)) {
            CFRelease(*(void **)retValuePointer);
        }
        return value;
    }
}

@implementation ORMethodCall (Execute)
#if DEBUG
// 尝试寻找被重写的 getter/setter 方法
- (NSString *)unrecognizedSelectorTip:(id)instance
{
    if (object_isClass(instance)) {
        return @"";
    }
    NSString *currentName = self.selectorName;
    // 如果是 setter 方法，去掉之前逻辑添加的 set 前缀
    if (self.isAssignedValue && [currentName hasPrefix:@"set"] && [currentName hasSuffix:@":"]) {
        currentName = [currentName substringWithRange:NSMakeRange(3, currentName.length - 4)];
        currentName = [[currentName substringToIndex:1].lowercaseString stringByAppendingString:[currentName substringFromIndex:1]];
    }
    NSMutableString *tip = [NSMutableString stringWithFormat:@"%@ Unrecognized selector '%@'", instance, currentName];
    Class clazz = [instance class];

    // 1、先尝试通过 class_copyPropertyList 查找属性的 getter/setter 方法，如
    // @property(nonatomic, assign, getter=customGetterTest, setter=customSetterTest:) BOOL test;
    objc_property_t property = class_getProperty(clazz, currentName.UTF8String);
    if (property) {
        NSString *foundName = [NSString stringWithUTF8String:property_copyAttributeValue(property, self.isAssignedValue ? "S" : "G")];
        if (foundName.length && [instance respondsToSelector:NSSelectorFromString(foundName)]) {
            [tip appendFormat:@"，but found %@ method '%@', please check if you need to call this method", self.isAssignedValue ? @"setter" : @"getter", foundName];
            return tip;
        }
    }

    // 2、未找到则尝试手动拼接 getter/setter 方法名并从 class_copyMethodList 查找，如
    // @interface UIView(UIViewRendering)
    // @property(nonatomic,getter=isHidden) BOOL hidden;
    //
    currentName = [NSString stringWithFormat:@"%@%@%@", self.isAssignedValue ? @"set" : @"is", [[currentName substringToIndex:1] uppercaseString], [currentName substringFromIndex:1]];
    Class methodClass = clazz.mutableCopy;
//    class_getInstanceMethod(<#Class  ___unsafe_unretained cls#>, <#SEL  _Nonnull name#>)
    while (methodClass && methodClass != NSObject.class) {
        unsigned int methodCount;
        Method *methods = class_copyMethodList(methodClass, &methodCount);
        for (int i = 0; i < methodCount; i++) {
            Method method = methods[i];
            SEL sel = method_getName(method);
            NSString *methodName = NSStringFromSelector(sel);
            if ([methodName isEqualToString:currentName]) {
                if ([instance respondsToSelector:sel]) {
                    [tip appendFormat:@"，but found %@ method '%@', please check if you need to call this method", self.isAssignedValue ? @"setter" : @"getter", currentName];
                    free(methods);
                    return tip;
                }
            }
        }
        free(methods);
        methodClass = class_getSuperclass(methodClass);
    }

    return tip;
}
#endif
@end

MFValue * evalORCFuncCall(ORCFuncCall *node, MFScopeChain * scope) {
    NSMutableArray *args = [NSMutableArray array];
    for (ORValueExpression *exp in node.expressions){
        MFValue *value = evalORNode(exp, scope);
        NSCAssert(value != nil, @"value must be existed");
        [args addObject:value];
    }
    if ([node.caller isKindOfClass:[ORMethodCall class]]
        && [(ORMethodCall *)node.caller methodOperator] == MethodOpretorDot){
        // TODO: 调用block
        // make.left.equalTo(xxxx);
        MFValue *value = evalORNode((ORMethodCall *)node.caller, scope);
        return invoke_MFBlockValue(value, args);
    }
    //TODO: 递归函数优化, 优先查找全局函数
    id functionImp = [[ORGlobalFunctionTable shared] getFunctionNodeWithName:node.caller.value];
    if ([functionImp isKindOfClass:[ORFunctionImp class]]){
        // global function calll
        MFValue *result = nil;
        [ORArgsStack push:args];
        result = evalORNode((ORFunctionImp *)functionImp, scope);
        return result;
    }else if([functionImp isKindOfClass:[ORSearchedFunction class]]) {
        // 调用系统函数
        MFValue *result = nil;
        [ORArgsStack push:args];
        result = [(ORSearchedFunction *)functionImp execute:scope];
        return result;
    }else{
        MFValue *blockValue = [scope recursiveGetValueWithIdentifier:node.caller.value];
        //调用block
        if (blockValue.isBlockValue) {
            return invoke_MFBlockValue(blockValue, args);
        //调用函数指针 int (*xxx)(int a ) = &x;  xxxx();
        }else if (blockValue.funPair) {
            ORSearchedFunction *function = [ORSearchedFunction functionWithName:blockValue.funPair.var.varname];
            while (blockValue.pointerCount > 1) {
                blockValue.pointerCount--;
            }
            function.funPair = blockValue.funPair;
            function.pointer = blockValue->realBaseValue.pointerValue;
            [ORArgsStack push:args];
            return [function execute:scope];
        } else {
#if DEBUG
            NSLog(@"\
\n---------OCRunner Error---------\n\
*Unknown C function: '%@'*\n\
%@\n\
You need to add the missing C function in OCRunner scripts.\n\
For example:\n\
If it is 'UIEdgeInsetsMake', then add the following function:\n\
```\n\
UIEdgeInsets UIEdgeInsetsMake(CGFloat top, CGFloat left, CGFloat bottom, CGFloat right) {\n\
    UIEdgeInsets insets;\n\
    insets.top = top;\n\
    insets.left = left;\n\
    insets.bottom = bottom;\n\
    insets.right = right;\n\
    return insets;\n\
}\n\
```\n\
If it is 'UIInterfaceOrientationIsLandscape', then add this function:\n\
```\n\
BOOL UIInterfaceOrientationIsLandscape(UIInterfaceOrientation orientation) {\n\
    return ((orientation) == UIInterfaceOrientationLandscapeLeft || (orientation) == UIInterfaceOrientationLandscapeRight);\n\
}\n\
```\n\
-----------------------------------", node.caller.value, [ORCallFrameStack history]);
//            NSAssert(false, @"As mentioned above");
#endif

        }
    }
    return [MFValue valueWithObject:nil];
}


MFValue * evalORScopeImp (ORScopeImp  *node, MFScopeChain * scope) {
    //{ }
    for (ORNode *statement in node.statements) {
        MFValue *result = evalORNode(statement, scope);
        if (!result.isNormal) {
            return result;
        }
    }
    return [MFValue normalEnd];
}

 MFValue * evalORFunctionImp (ORFunctionImp  *node, MFScopeChain * scope) {
    // C函数声明执行, 向全局作用域注册函数
    if ([ORArgsStack isEmpty]
        && node.declare.funVar.varname
        && node.declare.funVar.ptCount == 0) {
        NSString *funcName = node.declare.funVar.varname;
        // NOTE: 恢复后，再执行时，应该覆盖旧的实现
        [[ORGlobalFunctionTable shared] setFunctionNode:node WithName:funcName];
        return [MFValue normalEnd];
    }
    MFScopeChain *current = [MFScopeChain scopeChainWithNext:scope];
    if (node.declare) {
        if(node.declare.isBlockDeclare){
            // xxx = ^void (int x){ }, block作为值
            MFBlock *manBlock = [[MFBlock alloc] init];
            manBlock.func = [node convertToNormalFunctionImp];
            MFScopeChain *blockScope = [MFScopeChain scopeChainWithNext:[MFScopeChain topScope]];
            copy_undef_var(node, [MFVarDeclareChain new], scope, blockScope);
            manBlock.outScope = blockScope;
            manBlock.retType = manBlock.func.declare.returnType;
            manBlock.paramTypes = manBlock.func.declare.funVar.pairs;
            __autoreleasing id ocBlock = [manBlock ocBlock];
            MFValue *value = [MFValue valueWithBlock:ocBlock];
            value.resultType = MFStatementResultTypeNormal;
            CFRelease((__bridge void *)ocBlock);
            return value;
        }else{
            evalORNode(node.declare, current);
        }
    }
    [ORCallFrameStack pushFunctionCall:node scope:current];
    MFValue *value = evalORNode(node.scopeImp, current);
    value.resultType = MFStatementResultTypeNormal;
    [ORCallFrameStack pop];
    return value;
}

MFValue * evalORSubscriptExpression(ORSubscriptExpression *node, MFScopeChain * scope) {
    MFValue *bottomValue = evalORNode(node.keyExp, scope);
    MFValue *arrValue = evalORNode(node.caller, scope);
    return [arrValue subscriptGetWithIndex:bottomValue];
}

MFValue * evalORAssignExpression (ORAssignExpression  *node, MFScopeChain * scope) {
    ORNode *resultExp;
#define SetResultExpWithBinaryOperator(type)\
    ORBinaryExpression *exp = [ORBinaryExpression new];\
    exp.nodeType = AstEnumBinaryExpression;\
    exp.left = node.value;\
    exp.right = node.expression;\
    exp.operatorType = type;\
    resultExp = exp;
    switch (node.assignType) {
        case AssignOperatorAssign:
            resultExp = node.expression;
            break;
        case AssignOperatorAssignAnd:{
            SetResultExpWithBinaryOperator(BinaryOperatorAnd);
            break;
        }
        case AssignOperatorAssignOr:{
            SetResultExpWithBinaryOperator(BinaryOperatorOr);
            break;
        }
        case AssignOperatorAssignXor:{
            SetResultExpWithBinaryOperator(BinaryOperatorXor);
            break;
        }
        case AssignOperatorAssignAdd:{
            SetResultExpWithBinaryOperator(BinaryOperatorAdd);
            break;
        }
        case AssignOperatorAssignSub:{
            SetResultExpWithBinaryOperator(BinaryOperatorSub);
            break;
        }
        case AssignOperatorAssignDiv:{
            SetResultExpWithBinaryOperator(BinaryOperatorDiv);
            break;
        }
        case AssignOperatorAssignMuti:{
            SetResultExpWithBinaryOperator(BinaryOperatorMulti);
            break;
        }
        case AssignOperatorAssignMod:{
            SetResultExpWithBinaryOperator(BinaryOperatorMod);
            break;
        }
        case AssignOperatorAssignShiftLeft:{
            SetResultExpWithBinaryOperator(BinaryOperatorShiftLeft);
            break;
        }
        case AssignOperatorAssignShiftRight:{
            SetResultExpWithBinaryOperator(BinaryOperatorShiftRight);
            break;
        }
        default:
            break;
    }
    switch (node.value.nodeType) {
        case AstEnumUnaryExpression:
        {
            MFValue *left = evalORNode(node.value, scope);
            MFValue *right = evalORNode(resultExp, scope);
            [right writePointer:left.pointer typeEncode:left.typeEncode];
            break;
        }
        case AstEnumValueExpression:
        {
            ORValueExpression *valueExp = (ORValueExpression *)node.value;
            MFValue *resultValue = evalORNode(resultExp, scope);
            switch (valueExp.value_type) {
                case OCValueSelf:{
                    scope.instance = resultValue;
                    break;
                }
                case OCValueVariable:{
                    [scope assignWithIdentifer:(NSString *)valueExp.value value:resultValue];
                    break;
                }
                default:
                    break;
            }
            break;
        }
        case AstEnumMethodCall:
        {
            ORMethodCall *methodCall = (ORMethodCall *)node.value;
            if (!methodCall.methodOperator) {
                NSCAssert(0, @"must dot grammar");
            }
            //调用对象setter方法
            NSString *setterName = methodCall.names.firstObject;
            NSString *first = [[setterName substringToIndex:1] uppercaseString];
            NSString *other = setterName.length > 1 ? [setterName substringFromIndex:1] : @"";
            setterName = [NSString stringWithFormat:@"set%@%@",first,other];
            ORMethodCall *setCaller = [ORMethodCall new];
            setCaller.nodeType = AstEnumMethodCall;
            setCaller.caller = [(ORMethodCall *)node.value caller];
            setCaller.names = [@[setterName] mutableCopy];
            setCaller.values = [@[resultExp] mutableCopy];
            setCaller.isAssignedValue = YES;
            evalORNode(setCaller, scope);
            break;
        }
        case AstEnumSubscriptExpression:
        {
            MFValue *resultValue = evalORNode(resultExp, scope);
            ORSubscriptExpression *subExp = (ORSubscriptExpression *)node.value;
            MFValue *caller = evalORNode(subExp.caller, scope);
            MFValue *indexValue = evalORNode(subExp.keyExp, scope);
            [caller subscriptSetValue:resultValue index:indexValue];
        }
        default:
            break;
    }
    return [MFValue normalEnd];
}

MFValue * evalORDeclareExpression (ORDeclareExpression  *node, MFScopeChain * scope) {
    BOOL staticVar = node.modifier & DeclarationModifierStatic;
    if ([node.pair.var isKindOfClass:[ORCArrayVariable class]]) {
        evalORNode(node.pair.var, scope);
    }
    MFValue *(^initializeBlock)(void) = ^MFValue *{
        if (node.expression) {
            MFValue *value = [evalORNode(node.expression, scope) copy];
            value.modifier = node.modifier;
            value.typeName = node.pair.type.name;
            value.typeEncode = node.pair.typeEncode;
            if ([node.pair.var isKindOfClass:[ORFuncVariable class]]&& [(ORFuncVariable *)node.pair.var isBlock] == NO)
                value.funPair = node.pair;
            [scope setValue:value withIndentifier:node.pair.var.varname];
            return value;
        }else{
            MFValue *value = [MFValue defaultValueWithTypeEncoding:node.pair.typeEncode];
            value.modifier = node.modifier;
            value.typeName = node.pair.type.name;
            value.typeEncode = node.pair.typeEncode;
            [value setDefaultValue];
            if (value.type == OCTypeObject
                && NSClassFromString(value.typeName) == nil
                && ![value.typeName isEqualToString:@"id"]) {
                NSString *reason = [NSString stringWithFormat:@"Unknown Type Identifier: %@",value.typeName];
                @throw [NSException exceptionWithName:@"OCRunner" reason:reason userInfo:nil];
            }
            
            if ([node.pair.var isKindOfClass:[ORFuncVariable class]]&& [(ORFuncVariable *)node.pair.var isBlock] == NO)
                value.funPair = node.pair;
            
            [scope setValue:value withIndentifier:node.pair.var.varname];
            return value;
        }
    };
    if (staticVar) {
        NSString *key = [NSString stringWithFormat:@"%p",(void *)node];
        MFValue *value = [[MFStaticVarTable shareInstance] getStaticVarValueWithKey:key];
        if (value) {
            [scope setValue:value withIndentifier:node.pair.var.varname];
        }else{
            MFValue *value = initializeBlock();
            [[MFStaticVarTable shareInstance] setStaticVarValue:value withKey:key];
        }
    }else{
        initializeBlock();
    }
    return [MFValue normalEnd];
}
MFValue * evalORUnaryExpression (ORUnaryExpression  *node, MFScopeChain * scope) {
    MFValue *currentValue = evalORNode(node.value, scope);
    START_BOX;
    cal_result.typeEncode = currentValue.typeEncode;
    switch (node.operatorType) {
        case UnaryOperatorIncrementSuffix:{
            SuffixUnaryExecuteInt(++, currentValue);
            SuffixUnaryExecuteFloat(++, currentValue);
            break;
        }
        case UnaryOperatorDecrementSuffix:{
            SuffixUnaryExecuteInt(--, currentValue);
            SuffixUnaryExecuteFloat(--, currentValue);
            break;
        }
        case UnaryOperatorIncrementPrefix:{
            PrefixUnaryExecuteInt(++, currentValue);
            PrefixUnaryExecuteFloat(++, currentValue);
            break;
        }
        case UnaryOperatorDecrementPrefix:{
            PrefixUnaryExecuteInt(--, currentValue);
            PrefixUnaryExecuteFloat(--, currentValue);
            break;
        }
        case UnaryOperatorNot:{
            cal_result.box.boolValue = !currentValue.isSubtantial;
            cal_result.typeEncode = OCTypeStringBOOL;
            break;
        }
        case UnaryOperatorSizeOf:{
            size_t result = 0;
            UnaryExecute(result, sizeof, currentValue);
            cal_result.box.longlongValue = result;
            cal_result.typeEncode = OCTypeStringLongLong;
            break;
        }
        case UnaryOperatorBiteNot:{
            PrefixUnaryExecuteInt(~, currentValue);
            break;
        }
        case UnaryOperatorNegative:{
            PrefixUnaryExecuteInt(-, currentValue);
            PrefixUnaryExecuteFloat(-, currentValue);;
            break;
        }
        case UnaryOperatorAdressPoint:{
            MFValue *resultValue = [MFValue defaultValueWithTypeEncoding:currentValue.typeEncode];
            void *pointer = currentValue.pointer;
            if ([currentValue isObject]) {
                pointer = currentValue.weakPointer;
            }
            resultValue.pointerCount += 1;
            resultValue.pointer = &pointer;
            return resultValue;
        }
        case UnaryOperatorAdressValue:{
            MFValue *resultValue = [MFValue defaultValueWithTypeEncoding:currentValue.typeEncode];
            resultValue.pointerCount -= 1;
            if (node.parentNode.nodeType == AstEnumAssignExpression) {
                [resultValue setValuePointerWithNoCopy:*(void **)currentValue.pointer];
            }else{
                resultValue.pointer = *(void **)currentValue.pointer;
            }
            return resultValue;
        }
        default:
            break;
    }
    return [MFValue valueWithORCaculateValue:cal_result];
}


MFValue * evalORBinaryExpression(ORBinaryExpression *node, MFScopeChain * scope) {
    switch (node.operatorType) {
        case BinaryOperatorLOGIC_AND:{
            MFValue *leftValue = evalORNode(node.left, scope);
            if (leftValue.isSubtantial) {
                MFValue *rightValue = evalORNode(node.right, scope);
                return [MFValue valueWithBOOL:rightValue.isSubtantial];
            }
            return [MFValue valueWithBOOL:NO];
            break;
        }
        case BinaryOperatorLOGIC_OR:{
            MFValue *leftValue = evalORNode(node.left, scope);
            if (leftValue.isSubtantial) {
                return [MFValue valueWithBOOL:YES];
            }
            MFValue *rightValue = evalORNode(node.right, scope);
            return [MFValue valueWithBOOL:rightValue.isSubtantial];
            break;
        }
        default: break;
    }
    MFValue *rightValue = evalORNode(node.right, scope);
    MFValue *leftValue = evalORNode(node.left, scope);
    START_BOX;
    cal_result.typeEncode = leftValue.typeEncode;
    switch (node.operatorType) {
        case BinaryOperatorAdd:{
            CalculateExecute(leftValue, +, rightValue);
            break;
        }
        case BinaryOperatorSub:{
            CalculateExecute(leftValue, -, rightValue);
            break;
        }
        case BinaryOperatorDiv:{
            CalculateExecute(leftValue, /, rightValue);
            break;
        }
        case BinaryOperatorMulti:{
            CalculateExecute(leftValue, *, rightValue);
            break;
        }
        case BinaryOperatorMod:{
            BinaryExecuteInt(leftValue, %, rightValue);
            break;
        }
        case BinaryOperatorShiftLeft:{
            BinaryExecuteInt(leftValue, <<, rightValue);
            break;
        }
        case BinaryOperatorShiftRight:{
            BinaryExecuteInt(leftValue, >>, rightValue);
            break;
        }
        case BinaryOperatorAnd:{
            BinaryExecuteInt(leftValue, &, rightValue);
            break;
        }
        case BinaryOperatorOr:{
            BinaryExecuteInt(leftValue, |, rightValue);
            break;
        }
        case BinaryOperatorXor:{
            BinaryExecuteInt(leftValue, ^, rightValue);
            break;
        }
        case BinaryOperatorLT:{
            LogicBinaryOperatorExecute(leftValue, <, rightValue);
            cal_result.box.boolValue = logicResultValue;
            cal_result.typeEncode = OCTypeStringBOOL;
            break;
        }
        case BinaryOperatorGT:{
            LogicBinaryOperatorExecute(leftValue, >, rightValue);
            cal_result.box.boolValue = logicResultValue;
            cal_result.typeEncode = OCTypeStringBOOL;
            break;
        }
        case BinaryOperatorLE:{
            LogicBinaryOperatorExecute(leftValue, <=, rightValue);
            cal_result.box.boolValue = logicResultValue;
            cal_result.typeEncode = OCTypeStringBOOL;
            break;
        }
        case BinaryOperatorGE:{
            LogicBinaryOperatorExecute(leftValue, >=, rightValue);
            cal_result.box.boolValue = logicResultValue;
            cal_result.typeEncode = OCTypeStringBOOL;
            break;
        }
        case BinaryOperatorNotEqual:{
            LogicBinaryOperatorExecute(leftValue, !=, rightValue);
            cal_result.box.boolValue = logicResultValue;
            cal_result.typeEncode = OCTypeStringBOOL;
            break;
        }
        case BinaryOperatorEqual:{
            LogicBinaryOperatorExecute(leftValue, ==, rightValue);
            cal_result.box.boolValue = logicResultValue;
            cal_result.typeEncode = OCTypeStringBOOL;
            break;
        }
        default:
            break;
    }
    return [MFValue valueWithORCaculateValue:cal_result];
}

MFValue * evalORTernaryExpression(ORTernaryExpression *node, MFScopeChain * scope) {
    MFValue *condition = evalORNode(node.expression, scope);
    if (node.values.count == 1) { // condition ?: value
        if (condition.isSubtantial) {
            return condition;
        }else{
            return evalORNode(node.values.lastObject, scope);
        }
    }else{ // condition ? value1 : value2
        if (condition.isSubtantial) {
            return evalORNode(node.values.firstObject, scope);
        }else{
            return evalORNode(node.values.lastObject, scope);
        }
    }
}

MFValue * evalORIfStatement (ORIfStatement  *node, MFScopeChain * scope) {
    NSMutableArray *statements = [NSMutableArray array];
    ORIfStatement *ifStatement = node;
    while (ifStatement) {
        [statements insertObject:ifStatement atIndex:0];
        ifStatement = ifStatement.last;
    }
    for (ORIfStatement *statement in statements) {
        MFValue *conditionValue = evalORNode(statement.condition, scope);
        if (conditionValue.isSubtantial) {
            MFScopeChain *current = [MFScopeChain scopeChainWithNext:scope];
            return evalORNode(statement.scopeImp, current);
        }
    }
    if (node.condition == nil) {
        MFScopeChain *current = [MFScopeChain scopeChainWithNext:scope];
        return evalORNode(node.scopeImp, current);
    }
    return [MFValue normalEnd];
}
MFValue * evalORWhileStatement (ORWhileStatement  *node, MFScopeChain * scope) {
    MFScopeChain *current = [MFScopeChain scopeChainWithNext:scope];
    while (1) {
        if (!evalORNode(node.condition, scope).isSubtantial) {
            break;
        }
        MFValue *resultValue = evalORNode(node.scopeImp, current);
        if (resultValue.isBreak) {
            resultValue.resultType = MFStatementResultTypeNormal;
            break;
        }else if (resultValue.isContinue){
            resultValue.resultType = MFStatementResultTypeNormal;
        }else if (resultValue.isReturn){
            return resultValue;
        }else if (resultValue.isNormal){
            
        }
    }
    return [MFValue normalEnd];
}

MFValue * evalORDoWhileStatement (ORDoWhileStatement  *node, MFScopeChain * scope) {
    MFScopeChain *current = [MFScopeChain scopeChainWithNext:scope];
    while (1) {
        MFValue *resultValue = evalORNode(node.scopeImp, current);
        if (resultValue.isBreak) {
            resultValue.resultType = MFStatementResultTypeNormal;
            break;
        }else if (resultValue.isContinue){
            resultValue.resultType = MFStatementResultTypeNormal;
        }else if (resultValue.isReturn){
            return resultValue;
        }else if (resultValue.isNormal){
            
        }
        if (!evalORNode(node.condition, scope).isSubtantial) {
            break;
        }
    }
    return [MFValue normalEnd];
}

MFValue * evalORCaseStatement (ORCaseStatement  *node, MFScopeChain * scope) {
    MFScopeChain *current = [MFScopeChain scopeChainWithNext:scope];
    return evalORNode(node.scopeImp, current);
}


MFValue * evalORSwitchStatement (ORSwitchStatement  *node, MFScopeChain * scope) {
    MFValue *value = evalORNode(node.value, scope);
    BOOL matched = NO;
    for (ORCaseStatement *statement in node.cases) {
        MFValue *result = nil;
        if (statement.value && !matched) {
            MFValue *caseValue = evalORNode(statement.value, scope);
            LogicBinaryOperatorExecute(value, ==, caseValue);
            matched = logicResultValue;
            if (!matched) {
                continue;
            }
        }
        result = evalORNode(statement, scope);
        if (result.isBreak) {
            result.resultType = MFStatementResultTypeNormal;
            return result;
        } else if (result.isNormal) {
            continue;
        } else {
            return result;
        }
    }
    return [MFValue normalEnd];
}


MFValue * evalORForStatement (ORForStatement  *node, MFScopeChain * scope) {
    MFScopeChain *current = [MFScopeChain scopeChainWithNext:scope];
    for (ORNode *exp in node.varExpressions) {
        evalORNode(exp, current);
    }
    while (1) {
        if (!evalORNode(node.condition, current).isSubtantial) {
            break;
        }
        MFValue *result = evalORNode(node.scopeImp, current);
        if (result.isReturn) {
            return result;
        }else if (result.isBreak){
            result.resultType = MFStatementResultTypeNormal;
            return result;
        }else if (result.isContinue){

        }
        for (ORNode *exp in node.expressions) {
            evalORNode(exp, (MFScopeChain *)current);
        }
    }
    return [MFValue normalEnd];
}
MFValue * evalORForInStatement (ORForInStatement  *node, MFScopeChain * scope) {
    MFScopeChain *current = [MFScopeChain scopeChainWithNext:scope];
    MFValue *arrayValue = evalORNode(node.value, current);
    for (id element in arrayValue.objectValue) {
        //TODO: 每执行一次，在作用域中重新设置一次
        [current setValue:[MFValue valueWithObject:element] withIndentifier:node.expression.pair.var.varname];
        MFValue *result = evalORNode(node.scopeImp, current);
        if (result.isBreak) {
            result.resultType = MFStatementResultTypeNormal;
            return result;
        }else if(result.isContinue){
            continue;
        }else if (result.isReturn){
            return result;
        }
    }
    return [MFValue normalEnd];
}

MFValue * evalORReturnStatement (ORReturnStatement  *node, MFScopeChain * scope) {
    if (node.expression) {
        MFValue *value = evalORNode(node.expression, scope);
        value.resultType = MFStatementResultTypeReturnValue;
        return value;
    }else{
        MFValue *value = [MFValue voidValue];
        value.resultType = MFStatementResultTypeReturnEmpty;
        return value;
    }
}

MFValue * evalORBreakStatement (ORBreakStatement  *node, MFScopeChain * scope) {
    MFValue *value = [MFValue voidValue];
    value.resultType = MFStatementResultTypeBreak;
    return value;
}

MFValue * evalORContinueStatement (ORContinueStatement  *node, MFScopeChain * scope) {
    MFValue *value = [MFValue voidValue];
    value.resultType = MFStatementResultTypeContinue;
    return value;
}

MFValue * evalORPropertyDeclare(ORPropertyDeclare *node, MFScopeChain * scope) {
    NSString *propertyName = node.var.var.varname;
    MFValue *classValue = [scope recursiveGetValueWithIdentifier:@"Class"];
    Class clazz = *(Class *)classValue.pointer;
    MFPropertyMapTableItem *propItem = [[MFPropertyMapTableItem alloc] initWithClass:clazz property:node];
    [[MFPropertyMapTable shareInstance] addPropertyMapTableItem:propItem];
    // only support add new property when ivar is NULL
    if (class_getProperty(clazz, propertyName.UTF8String)
        && class_getInstanceVariable(clazz, [@"_" stringByAppendingString:propertyName].UTF8String)) {
        propItem.added = NO;
        return nil;
    }
    // for recover: RunnerClasses+Recover.m
    propItem.added = YES;
    class_addProperty(clazz, propertyName.UTF8String, node.propertyAttributes, 3);
    replace_getter_method(clazz, node);
    replace_setter_method(clazz, node);
    return nil;
}


@implementation ORPropertyDeclare(Execute)
- (const objc_property_attribute_t *)propertyAttributes{
    NSValue *value = objc_getAssociatedObject(self, mf_propKey(@"propertyAttributes"));
    objc_property_attribute_t *attributes = (objc_property_attribute_t *)[value pointerValue];
    if (attributes != NULL) {
        return attributes;
    }
    attributes = (objc_property_attribute_t *)malloc(sizeof(objc_property_attribute_t) * 3);
    attributes[0] = self.typeAttribute;
    attributes[1] = self.memeryAttribute;
    attributes[2] = self.atomicAttribute;
    objc_setAssociatedObject(self, "propertyAttributes", [NSValue valueWithPointer:attributes], OBJC_ASSOCIATION_ASSIGN);
    return attributes;
}
- (void)dealloc{
    NSValue *value = objc_getAssociatedObject(self, mf_propKey(@"propertyAttributes"));
    objc_property_attribute_t *attributes = (objc_property_attribute_t *)[value pointerValue];
    if (attributes != NULL) {
        free((void *)attributes->value);
        free(attributes);
    }
}
- (objc_property_attribute_t )typeAttribute{
    const char *typeencode = self.var.typeEncode;
    NSString *typeName = self.var.type.name;
    char buffer[256] = { 0 };
    if (*typeencode == OCTypeObject && NSClassFromString(typeName)) {
        snprintf(buffer, 256, "%s\"%s\"",typeencode,typeName.UTF8String);
    }else{
        snprintf(buffer, 256, "%s",typeencode);
    }
    objc_property_attribute_t type = {"T", strdup(buffer) };
    return type;
}
- (objc_property_attribute_t )memeryAttribute{
    objc_property_attribute_t memAttr = {"", ""};
    switch (self.modifier & MFPropertyModifierMemMask) {
        case MFPropertyModifierMemStrong:
            memAttr.name = "&";
            break;
        case MFPropertyModifierMemWeak:
            memAttr.name = "W";
            break;
        case MFPropertyModifierMemCopy:
            memAttr.name = "C";
            break;
        default:
            break;
    }
    return memAttr;
}
- (objc_property_attribute_t )atomicAttribute{
    objc_property_attribute_t atomicAttr = {"", ""};
    switch (self.modifier & MFPropertyModifierAtomicMask) {
        case MFPropertyModifierAtomic:
            break;
        case MFPropertyModifierNonatomic:
            atomicAttr.name = "N";
            break;
        default:
            break;
    }
    return atomicAttr;
}
@end

MFValue * evalORMethodDeclare(ORMethodDeclare *node, MFScopeChain * scope) {
    NSMutableArray * parameters = [ORArgsStack pop];
    [parameters enumerateObjectsUsingBlock:^(MFValue * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [scope setValue:obj withIndentifier:node.parameterNames[idx]];
    }];
    return nil;
}


MFValue * evalORMethodImplementation(ORMethodImplementation *node, MFScopeChain * scope) {
    MFScopeChain *current = [MFScopeChain scopeChainWithNext:scope];
    [ORCallFrameStack pushMethodCall:node instance:scope.instance];
    evalORNode(node.declare, current);
    MFValue *result = evalORNode(node.scopeImp, current);
    result.resultType = MFStatementResultTypeNormal;
    [ORCallFrameStack pop];
    return result;
}

#import <objc/runtime.h>

MFValue * evalORClass(ORClass *node, MFScopeChain * scope) {
    Class clazz = NSClassFromString(node.className);
    MFScopeChain *current = [MFScopeChain scopeChainWithNext:scope];
    if (!clazz) {
        Class superClass = NSClassFromString(node.superClassName);
        if (!superClass) {
            // 针对仅实现 @implementation xxxx  的类, 默认继承NSObjectt
            superClass = [NSObject class];
        }
        clazz = objc_allocateClassPair(superClass, node.className.UTF8String, 0);
        //添加协议
        for (NSString *name in node.protocols) {
            Protocol *protcol = NSProtocolFromString(name);
            if (protcol) {
                class_addProtocol(clazz, protcol);
            }
        }
        objc_registerClassPair(clazz);
        [[MFScopeChain topScope] setValue:[MFValue valueWithClass:clazz] withIndentifier:node.className];
    }
    // 添加Class变量到作用域
    [current setValue:[MFValue valueWithClass:clazz] withIndentifier:@"Class"];
    // 先添加属性
    for (ORPropertyDeclare *property in node.properties) {
        evalORNode(property, current);
    }
    // 在添加方法，这样可以解决属性的懒加载不生效的问题
    for (ORMethodImplementation *method in node.methods) {
        [method setClassNode:clazz];
        replace_method(clazz, method);
    }
    return nil;
}



MFValue * evalORStructExpressoin (ORStructExpressoin  *node, MFScopeChain * scope) {
    NSMutableString *typeEncode = [@"{" mutableCopy];
    NSMutableArray *keys = [NSMutableArray array];
    [typeEncode appendString:node.sturctName];
    [typeEncode appendString:@"="];
    for (ORDeclareExpression *exp in node.fields) {
        NSString *typeName = exp.pair.type.name;
        ORSymbolItem *item = [[ORTypeSymbolTable shareInstance] symbolItemForTypeName:typeName];
        [typeEncode appendFormat:@"%s",item ? item.typeEncode.UTF8String : exp.pair.typeEncode];
        [keys addObject:exp.pair.var.varname];
    }
    [typeEncode appendString:@"}"];
    // 类型表注册全局类型
    ORStructDeclare *declare = [ORStructDeclare structDecalre:typeEncode.UTF8String keys:keys];
    [[ORTypeSymbolTable shareInstance] addStruct:declare forAlias:node.sturctName];
    return [MFValue voidValue];
}


MFValue * evalOREnumExpressoin (OREnumExpressoin  *node, MFScopeChain * scope) {
    ORTypeSpecial *special = [ORTypeSpecial specialWithType:node.valueType name:node.enumName];
    ORTypeVarPair *pair = [[ORTypeVarPair alloc] init];
    pair.type = special;
    const char *typeEncode = pair.typeEncode;
    MFValue *lastValue = nil;
    // 注册全局变量
    for (id exp in node.fields) {
        if ([exp isKindOfClass:[ORAssignExpression class]]) {
            ORAssignExpression *assignExp = (ORAssignExpression *)exp;
            lastValue = evalORNode(assignExp.expression, scope);
            lastValue.typeEncode = typeEncode;
            [scope setValue:lastValue withIndentifier:[(ORValueExpression *)assignExp.value value]];
        }else if ([exp isKindOfClass:[ORValueExpression class]]){
            if (lastValue) {
                lastValue = [MFValue valueWithLongLong:lastValue.longlongValue + 1];
                lastValue.typeEncode = typeEncode;
                [scope setValue:lastValue withIndentifier:[(ORValueExpression *)exp value]];
            }else{
                lastValue = [MFValue valueWithLongLong:0];
                lastValue.typeEncode = typeEncode;
                [scope setValue:lastValue withIndentifier:[(ORValueExpression *)exp value]];
            }
        }else{
            NSCAssert(NO, @"must be ORAssignExpression and ORValueExpression");
        }
    }
    // 类型表注册全局类型
    if (node.enumName) {
        [[ORTypeSymbolTable shareInstance] addTypePair:pair forAlias:node.enumName];
    }
    return [MFValue voidValue];
}


MFValue * evalORTypedefExpressoin (ORTypedefExpressoin  *node, MFScopeChain * scope) {
    if ([node.expression isKindOfClass:[ORTypeVarPair class]]) {
        [[ORTypeSymbolTable shareInstance] addTypePair:(ORTypeVarPair *)node.expression forAlias:node.typeNewName];
    }else if ([node.expression isKindOfClass:[ORStructExpressoin class]]){
        ORStructExpressoin *structExp = (ORStructExpressoin *)node.expression;
        evalORNode(structExp, scope);
        ORSymbolItem *item = [[ORTypeSymbolTable shareInstance] symbolItemForTypeName:structExp.sturctName];
        [[ORTypeSymbolTable shareInstance] addSybolItem:item forAlias:node.typeNewName];
    }else if ([node.expression isKindOfClass:[OREnumExpressoin class]]){
        OREnumExpressoin *enumExp = (OREnumExpressoin *)node.expression;
        evalORNode(enumExp, scope);
        ORTypeSpecial *special = [ORTypeSpecial specialWithType:enumExp.valueType name:node.typeNewName];
        ORTypeVarPair *pair = [[ORTypeVarPair alloc] init];
        pair.type = special;
        [[ORTypeSymbolTable shareInstance] addTypePair:pair forAlias:node.typeNewName];
    }else if ([node.expression isKindOfClass:[ORUnionExpressoin class]]){
        ORUnionExpressoin *unionExp = (ORUnionExpressoin *)node.expression;
        evalORNode(unionExp, scope);
        ORSymbolItem *item = [[ORTypeSymbolTable shareInstance] symbolItemForTypeName:unionExp.unionName];
        [[ORTypeSymbolTable shareInstance] addSybolItem:item forAlias:node.typeNewName];
    }else{
        NSCAssert(NO, @"must be ORTypeVarPair, ORStructExpressoin,  OREnumExpressoin");
    }
    return [MFValue voidValue];
}



MFValue * evalORProtocol (ORProtocol  *node, MFScopeChain * scope) {
    if (NSProtocolFromString(node.protcolName) != nil) {
        return [MFValue voidValue];
    }
    Protocol *protocol = objc_allocateProtocol(node.protcolName.UTF8String);
    for (NSString *name in node.protocols) {
        Protocol *superP = NSProtocolFromString(name);
        protocol_addProtocol(protocol, superP);
    }
    for (ORPropertyDeclare *prop in node.properties) {
        protocol_addProperty(protocol, prop.var.var.varname.UTF8String, prop.propertyAttributes, 3, NO, YES);
    }
    for (ORMethodDeclare *declare in node.methods) {
        const char *typeEncoding = declare.returnType.typeEncode;
        typeEncoding = mf_str_append(typeEncoding, "@:"); //add node and _cmd
        for (ORTypeVarPair *pair in declare.parameterTypes) {
            const char *paramTypeEncoding = pair.typeEncode;
            const char *beforeTypeEncoding = typeEncoding;
            typeEncoding = mf_str_append(typeEncoding, paramTypeEncoding);
            free((void *)beforeTypeEncoding);
        }
        protocol_addMethodDescription(protocol, NSSelectorFromString(declare.selectorName), typeEncoding, NO, !declare.isClassMethod);
    }
    objc_registerProtocol(protocol);
    return [MFValue voidValue];
}


MFValue * evalORCArrayVariable (ORCArrayVariable  *node, MFScopeChain * scope) {
    MFValue *value = evalORNode(node.capacity, scope);
    if (![node.capacity isKindOfClass:[ORIntegerValue class]]
        && [node.capacity isKindOfClass:[ORCArrayVariable class]] == NO) {
        ORIntegerValue *integerValue = [ORIntegerValue new];
        integerValue.value = value.longlongValue;
        node.capacity = integerValue;
    }
    return [MFValue voidValue];
}


MFValue * evalORUnionExpressoin (ORUnionExpressoin  *node, MFScopeChain * scope) {
    NSMutableString *typeEncode = [@"(" mutableCopy];
    NSMutableArray *keys = [NSMutableArray array];
    [typeEncode appendString:node.unionName];
    [typeEncode appendString:@"="];
    for (ORDeclareExpression *exp in node.fields) {
        NSString *typeName = exp.pair.type.name;
        ORSymbolItem *item = [[ORTypeSymbolTable shareInstance] symbolItemForTypeName:typeName];
        [typeEncode appendFormat:@"%s",item ?  item.typeEncode.UTF8String : exp.pair.typeEncode];
        [keys addObject:exp.pair.var.varname];
    }
    [typeEncode appendString:@")"];
    // 类型表注册全局类型
    ORUnionDeclare *declare = [ORUnionDeclare unionDecalre:typeEncode.UTF8String keys:keys];;
    [[ORTypeSymbolTable shareInstance] addUnion:declare forAlias:node.unionName];
    return [MFValue voidValue];
}


MFValue *evalORNode(ORNode *node, MFScopeChain * scope) {
    if (node == NULL) return MFValue.nullValue;
    switch (node.nodeType) {
        case AstEnumFuncVariable: return evalORFuncVariable((ORFuncVariable *)node, scope);
        case AstEnumFuncDeclare: return evalORFuncDeclare((ORFuncDeclare *)node, scope);
        case AstEnumScopeImp: return evalORScopeImp((ORScopeImp *)node, scope);
        case AstEnumValueExpression: return evalORValueExpression((ORValueExpression *)node, scope);
        case AstEnumIntegerValue: return evalORIntegerValue((ORIntegerValue *)node, scope);
        case AstEnumUIntegerValue: return evalORUIntegerValue((ORUIntegerValue *)node, scope);
        case AstEnumDoubleValue: return evalORDoubleValue((ORDoubleValue *)node, scope);
        case AstEnumBoolValue: return evalORBoolValue((ORBoolValue *)node, scope);
        case AstEnumMethodCall: return evalORMethodCall((ORMethodCall *)node, scope);
        case AstEnumCFuncCall: return evalORCFuncCall((ORCFuncCall *)node, scope);
        case AstEnumFunctionImp: return evalORFunctionImp((ORFunctionImp *)node, scope);
        case AstEnumSubscriptExpression: return evalORSubscriptExpression((ORSubscriptExpression *)node, scope);
        case AstEnumAssignExpression: return evalORAssignExpression((ORAssignExpression *)node, scope);
        case AstEnumDeclareExpression: return evalORDeclareExpression((ORDeclareExpression *)node, scope);
        case AstEnumUnaryExpression: return evalORUnaryExpression((ORUnaryExpression *)node, scope);
        case AstEnumBinaryExpression: return evalORBinaryExpression((ORBinaryExpression *)node, scope);
        case AstEnumTernaryExpression: return evalORTernaryExpression((ORTernaryExpression *)node, scope);
        case AstEnumIfStatement: return evalORIfStatement((ORIfStatement *)node, scope);
        case AstEnumWhileStatement: return evalORWhileStatement((ORWhileStatement *)node, scope);
        case AstEnumDoWhileStatement: return evalORDoWhileStatement((ORDoWhileStatement *)node, scope);
        case AstEnumCaseStatement: return evalORCaseStatement((ORCaseStatement *)node, scope);
        case AstEnumSwitchStatement: return evalORSwitchStatement((ORSwitchStatement *)node, scope);
        case AstEnumForStatement: return evalORForStatement((ORForStatement *)node, scope);
        case AstEnumForInStatement: return evalORForInStatement((ORForInStatement *)node, scope);
        case AstEnumReturnStatement: return evalORReturnStatement((ORReturnStatement *)node, scope);
        case AstEnumBreakStatement: return evalORBreakStatement((ORBreakStatement *)node, scope);
        case AstEnumContinueStatement: return evalORContinueStatement((ORContinueStatement *)node, scope);
        case AstEnumPropertyDeclare: return evalORPropertyDeclare((ORPropertyDeclare *)node, scope);
        case AstEnumMethodDeclare: return evalORMethodDeclare((ORMethodDeclare *)node, scope);
        case AstEnumMethodImplementation: return evalORMethodImplementation((ORMethodImplementation *)node, scope);
        case AstEnumClass: return evalORClass((ORClass *)node, scope);
        case AstEnumProtocol: return evalORProtocol((ORProtocol *)node, scope);
        case AstEnumStructExpressoin: return evalORStructExpressoin((ORStructExpressoin *)node, scope);
        case AstEnumEnumExpressoin: return evalOREnumExpressoin((OREnumExpressoin *)node, scope);
        case AstEnumTypedefExpressoin: return evalORTypedefExpressoin((ORTypedefExpressoin *)node, scope);
        case AstEnumCArrayVariable: return evalORCArrayVariable((ORCArrayVariable *)node, scope);
        case AstEnumUnionExpressoin: return evalORUnionExpressoin((ORUnionExpressoin *)node, scope);
        default:
            break;
    }
    return MFValue.nullValue;
}
