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

static void *add_function(const char *funcReturnType, NSMutableArray <NSString *>*argTypes, void (*executeFunc)(ffi_cif*,void*,void**,void*), NSDictionary *userInfo){
    void *imp = NULL;
    ffi_cif *cif = malloc(sizeof(ffi_cif));//不可以free
    ffi_closure *closure = ffi_closure_alloc(sizeof(ffi_closure), (void **)&imp);
    ffi_type *returnType = mf_ffi_type_with_type_encoding(funcReturnType);
    ffi_type **args = malloc(sizeof(ffi_type *) * (unsigned int)argTypes.count);
    for (int  i = 0 ; i < argTypes.count; i++) {
        args[i] = mf_ffi_type_with_type_encoding(argTypes[i].UTF8String);
    }
    if(ffi_prep_cif(cif, FFI_DEFAULT_ABI, (unsigned int)argTypes.count, returnType, args) == FFI_OK)
    {
        CFTypeRef cfuserInfo = (__bridge_retained CFTypeRef)userInfo;
        ffi_prep_closure_loc(closure, cif, executeFunc, (void *)cfuserInfo, imp);
    }
    return imp;
}
static void methodIMP(ffi_cif *cif, void *ret, void **args, void *userdata){
    NSDictionary * userInfo = (__bridge id)userdata;// 不可以进行释放
    Class class  = userInfo[@"class"];
    NSString *typeEncoding = userInfo[@"typeEncoding"];
    MFScopeChain *scope = userInfo[@"scope"];
    id assignSlf = (__bridge  id)(*(void **)args[0]);
    [scope setValue:[MFValue valueInstanceWithObject:assignSlf] withIndentifier:@"self"];
    SEL sel = *(void **)args[1];
    BOOL classMethod = object_isClass(assignSlf);
    MFMethodMapTableItem *map = [[MFMethodMapTable shareInstance] getMethodMapTableItemWith:class classMethod:classMethod sel:sel];
    __autoreleasing MFValue *retValue = [map.methodImp execute:scope];
    NSMethodSignature *methodSignature = [NSMethodSignature signatureWithObjCTypes:typeEncoding.UTF8String];
    [retValue assignToCValuePointer:ret typeEncoding:[methodSignature methodReturnType]];
}


static void replace_method(Class clazz, ORMethodImplementation *methodImp, MFScopeChain *scope){
    ORMethodDeclare *declare = methodImp.declare;
    NSString *methodName = [declare.methodNames componentsJoinedByString:@":"];
    SEL sel = NSSelectorFromString(methodName);
    
    MFMethodMapTableItem *item = [[MFMethodMapTableItem alloc] initWithClass:clazz method:methodImp];
    [[MFMethodMapTable shareInstance] addMethodMapTableItem:item];
    
    BOOL needFreeTypeEncoding = NO;
    const char *typeEncoding;
    Method ocMethod;
    if (methodImp.declare.isClassMethod) {
        ocMethod = class_getClassMethod(clazz, sel);
    }else{
        ocMethod = class_getInstanceMethod(clazz, sel);
    }
    
    if (ocMethod) {
        typeEncoding = method_getTypeEncoding(ocMethod);
    }else{
        typeEncoding = OCTypeEncodingForPair(methodImp.declare.returnType);
        
        for (ORTypeVarPair *pair in methodImp.declare.parameterTypes) {
            const char *paramTypeEncoding = OCTypeEncodingForPair(pair);
            typeEncoding = mf_str_append(typeEncoding, paramTypeEncoding);
            needFreeTypeEncoding = YES;
        }
    }
    Class c2 = methodImp.declare.isClassMethod ? objc_getMetaClass(class_getName(clazz)) : clazz;
    if (class_respondsToSelector(c2, sel)) {
        NSString *orgSelName = [NSString stringWithFormat:@"ORG%@",methodName];
        SEL orgSel = NSSelectorFromString(orgSelName);
        if (!class_respondsToSelector(c2, orgSel)) {
            class_addMethod(c2, orgSel, method_getImplementation(ocMethod), typeEncoding);
        }
    }
    NSMethodSignature *sig = [NSMethodSignature signatureWithObjCTypes:typeEncoding];
    NSMutableArray *argTypes = [NSMutableArray array];
    for (int  i = 0 ; i < sig.numberOfArguments; i++) {
        [argTypes addObject:[NSString stringWithUTF8String:[sig getArgumentTypeAtIndex:i]]];
    }
    NSDictionary *userInfo = @{@"class":c2,@"typeEncoding":@(typeEncoding), @"scope":scope};
    void *imp = add_function(sig.methodReturnType, argTypes, methodIMP, userInfo);
    class_replaceMethod(c2, sel, imp, typeEncoding);
    if (needFreeTypeEncoding) {
        free((void *)typeEncoding);
    }
}
static void add_method(Class clazz, ORMethodImplementation *methodImp, MFScopeChain *scope){
    ORMethodDeclare *declare = methodImp.declare;
    NSString *methodName = [declare.methodNames componentsJoinedByString:@":"];
    SEL sel = NSSelectorFromString(methodName);
    
    MFMethodMapTableItem *item = [[MFMethodMapTableItem alloc] initWithClass:clazz method:methodImp];
    [[MFMethodMapTable shareInstance] addMethodMapTableItem:item];
    
    BOOL needFreeTypeEncoding = NO;
    const char *typeEncoding;
    Method ocMethod;
    if (methodImp.declare.isClassMethod) {
        ocMethod = class_getClassMethod(clazz, sel);
    }else{
        ocMethod = class_getInstanceMethod(clazz, sel);
    }
    
    if (ocMethod) {
        typeEncoding = method_getTypeEncoding(ocMethod);
    }else{
        typeEncoding = OCTypeEncodingForPair(methodImp.declare.returnType);
        
        for (ORTypeVarPair *pair in methodImp.declare.parameterTypes) {
            const char *paramTypeEncoding = OCTypeEncodingForPair(pair);
            typeEncoding = mf_str_append(typeEncoding, paramTypeEncoding);
            needFreeTypeEncoding = YES;
        }
    }
    Class c2 = methodImp.declare.isClassMethod ? objc_getMetaClass(class_getName(clazz)) : clazz;
    NSMethodSignature *sig = [NSMethodSignature signatureWithObjCTypes:typeEncoding];
    NSMutableArray *argTypes = [NSMutableArray array];
    for (int  i = 0 ; i < sig.numberOfArguments; i++) {
        [argTypes addObject:[NSString stringWithUTF8String:[sig getArgumentTypeAtIndex:i]]];
    }
    NSDictionary *userInfo = @{@"class":c2,@"typeEncoding":@(typeEncoding), @"scope":scope};
    void *imp = add_function(sig.methodReturnType, argTypes, methodIMP, userInfo);
    class_addMethod(c2, sel, imp, typeEncoding);
    if (needFreeTypeEncoding) {
        free((void *)typeEncoding);
    }
}
id registerClassGetter(id self1, SEL _cmd1) {
    NSString *key = NSStringFromSelector(_cmd1);
    Ivar ivar = class_getInstanceVariable([self1 class], strcat("_", key.UTF8String));
    return object_getIvar(self1, ivar);
}
void registerClassSetter(id self1, SEL _cmd1, id newValue) { //移除set
    NSString *key = NSStringFromSelector(_cmd1);
    key = [key substringWithRange:NSMakeRange(3, key.length - 4)]; // setXxxx: -> Xxxx
    NSString *head = [[key substringWithRange:NSMakeRange(0, 1)] lowercaseString];
    key = [key stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:head]; // 替换大写首字母
    Ivar ivar = class_getInstanceVariable([self1 class], strcat("_", key.UTF8String)); //basicsViewController里面有个_dictCustomerProperty属性
    object_setIvar(self1, ivar, newValue);
}
void copy_undef_var(id exprOrStatement, MFVarDeclareChain *chain, MFScopeChain *fromScope, MFScopeChain *destScope);
void copy_undef_vars(NSArray *exprOrStatements, MFVarDeclareChain *chain, MFScopeChain *fromScope, MFScopeChain *destScope){
    for (id exprOrStatement in exprOrStatements) {
        copy_undef_var(exprOrStatement, chain, fromScope, destScope);
    }
}
/// Block执行时的外部变量捕获
void copy_undef_var(id exprOrStatement, MFVarDeclareChain *chain, MFScopeChain *fromScope, MFScopeChain *destScope){
    if (!exprOrStatement) {
        return;
    }
    Class exprOrStatementClass = [exprOrStatement class];
    if (exprOrStatementClass == [ORValueExpression class]) {
        ORValueExpression *expr = (ORValueExpression *)exprOrStatement;
        switch (expr.value_type) {
            case OCValueDictionary:{
                for (NSArray *kv in expr.value) {
                    ORExpression *keyExp = kv.firstObject;
                    ORExpression *valueExp = kv.firstObject;
                    copy_undef_var(keyExp, chain, fromScope, destScope);
                    copy_undef_var(valueExp, chain, fromScope, destScope);
                }
                break;
            }
            case OCValueArray:{
                for (ORExpression *valueExp in expr.value) {
                    copy_undef_var(valueExp, chain, fromScope, destScope);
                }
                break;
            }
            case OCValueSelf:
            case OCValueSuper:{
                NSString *identifier = @"self";
                if (![chain isInChain:identifier]) {
                    MFValue *value = [fromScope getValueWithIdentifier:identifier endScope:[MFScopeChain topScope]];
                    if (value) {
                        [destScope setValue:value withIndentifier:identifier];
                    }
                }
                break;
            }
            case OCValueVariable:{
                NSString *identifier = expr.value;
                if (![chain isInChain:identifier]) {
                   MFValue *value = [fromScope getValueWithIdentifier:identifier endScope:[MFScopeChain topScope]];
                    if (value) {
                        [destScope setValue:value withIndentifier:identifier];
                    }
                }
            }
            default:
                break;
        }
    }else if (exprOrStatementClass == ORAssignExpression.class) {
        ORAssignExpression *expr = (ORAssignExpression *)exprOrStatement;
        copy_undef_var(expr.value, chain, fromScope, destScope);
        copy_undef_var(expr.expression, chain, fromScope, destScope);
        return;
    }else if (exprOrStatementClass == ORBinaryExpression.class){
        ORBinaryExpression *expr = (ORBinaryExpression *)exprOrStatement;
        copy_undef_var(expr.left, chain, fromScope, destScope);
        copy_undef_var(expr.right, chain, fromScope, destScope);
        return;
    }else if (exprOrStatementClass == ORTernaryExpression.class){
        ORTernaryExpression *expr = (ORTernaryExpression *)exprOrStatement;
        copy_undef_var(expr.expression, chain, fromScope, destScope);
        copy_undef_vars(expr.values, chain, fromScope, destScope);
        return;
    }else if (exprOrStatementClass == ORUnaryExpression.class){
        ORUnaryExpression *expr = (ORUnaryExpression *)exprOrStatement;
        copy_undef_var(expr.value, chain, fromScope, destScope);
        return;
    }else if (exprOrStatementClass == ORCFuncCall.class){
        ORCFuncCall *expr = (ORCFuncCall *)exprOrStatement;
        copy_undef_var(expr.caller, chain, fromScope, destScope);
        copy_undef_vars(expr.expressions, chain, fromScope, destScope);
        return;
    }else if (exprOrStatementClass == ORSubscriptExpression.class){
        ORSubscriptExpression *expr = (ORSubscriptExpression *)exprOrStatement;
        copy_undef_var(expr.caller, chain, fromScope, destScope);
        copy_undef_var(expr.keyExp, chain, fromScope, destScope);
        return;
    }else if (exprOrStatementClass == ORBlockImp.class){
        ORBlockImp *expr = (ORBlockImp *)exprOrStatement;
        ORFuncDeclare *funcDeclare = expr.declare;
        MFVarDeclareChain *funcChain = [MFVarDeclareChain varDeclareChainWithNext:chain];
        NSArray <ORTypeVarPair *>*params = funcDeclare.var.pairs;
        for (ORTypeVarPair *param in params) {
            [funcChain addIndentifer:param.var.varname];
        }
        copy_undef_vars(expr.statements, funcChain, fromScope, destScope);
        return;
    }
//    else if (exprOrStatementClass == MFExpressionStatement.class){
//        MFExpressionStatement *statement = (MFExpressionStatement *)exprOrStatement;
//        copy_undef_var(statement.expr, chain, fromScope, endScope, destScope);
//        return;
//    }
    else if (exprOrStatementClass == ORDeclareExpression.class){
        ORDeclareExpression *expr = (ORDeclareExpression *)exprOrStatement;
        NSString *name = expr.pair.var.varname;
        [chain addIndentifer:name];
        copy_undef_var(expr.expression, chain, fromScope, destScope);
        return;
        
    }else if (exprOrStatementClass == ORIfStatement.class){
        ORIfStatement *ifStatement = (ORIfStatement *)exprOrStatement;
        copy_undef_var(ifStatement.condition, chain, fromScope, destScope);
        MFVarDeclareChain *ifChain = [MFVarDeclareChain varDeclareChainWithNext:chain];
        copy_undef_var(ifStatement.funcImp, ifChain, fromScope, destScope);
        copy_undef_var(ifStatement.last, chain, fromScope, destScope);
        return;
    }else if (exprOrStatementClass == ORSwitchStatement.class){
        ORSwitchStatement *swithcStatement = (ORSwitchStatement *)exprOrStatement;
        copy_undef_var(swithcStatement.value, chain, fromScope, destScope);
        copy_undef_vars(swithcStatement.cases, chain, fromScope, destScope);
        MFVarDeclareChain *defChain = [MFVarDeclareChain varDeclareChainWithNext:chain];
        copy_undef_var(swithcStatement.funcImp, defChain, fromScope, destScope);
        return;
        
    }else if (exprOrStatementClass == ORCaseStatement.class){
        ORCaseStatement *caseStatement = (ORCaseStatement *)exprOrStatement;
        copy_undef_var(caseStatement.value, chain, fromScope, destScope);
        MFVarDeclareChain *caseChain = [MFVarDeclareChain varDeclareChainWithNext:chain];
        copy_undef_var(caseStatement.funcImp, caseChain, fromScope, destScope);
        return;
    }else if (exprOrStatementClass == ORForStatement.class){
        ORForStatement *forStatement = (ORForStatement *)exprOrStatement;
        MFVarDeclareChain *forChain = [MFVarDeclareChain varDeclareChainWithNext:chain];
        copy_undef_vars(forStatement.declareExpressions, forChain, fromScope, destScope);
        copy_undef_var(forStatement.condition, forChain, fromScope, destScope);
        copy_undef_vars(forStatement.expressions, forChain, fromScope, destScope);
        copy_undef_var(forStatement.funcImp, forChain, fromScope, destScope);
    }else if (exprOrStatementClass == ORForInStatement.class){
        ORForInStatement *forEachStatement = (ORForInStatement *)exprOrStatement;
        MFVarDeclareChain *forEachChain = [MFVarDeclareChain varDeclareChainWithNext:chain];
        copy_undef_var(forEachStatement.expression, forEachChain, fromScope, destScope);
        copy_undef_var(forEachStatement.value, forEachChain, fromScope, destScope);
        copy_undef_var(forEachStatement.funcImp, forEachChain, fromScope, destScope);
    }else if (exprOrStatementClass == ORWhileStatement.class){
        ORWhileStatement *whileStatement = (ORWhileStatement *)exprOrStatement;
        copy_undef_var(whileStatement.condition, chain, fromScope, destScope);
        MFVarDeclareChain *whileChain = [MFVarDeclareChain varDeclareChainWithNext:chain];
        copy_undef_var(whileStatement.funcImp, whileChain, fromScope, destScope);
    }else if (exprOrStatementClass == ORDoWhileStatement.class){
        ORDoWhileStatement *doWhileStatement = (ORDoWhileStatement *)exprOrStatement;
        copy_undef_var(doWhileStatement.condition, chain, fromScope, destScope);
        MFVarDeclareChain *doWhileChain = [MFVarDeclareChain varDeclareChainWithNext:chain];
        copy_undef_var(doWhileStatement.funcImp, doWhileChain, fromScope, destScope);
    }else if (exprOrStatementClass == ORReturnStatement.class){
        ORReturnStatement *returnStatement = (ORReturnStatement *)exprOrStatement;
        copy_undef_var(returnStatement.expression, chain, fromScope, destScope);
        return;
    }else if (exprOrStatementClass == ORContinueStatement.class){
        
    }else if (exprOrStatementClass == ORBreakStatement.class){
        
    }
}
@implementation ORCodeCheck(Execute)
- (nullable MFValue *)execute:(MFScopeChain *)scope {
    return nil;
}

@end
@implementation ORFuncDeclare(Execute)
- (nullable MFValue *)execute:(MFScopeChain *)scope {
    NSMutableArray * parameters = [[MFStack argsStack] pop];
    [parameters enumerateObjectsUsingBlock:^(MFValue * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [scope setValue:obj withIndentifier:self.var.pairs[idx].var.varname];
    }];
    return nil;
}
@end
@implementation ORValueExpression (Execute)
- (nullable MFValue *)execute:(MFScopeChain *)scope {
    switch (self.value_type) {
        case OCValueVariable:{
            return [scope getValueWithIdentifier:self.value];
        }
        case OCValueClassName:{
            return [MFValue valueInstanceWithClass:NSClassFromString(self.value)];
        }
        case OCValueSelf:{
            return [scope getValueWithIdentifier:@"self"];
        }
        case OCValueSuper:{
            return [scope getValueWithIdentifier:@"super"];
        }
        case OCValueSelector:{
            return [MFValue valueInstanceWithSEL:NSSelectorFromString(self.value)];
        }
//        case OCValueProtocol:{
//            return [MFValue valueInstanceWithObject:NSProtocolFromString(self.value)];
//        }
        case OCValueDictionary:{
            NSMutableArray *exps = self.value;
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            for (NSMutableArray <ORExpression *>*kv in exps) {
                ORExpression *keyExp = kv.firstObject;
                ORExpression *valueExp = kv.firstObject;
                id key = [keyExp execute:scope].objectValue;
                id value = [valueExp execute:scope].objectValue;
                NSAssert(key == nil, @"the key of NSDictionary can't be nil");
                NSAssert(value == nil, @"the vale of NSDictionary can't be nil");
                dict[key] = value;
            }
            return [MFValue valueInstanceWithObject:[dict copy]];
        }
        case OCValueArray:{
            NSMutableArray *exps = self.value;
            NSMutableArray *array = [NSMutableArray array];
            for (ORExpression *exp in exps) {
                id value = [exp execute:scope].objectValue;
                NSAssert(value == nil, @"the vale of NSArray can't be nil");
                [array addObject:value];
            }
            return [MFValue valueInstanceWithObject:[array copy]];
        }
        case OCValueNSNumber:{
            MFValue *value = [self.value execute:scope];
            ValueDefineWithMFValue(0, value);
            UnaryExecuteBaseType(NSNumber *, @, 0, value);
            return [MFValue valueInstanceWithObject:unaryResultValue0];
        }
        case OCValueString:{
            return [MFValue valueInstanceWithObject:self.value];
        }
        case OCValueCString:{
            NSString *value = self.value;
            char * cstring = malloc(value.length * sizeof(char));
            memcpy(cstring, value.UTF8String, value.length * sizeof(char));
            return [MFValue valueInstanceWithPointer:cstring];
        }
        case OCValueInt:{
            NSString *value = self.value;
            return [MFValue valueInstanceWithLongLong:value.longLongValue];
        }
        case OCValueDouble:{
            NSString *value = self.value;
            return [MFValue valueInstanceWithLongLong:value.doubleValue];
        }
        case OCValueNil:{
            return [MFValue valueInstanceWithObject:nil];
        }
        case OCValueNULL:{
            return [MFValue valueInstanceWithPointer:NULL];
        }
        case OCValueBOOL:{
            return [MFValue valueInstanceWithBOOL:[self.value isEqual:@"YES"] ? YES: NO];
            break;
        }
        default:
            break;
    }
    return nil;
}
@end
@implementation ORMethodCall(Execute)
- (nullable MFValue *)execute:(MFScopeChain *)scope {
    NSMutableArray *argValues = [NSMutableArray array];
    for (ORValueExpression *exp in self.values){
        [argValues addObject:[exp execute:scope]];
    }
    [[MFStack argsStack] push:argValues];
    id instance = scope.selfInstance;
    NSString *selector = [self.names componentsJoinedByString:@":"];
    if (self.values.count >= 1) {
        selector = [selector stringByAppendingString:@":"];
    }
    SEL sel = NSSelectorFromString(selector);
    NSMethodSignature *sig = [instance methodSignatureForSelector:sel];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:sig];
    invocation.target = instance;
    invocation.selector = sel;
    NSUInteger argCount = [sig numberOfArguments];
    for (NSUInteger i = 2; i < argCount; i++) {
        void *ptr = malloc(sizeof(char *));
        [invocation setArgument:ptr atIndex:i];
        free(ptr);
    }
    // func replaceIMP execute
    [invocation invoke];
    return nil;
}@end
@implementation ORCFuncCall(Execute)
- (nullable MFValue *)execute:(MFScopeChain *)scope {
    NSMutableArray *args = [NSMutableArray array];
    for (ORValueExpression *exp in self.expressions){
        [args addObject:[exp execute:scope]];
    }
    [[MFStack argsStack] push:args];
    if ([self.caller isKindOfClass:[ORMethodCall class]] && [(ORMethodCall *)self.caller isDot]){
        // TODO: 调用block
        // make.left.equalTo(xxxx);
        MFValue *value = [(ORMethodCall *)self.caller execute:scope];
        const char *blockTypeEncoding = [MFBlock typeEncodingForBlock:value.c2objectValue];
        NSMethodSignature *sig = [NSMethodSignature signatureWithObjCTypes:blockTypeEncoding];
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:sig];
        [invocation setTarget:value.objectValue];
        NSUInteger numberOfArguments = [sig numberOfArguments];
        if (numberOfArguments - 1 != self.expressions.count) {
//            mf_throw_error(expr.lineNumber, MFRuntimeErrorParameterListCountNoMatch, @"expect count: %zd, pass in cout:%zd",numberOfArguments - 1,expr.args.count);
            return nil;
        }
        //占位..
        for (NSUInteger i = 1; i < numberOfArguments; i++) {
            void *ptr = malloc(sizeof(char *));
            [invocation setArgument:ptr atIndex:i];
            free(ptr);
        }
        [invocation invoke];
        const char *retType = [sig methodReturnType];
        retType = removeTypeEncodingPrefix((char *)retType);
        MFValue *retValue;
        if (*retType != 'v') {
            void *retValuePtr = alloca(mf_size_with_encoding(retType));
            [invocation getReturnValue:retValuePtr];
            retValue = [[MFValue alloc] initWithCValuePointer:retValuePtr typeEncoding:retType bridgeTransfer:NO];
        }else{
            retValue = [MFValue voidValueInstance];
        }
        return retValue;
    }
    if (self.caller.value_type == OCValueVariable) {
        MFValue *blockValue = [scope getValueWithIdentifier:self.caller.value];
        if (blockValue.typePair.type.type == TypeBlock) {
            const char *blockTypeEncoding = [MFBlock typeEncodingForBlock:blockValue.c2objectValue];
            NSMethodSignature *sig = [NSMethodSignature signatureWithObjCTypes:blockTypeEncoding];
            NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:sig];
            [invocation setTarget:blockValue.objectValue];
            NSUInteger numberOfArguments = [sig numberOfArguments];
            if (numberOfArguments - 1 != self.expressions.count) {
            //            mf_throw_error(expr.lineNumber, MFRuntimeErrorParameterListCountNoMatch, @"expect count: %zd, pass in cout:%zd",numberOfArguments - 1,expr.args.count);
                return nil;
            }
            //占位..
            for (NSUInteger i = 1; i < numberOfArguments; i++) {
                void *ptr = malloc(sizeof(char *));
                [invocation setArgument:ptr atIndex:i];
                free(ptr);
            }
            [invocation invoke];
            const char *retType = [sig methodReturnType];
            retType = removeTypeEncodingPrefix((char *)retType);
            MFValue *retValue;
            if (*retType != 'v') {
                void *retValuePtr = alloca(mf_size_with_encoding(retType));
                [invocation getReturnValue:retValuePtr];
                retValue = [[MFValue alloc] initWithCValuePointer:retValuePtr typeEncoding:retType bridgeTransfer:NO];
            }else{
                retValue = [MFValue voidValueInstance];
            }
            return retValue;
        }else{
            ORBlockImp *imp = [scope getValueWithIdentifier:self.caller.value].objectValue;
            [imp execute:scope];
        }
    }
    return nil;
}
@end
@implementation ORBlockImp(Execute)
- (nullable MFValue *)execute:(MFScopeChain *)scope {
    MFScopeChain *current = [MFScopeChain scopeChainWithNext:scope];
    if (self.declare) {
        if(self.declare.isBlockDeclare){
            // xxx = ^void (int x){ }, block作为值
            MFValue *value = [MFValue new];
            [value setValueType:TypeBlock];
            MFBlock *manBlock = [[MFBlock alloc] init];
            manBlock.func = self;
            // 恢复为普通func
            [self.declare becomeNormalFuncDeclare];
            MFScopeChain *blockScope = [MFScopeChain scopeChainWithNext:[MFScopeChain topScope]];
            copy_undef_var(self, [MFVarDeclareChain new], scope, blockScope);
            manBlock.outScope = blockScope;
            const char *typeEncoding = OCTypeEncodingForPair(manBlock.func.declare.returnType);
            typeEncoding = mf_str_append(typeEncoding, "@?");
            for (ORTypeVarPair *param in manBlock.func.declare.var.pairs) {
                const char *paramTypeEncoding = OCTypeEncodingForPair(param);
                typeEncoding = mf_str_append(typeEncoding, paramTypeEncoding);
            }
            manBlock.typeEncoding = typeEncoding;
            __autoreleasing id ocBlock = [manBlock ocBlock];
            value.objectValue = ocBlock;
            CFRelease((__bridge void *)ocBlock);
            return value;
        }else{
            [self.declare execute:current];
        }
    }
    //{ }
    for (id <OCExecute>statement in self.statements) {
        MFValue *result = [statement execute:current];
        if (!result.isNormal) {
            return result;
        }
    }
    return [MFValue normalEnd];
}
@end
@implementation ORSubscriptExpression(Execute)
- (nullable MFValue *)execute:(MFScopeChain *)scope {
    MFValue *bottomValue = [self.keyExp execute:scope];
    MFValue *arrValue = [self.caller execute:scope];
    return [arrValue subscriptGetWithIndex:bottomValue];
}
@end
@implementation ORAssignExpression (Execute)
- (nullable MFValue *)execute:(MFScopeChain *)scope {
    ORExpression *resultExp;
#define SetResultExpWithBinaryOperator(type)\
    ORBinaryExpression *exp = [ORBinaryExpression new];\
    exp.left = self.value;\
    exp.right = self.expression;\
    exp.operatorType = type;\
    resultExp = exp;
    switch (self.assignType) {
        case AssignOperatorAssign:
            resultExp = self.expression;
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
    
    switch (self.value.value_type) {
        case OCValueSelf:{
            MFValue *resultValue = [resultExp execute:scope];
            [scope assignWithIdentifer:@"self" value:resultValue];
            break;
        }
        case OCValueVariable:{
            MFValue *resultValue = [resultExp execute:scope];
            [scope assignWithIdentifer:(NSString *)self.value.value value:resultValue];
            break;
        }
        case OCValueMethodCall:{
            ORMethodCall *methodCall = (ORMethodCall *)self.value;
            if (!methodCall.isDot) {
                NSCAssert(0, @"must dot grammar");
            }
            //调用对象setter方法
            NSString *setterName = methodCall.names.firstObject;
            NSString *first = [[setterName substringToIndex:1] uppercaseString];
            NSString *other = setterName.length > 1 ? [setterName substringFromIndex:1] : nil;
            setterName = [NSString stringWithFormat:@"set%@%@",first,other];
            if (methodCall.caller.value_type == OCValueSuper) {
                Class currentClass = objc_getClass(((NSString *)methodCall.caller.value).UTF8String);
                Class superClass = class_getSuperclass(currentClass);
                //FIXME: set super property
//                invoke_sueper_values([memberObjValue c2objectValue], superClass, NSSelectorFromString(memberName), @[operValue]);
            }else{
                ORMethodCall *setCaller = [ORMethodCall new];
                setCaller.caller = self.value;
                setCaller.names = [@[setterName] mutableCopy];
                setCaller.values = [@[resultExp] mutableCopy];
                [setCaller execute:scope];
            }
            break;
        }
        case OCValueCollectionGetValue:{
            MFValue *resultValue = [resultExp execute:scope];
            ORSubscriptExpression *subExp = (ORSubscriptExpression *)self.value;
            MFValue *caller = [subExp.caller execute:scope];
            MFValue *indexValue = [subExp.keyExp execute:scope];
            [caller subscriptSetValue:resultValue index:indexValue];
        }
        default:
            break;
    }
    return [MFValue normalEnd];
}
@end
@implementation ORDeclareExpression (Execute)
- (nullable MFValue *)execute:(MFScopeChain *)scope {
    if (self.expression) {
        MFValue *value = [self.expression execute:scope];
        if (!(value.typePair.type.type == TypeBlock)) {
            value.typePair = self.pair;
        }
        [scope setValue:value withIndentifier:self.pair.var.varname];
        return value;
    }else{
        [scope setValue:[MFValue defaultValueWithTypeEncoding:OCTypeEncodingForPair(self.pair)] withIndentifier:self.pair.var.varname];
    }
    return [MFValue normalEnd];
}@end
@implementation ORUnaryExpression (Execute)
- (nullable MFValue *)execute:(MFScopeChain *)scope {
    MFValue *currentValue = [self.value execute:scope];
    ValueDefineWithMFValue(0, currentValue);
    ValueDefineWithSuffix(Result);
    MFValue *resultValue = [MFValue new];
    resultValue.typePair = currentValue.typePair;
    switch (self.operatorType) {
        case UnaryOperatorIncrementSuffix:{
            SuffixUnaryExecuteInt(++, 0 , currentValue, Result);
            SuffixUnaryExecuteFloat(++, 0, currentValue, Result);
            break;
        }
        case UnaryOperatorDecrementSuffix:{
            SuffixUnaryExecuteInt(--, 0 , currentValue, Result);
            SuffixUnaryExecuteFloat(--, 0, currentValue, Result);
            break;
        }
        case UnaryOperatorIncrementPrefix:{
            PrefixUnaryExecuteInt(++, 0 , currentValue, Result);
            PrefixUnaryExecuteFloat(++, 0, currentValue, Result);
            break;
        }
        case UnaryOperatorDecrementPrefix:{
            PrefixUnaryExecuteInt(--, 0 , currentValue, Result);
            PrefixUnaryExecuteFloat(--, 0, currentValue, Result);
            break;
        }
        case UnaryOperatorNot:{
            return [MFValue valueInstanceWithBOOL:!currentValue.isSubtantial];
        }
        case UnaryOperatorSizeOf:{
            UnaryExecute(size_t, sizeof, 0 , currentValue);
            return [MFValue valueInstanceWithLongLong:unaryResultValue0];
        }
        case UnaryOperatorBiteNot:{
            PrefixUnaryExecuteInt(~, 0, currentValue, Result);
            break;
        }
        case UnaryOperatorNegative:{
            PrefixUnaryExecuteInt(-, 0 , currentValue, Result);
            PrefixUnaryExecuteFloat(-, 0, currentValue, Result);;
            break;
        }
        case UnaryOperatorAdressPoint:{
            resultValue.pointerValue = [currentValue valuePointer];
            resultValue.typePair.var.ptCount += 1;
            return resultValue;
        }
        case UnaryOperatorAdressValue:{
            if (currentValue.typePair.var.ptCount > 1) {
                resultValue.pointerValue = *(void **)currentValue.pointerValue;
            }else{
                GetPointerValue(0, currentValue);
                MFValueSetValue(resultValue, 0);
            }
            resultValue.typePair.var.ptCount -= 1;
            return resultValue;
        }
        default:
            break;
    }
    MFValueSetValue(resultValue, Result);
    return resultValue;
}@end
@implementation ORBinaryExpression(Execute)
- (nullable MFValue *)execute:(MFScopeChain *)scope {
    MFValue *rightValue = [self.right execute:scope];
    MFValue *leftValue = [self.left execute:scope];
    ValueDefineWithMFValue(left, leftValue);
    ValueDefineWithMFValue(right, rightValue);
    ValueDefineWithSuffix(Result);
    TypeKind type = rightValue.typePair.type.type;
    MFValue *resultValue = [MFValue new];
    [resultValue setValueType:type];
    switch (self.operatorType) {
        case BinaryOperatorAdd:{
            BinaryExecuteInt(left, +, right, type, Result);
            BinaryExecuteFloat(left, +, right, type, Result);
            break;
        }
        case BinaryOperatorSub:{
            BinaryExecuteInt(left, -, right, type, Result);
            BinaryExecuteFloat(left, -, right, type, Result);
            break;
        }
        case BinaryOperatorDiv:{
            BinaryExecuteInt(left, /, right, type, Result);
            BinaryExecuteFloat(left, /, right, type, Result);
            break;
        }
        case BinaryOperatorMulti:{
            BinaryExecuteInt(left, *, right, type, Result);
            BinaryExecuteFloat(left, *, right, type, Result);
            break;
        }
        case BinaryOperatorMod:{
            BinaryExecuteInt(left, %, right, type, Result);
            break;
        }
        case BinaryOperatorShiftLeft:{
            BinaryExecuteInt(left, <<, right, type, Result);
            break;
        }
        case BinaryOperatorShiftRight:{
            BinaryExecuteInt(left, >>, right, type, Result);
            break;
        }
        case BinaryOperatorAnd:{
            BinaryExecuteInt(left, &, right, type, Result);
            break;
        }
        case BinaryOperatorOr:{
            BinaryExecuteInt(left, |, right, type, Result);
            break;
        }
        case BinaryOperatorXor:{
            BinaryExecuteInt(left, ^, right, type, Result);
            break;
        }
        case BinaryOperatorLT:{
            LogicBinaryOperatorExecute(left, <, right, leftValue);
            return [MFValue valueInstanceWithBOOL:logicResultValue];
        }
        case BinaryOperatorGT:{
            LogicBinaryOperatorExecute(left, >, right, leftValue);
            return [MFValue valueInstanceWithBOOL:logicResultValue];
        }
        case BinaryOperatorLE:{
            LogicBinaryOperatorExecute(left, <=, right, leftValue);
            return [MFValue valueInstanceWithBOOL:logicResultValue];
        }
        case BinaryOperatorGE:{
            LogicBinaryOperatorExecute(left, >=, right, leftValue);
            return [MFValue valueInstanceWithBOOL:logicResultValue];
        }
        case BinaryOperatorNotEqual:{
            LogicBinaryOperatorExecute(left, !=, right, leftValue);
            return [MFValue valueInstanceWithBOOL:logicResultValue];
        }
        case BinaryOperatorEqual:{
            LogicBinaryOperatorExecute(left, ==, right, leftValue);
            return [MFValue valueInstanceWithBOOL:logicResultValue];
        }
        case BinaryOperatorLOGIC_AND:{
            LogicBinaryOperatorExecute(left, &&, right, leftValue);
            return [MFValue valueInstanceWithBOOL:logicResultValue];
        }
        case BinaryOperatorLOGIC_OR:{
            LogicBinaryOperatorExecute(left, ||, right, leftValue);
            return [MFValue valueInstanceWithBOOL:logicResultValue];
        }
        default:
            break;
    }
    MFValueSetValue(resultValue, Result);
    return resultValue;
}
@end
@implementation ORTernaryExpression(Execute)
- (nullable MFValue *)execute:(MFScopeChain *)scope {
    MFValue *condition = [self.expression execute:scope];
    if (self.values.count == 1) { // condition ?: value
        if (condition.isSubtantial) {
            return condition;
        }else{
            return [self.values.lastObject execute:scope];
        }
    }else{ // condition ? value1 : value2
        if (condition.isSubtantial) {
            return [self.values.firstObject execute:scope];
        }else{
            return [self.values.lastObject execute:scope];
        }
    }
}
@end
@implementation ORStatement (Execute)
- (nullable MFValue *)execute:(MFScopeChain *)scope {
    return [MFValue normalEnd];;
}@end
@implementation ORIfStatement (Execute)
- (nullable MFValue *)execute:(MFScopeChain *)scope {
    NSMutableArray *statements = [NSMutableArray array];
    ORIfStatement *ifStatement = self;
    while (ifStatement) {
        [statements insertObject:ifStatement atIndex:0];
        ifStatement = self.last;
    }
    for (ORIfStatement *statement in statements) {
        if ([statement.condition execute:scope].isSubtantial) {
            return [statement.funcImp execute:scope];
        }
    }
    if (self.condition == nil) {
        return [self.funcImp execute:scope];
    }
    return [MFValue normalEnd];
}@end
@implementation ORWhileStatement (Execute)
- (nullable MFValue *)execute:(MFScopeChain *)scope {
    while (1) {
        if (![self.condition execute:scope].isSubtantial) {
            break;
        }
        MFValue *resultValue = [self.funcImp execute:scope];
        if (resultValue.isBreak) {
            resultValue.resultType = MFStatementResultTypeNormal;
            break;
        }else if (resultValue.isContinue){
            resultValue.resultType = MFStatementResultTypeNormal;
        }else if (resultValue.isReturn){
            return resultValue;
        }else if (resultValue.isNormal){
            return [MFValue normalEnd];
        }
    }
    return [MFValue normalEnd];
}
@end
@implementation ORDoWhileStatement (Execute)
- (nullable MFValue *)execute:(MFScopeChain *)scope {
    while (1) {
        MFValue *resultValue = [self.funcImp execute:scope];
        if (resultValue.isBreak) {
            resultValue.resultType = MFStatementResultTypeNormal;
            break;
        }else if (resultValue.isContinue){
            resultValue.resultType = MFStatementResultTypeNormal;
        }else if (resultValue.isReturn){
            return resultValue;
        }else if (resultValue.isNormal){
            return [MFValue normalEnd];
        }
        
        if (![self.condition execute:scope].isSubtantial) {
            break;
        }
    }
    return [MFValue normalEnd];
}
@end
@implementation ORCaseStatement (Execute)
- (nullable MFValue *)execute:(MFScopeChain *)scope {
    return [self.funcImp execute:scope];
}@end
@implementation ORSwitchStatement (Execute)
- (nullable MFValue *)execute:(MFScopeChain *)scope {
    MFValue *value = [self.value execute:scope];
    ValueDefineWithMFValue(Switch, value);
    BOOL hasMatch = NO;
    for (ORCaseStatement *statement in self.cases) {
        if (statement.value) {
            if (!hasMatch) {
                MFValue *caseValue = [statement.value execute:scope];
                ValueDefineWithMFValue(Case, caseValue);
                LogicBinaryOperatorExecute(Switch, ==, Case,value);
                hasMatch = logicResultValue;
                if (!hasMatch) {
                    continue;
                }
            }
            MFValue *result = [statement.funcImp execute:scope];
            if (result.isBreak) {
                result.resultType = MFStatementResultTypeNormal;
                return value;
            }else if (result.isNormal){
                continue;
            }else{
                return value;
            }
        }else{
            MFValue *result = [statement.funcImp execute:scope];
            if (result.isBreak) {
                result.resultType = MFStatementResultTypeNormal;
                return value;
            }
        }
    }
    return [MFValue normalEnd];
}@end
@implementation ORForStatement (Execute)
- (nullable MFValue *)execute:(MFScopeChain *)scope {
    MFScopeChain *current = [MFScopeChain scopeChainWithNext:scope];
    for (ORDeclareExpression *declare in self.declareExpressions) {
        [declare execute:current];
    }
    while (1) {
        if (![self.condition execute:current].isSubtantial) {
            break;
        }
        MFValue *result = [self.funcImp execute:current];
        if (result.isReturn) {
            return result;
        }else if (result.isBreak){
            result.resultType = MFStatementResultTypeNormal;
            return result;
        }else if (result.isContinue){
            continue;
        }
        for (ORValueExpression *exp in self.expressions) {
            [exp execute:(MFScopeChain *)current];
        }
    }
    return [MFValue normalEnd];
}@end
@implementation ORForInStatement (Execute)
- (nullable MFValue *)execute:(MFScopeChain *)scope {
    MFScopeChain *current = [MFScopeChain scopeChainWithNext:scope];
    MFValue *arrayValue = [self.value execute:current];
    ValueDefineWithMFValue(Array, arrayValue);
    for (id element in objectValueArray) {
        //TODO: 每执行一次，在作用域中重新设置一次
        [current setValue:[MFValue valueInstanceWithObject:element] withIndentifier:self.expression.pair.var.varname];
        MFValue *result = [self.funcImp execute:current];
        if (result.isBreak) {
            result.resultType = MFStatementResultTypeNormal;
            return result;
        }else if(result.isContinue){
            continue;
        }else{
            return result;
        }
    }
    return [MFValue normalEnd];
}
@end
@implementation ORReturnStatement (Execute)
- (nullable MFValue *)execute:(MFScopeChain *)scope {
    if (self.expression) {
        MFValue *value = [self.expression execute:scope];
        value.resultType = MFStatementResultTypeReturnValue;
        return value;
    }else{
        MFValue *value = [MFValue voidValueInstance];
        value.resultType = MFStatementResultTypeReturnEmpty;
        return value;
    }
    return nil;
}
@end
@implementation ORBreakStatement (Execute)
- (nullable MFValue *)execute:(MFScopeChain *)scope {
    MFValue *value = [MFValue voidValueInstance];
    value.resultType = MFStatementResultTypeBreak;
    return value;
}
@end
@implementation ORContinueStatement (Execute)
- (nullable MFValue *)execute:(MFScopeChain *)scope {
    MFValue *value = [MFValue voidValueInstance];
    value.resultType = MFStatementResultTypeContinue;
    return value;
}
@end
@implementation ORPropertyDeclare(Execute)
- (nullable MFValue *)execute:(MFScopeChain *)scope {
    NSString *propertyName = self.var.var.varname;
    MFValue *classValue = [scope getValueWithIdentifier:@"Class"];
    ValueDefineWithMFValue(Current, classValue);
    Class class = classValueCurrent;
    objc_property_t property = class_getProperty(class, [propertyName UTF8String]);
    //FIXME: 自动生成get set方法
    if (property) {
        //FIXME: replace get set
    }else{
        //FIXME: add property
        class_addProperty(class, [propertyName UTF8String], self.propertyAttributes, 3);
        class_addMethod(class, NSSelectorFromString(propertyName), (IMP)registerClassGetter, "@@:");
        class_addMethod(class, NSSelectorFromString([NSString stringWithFormat:@"set%@:",[propertyName capitalizedString]]), (IMP)registerClassSetter, "v@:@");
    }
    return nil;
}
- (const objc_property_attribute_t *)propertyAttributes{
    NSValue *value = objc_getAssociatedObject(self, "propertyAttributes");
    objc_property_attribute_t *attributes = [value pointerValue];
    if (attributes != NULL) {
        return attributes;
    }
    attributes = malloc(sizeof(objc_property_attribute_t) * 3);
    attributes[0] = self.typeAttribute;
    attributes[1] = self.memeryAttribute;
    attributes[2] = self.atomicAttribute;
    objc_setAssociatedObject(self, "propertyAttributes", [NSValue valueWithPointer:attributes], OBJC_ASSOCIATION_ASSIGN);
    return attributes;
}
-(void)dealloc{
    NSValue *value = objc_getAssociatedObject(self, "propertyAttributes");
    objc_property_attribute_t **attributes = [value pointerValue];
    if (attributes != NULL) {
        free(attributes);
    }
}
- (objc_property_attribute_t )typeAttribute{
    objc_property_attribute_t type = {"T", OCTypeEncodingForPair(self.var) };
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
@implementation ORMethodDeclare(Execute)
- (nullable MFValue *)execute:(MFScopeChain *)scope {
    NSMutableArray * parameters = [[MFStack argsStack] pop];
    [parameters enumerateObjectsUsingBlock:^(MFValue * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [scope setValue:obj withIndentifier:self.parameterNames[idx]];
    }];
    return nil;
}
@end

@implementation ORMethodImplementation(Execute)
- (nullable MFValue *)execute:(MFScopeChain *)scope {
    MFScopeChain *current = [MFScopeChain scopeChainWithNext:scope];
    [self.declare execute:current];
    return [self.imp execute:current];
}
@end
#import <objc/runtime.h>

@implementation ORClass(Execute)
- (nullable MFValue *)execute:(MFScopeChain *)scope{
    Class clazz = NSClassFromString(self.className);
    MFScopeChain *current = [MFScopeChain scopeChainWithNext:scope];
    if (clazz) {
        // 添加Class变量到作用域
        [current setValue:[MFValue valueInstanceWithClass:clazz] withIndentifier:@"Class"];
        //FIXME: 注册method到作用域中,method已存在则Class中替换方法，不存在则新增
        for (ORMethodImplementation *method in self.methods) {
            replace_method(clazz, method, current);
        }
        //TODO: 注册property到作用域中,Class添加属性
        for (ORPropertyDeclare *property in self.properties) {
            [property execute:current];
        }
    }else{
        //FIXME: 新建类
        Class superClass = NSClassFromString(self.superClassName);
        if (!superClass) {
            //FIXME: 加入败者组，等待父类先加载
            return nil;
        }
        Class newClass = objc_allocateClassPair(superClass, self.className.UTF8String, 0);
        //FIXME: iVar
        for (ORPropertyDeclare *property in self.properties) {
            NSString *propertyName = property.var.var.varname;
            class_addIvar(newClass, strcat("_", propertyName.UTF8String), sizeof(int), log2(sizeof(int)), @encode(int));
        }
        //FIXME: privateVar
        for (ORTypeVarPair *privateVar in self.privateVariables) {
            
        }
//        //TODO: 添加protocol
//        for (NSString *protocolName in self.protocols) {
//            Protocol *protocol = NSProtocolFromString(protocolName);
//            class_addProtocol(newClass, protocol);
//        }
        objc_registerClassPair(newClass);
        // 添加Class变量到当前作用域
        [current setValue:[MFValue valueInstanceWithClass:newClass] withIndentifier:@"Class"];
        //FIXME: 添加属性
        for (ORPropertyDeclare *property in self.properties) {
            [property execute:current];
        }
        //FIXME: 添加方法
        for (ORMethodImplementation *method in self.methods) {
            add_method(newClass, method, scope);
        }
        //TODO: 顶级作用域添加类变量
        [[MFScopeChain topScope] setValue:[MFValue valueInstanceWithClass:newClass] withIndentifier:self.className];
    }
    return nil;
}
@end

// Document: https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtTypeEncodings.html
char *const OCTypeEncodingForPair(ORTypeVarPair * pair){
    char encoding[20];
    memset(encoding, 0, 20);
#define append(str) strcat(encoding,str)
    NSInteger pointCount = pair.var.ptCount;
    TypeKind type = pair.type.type;
    while (pointCount > 0) {
        if (type == TypeBlock) {
            break;
        }
        if (type == TypeChar && pointCount == 1) {
            pointCount--;
            continue;
        }
        if (type == TypeObject && pointCount == 1) {
            pointCount--;
            continue;
        }
        append("^");
        pointCount--;
    }
    
#define CaseTypeEncoding(type,code)\
case type:\
append(code); break;

    switch (type) {
        case TypeChar:
        {
            if (pair.var.ptCount > 0)
                append("*");
            else
                append("c");
            break;
        }
        CaseTypeEncoding(TypeInt, "i")
        CaseTypeEncoding(TypeShort, "s")
        CaseTypeEncoding(TypeLong, "l")
        CaseTypeEncoding(TypeLongLong, "q")
        CaseTypeEncoding(TypeUChar, "C")
        CaseTypeEncoding(TypeUInt, "I")
        CaseTypeEncoding(TypeUShort, "S")
        CaseTypeEncoding(TypeULong, "L")
        CaseTypeEncoding(TypeULongLong, "Q")
        CaseTypeEncoding(TypeFloat, "f")
        CaseTypeEncoding(TypeDouble, "d")
        CaseTypeEncoding(TypeBOOL, "B")
        CaseTypeEncoding(TypeVoid, "v")
        CaseTypeEncoding(TypeObject, "@")
        CaseTypeEncoding(TypeId, "@")
        CaseTypeEncoding(TypeClass, "#")
        CaseTypeEncoding(TypeSEL, ":")
        CaseTypeEncoding(TypeBlock, "@?")
        default:
            break;
    }
    append("\0");
    char *const result = malloc(sizeof(char) * 20);
    strcpy(result, encoding);
    return result;
}
