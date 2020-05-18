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
#import "MFWeakPropertyBox.h"
#import "MFBlock.h"
#import "MFValue.h"
#import <objc/message.h>
static MFValue *invoke_sueper_values(id instance, SEL sel, NSArray<MFValue *> *argValues){
    BOOL isClassMethod = object_isClass(instance);
    Class superClass;
    if (isClassMethod) {
        superClass = class_getSuperclass(instance);
    }else{
        superClass = class_getSuperclass([instance class]);
    }
    struct objc_super *superPtr = &(struct objc_super){instance,superClass};
    NSMethodSignature *sig = [instance methodSignatureForSelector:sel];
    NSUInteger argCount = sig.numberOfArguments;
    
    void **args = alloca(sizeof(void *) * argCount);
    ffi_type **argTypes = alloca(sizeof(ffi_type *) * argCount);
    
    argTypes[0] = &ffi_type_pointer;
    args[0] = &superPtr;
    
    argTypes[1] = &ffi_type_pointer;
    args[1] = &sel;
    
    for (NSUInteger i = 2; i < argCount; i++) {
        MFValue *argValue = argValues[i-2];
        char *argTypeEncoding = (char *)[sig getArgumentTypeAtIndex:i];
        argTypeEncoding = removeTypeEncodingPrefix(argTypeEncoding);
#define mf_SET_FFI_TYPE_AND_ARG_CASE(_code, _type, _ffi_type_value, _sel)\
case _code:{\
argTypes[i] = &_ffi_type_value;\
_type value = (_type)argValue._sel;\
args[i] = &value;\
break;\
}
        switch (*argTypeEncoding) {
                mf_SET_FFI_TYPE_AND_ARG_CASE('c', char, ffi_type_schar, charValue)
                mf_SET_FFI_TYPE_AND_ARG_CASE('i', int, ffi_type_sint, intValue)
                mf_SET_FFI_TYPE_AND_ARG_CASE('s', short, ffi_type_sshort, shortValue)
                mf_SET_FFI_TYPE_AND_ARG_CASE('l', long, ffi_type_slong, longValue)
                mf_SET_FFI_TYPE_AND_ARG_CASE('q', long long, ffi_type_sint64, longLongValue)
                mf_SET_FFI_TYPE_AND_ARG_CASE('C', unsigned char, ffi_type_uchar, uCharValue)
                mf_SET_FFI_TYPE_AND_ARG_CASE('I', unsigned int, ffi_type_uint, uIntValue)
                mf_SET_FFI_TYPE_AND_ARG_CASE('S', unsigned short, ffi_type_ushort, uShortValue)
                mf_SET_FFI_TYPE_AND_ARG_CASE('L', unsigned long, ffi_type_ulong, uLongValue)
                mf_SET_FFI_TYPE_AND_ARG_CASE('Q', unsigned long long, ffi_type_uint64, uLongLongValue)
                mf_SET_FFI_TYPE_AND_ARG_CASE('B', BOOL, ffi_type_sint8, boolValue)
                mf_SET_FFI_TYPE_AND_ARG_CASE('f', float, ffi_type_float, floatValue)
                mf_SET_FFI_TYPE_AND_ARG_CASE('d', double, ffi_type_double, doubleValue)
                mf_SET_FFI_TYPE_AND_ARG_CASE('@', id, ffi_type_pointer, c2objectValue)
                mf_SET_FFI_TYPE_AND_ARG_CASE('#', Class, ffi_type_pointer, c2objectValue)
                mf_SET_FFI_TYPE_AND_ARG_CASE(':', SEL, ffi_type_pointer, selValue)
                mf_SET_FFI_TYPE_AND_ARG_CASE('*', char *, ffi_type_pointer, c2pointerValue)
                mf_SET_FFI_TYPE_AND_ARG_CASE('^', id, ffi_type_pointer, c2pointerValue)
            default:
                NSCAssert(0, @"not support type  %s", argTypeEncoding);
                break;
        }
        
    }
    
    char *returnTypeEncoding = (char *)[sig methodReturnType];
    returnTypeEncoding = removeTypeEncodingPrefix(returnTypeEncoding);
    ffi_type *rtype = NULL;
    void *rvalue = NULL;
#define mf_FFI_RETURN_TYPE_CASE(_code, _ffi_type)\
case _code:{\
rtype = &_ffi_type;\
rvalue = alloca(rtype->size);\
break;\
}
    
    switch (*returnTypeEncoding) {
            mf_FFI_RETURN_TYPE_CASE('c', ffi_type_schar)
            mf_FFI_RETURN_TYPE_CASE('i', ffi_type_sint)
            mf_FFI_RETURN_TYPE_CASE('s', ffi_type_sshort)
            mf_FFI_RETURN_TYPE_CASE('l', ffi_type_slong)
            mf_FFI_RETURN_TYPE_CASE('q', ffi_type_sint64)
            mf_FFI_RETURN_TYPE_CASE('C', ffi_type_uchar)
            mf_FFI_RETURN_TYPE_CASE('I', ffi_type_uint)
            mf_FFI_RETURN_TYPE_CASE('S', ffi_type_ushort)
            mf_FFI_RETURN_TYPE_CASE('L', ffi_type_ulong)
            mf_FFI_RETURN_TYPE_CASE('Q', ffi_type_uint64)
            mf_FFI_RETURN_TYPE_CASE('B', ffi_type_sint8)
            mf_FFI_RETURN_TYPE_CASE('f', ffi_type_float)
            mf_FFI_RETURN_TYPE_CASE('d', ffi_type_double)
            mf_FFI_RETURN_TYPE_CASE('@', ffi_type_pointer)
            mf_FFI_RETURN_TYPE_CASE('#', ffi_type_pointer)
            mf_FFI_RETURN_TYPE_CASE(':', ffi_type_pointer)
            mf_FFI_RETURN_TYPE_CASE('^', ffi_type_pointer)
            mf_FFI_RETURN_TYPE_CASE('*', ffi_type_pointer)
            mf_FFI_RETURN_TYPE_CASE('v', ffi_type_void)
        case '{':{
            rtype = mf_ffi_type_with_type_encoding(returnTypeEncoding);
            rvalue = alloca(rtype->size);
        }
            
        default:
            NSCAssert(0, @"not support type  %s", returnTypeEncoding);
            break;
    }
    ffi_cif cif;
    ffi_prep_cif(&cif, FFI_DEFAULT_ABI, (unsigned int)argCount, rtype, argTypes);
    ffi_call(&cif, objc_msgSendSuper, rvalue, args);
    MFValue *retValue;
    if (*returnTypeEncoding != 'v') {
        retValue = [[MFValue alloc] initWithCValuePointer:rvalue typeEncoding:returnTypeEncoding bridgeTransfer:NO];
    }else{
        retValue = [MFValue voidValueInstance];
    }
    return retValue;
}

static MFValue * invoke_MFBlockValue(MFValue *blockValue, NSArray *args){
    const char *blockTypeEncoding = [MFBlock typeEncodingForBlock:blockValue.c2objectValue];
    NSMethodSignature *sig = [NSMethodSignature signatureWithObjCTypes:blockTypeEncoding];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:sig];
    [invocation setTarget:blockValue.objectValue];
    NSUInteger numberOfArguments = [sig numberOfArguments];
    if (numberOfArguments - 1 != args.count) {
        //            mf_throw_error(expr.lineNumber, MFRuntimeErrorParameterListCountNoMatch, @"expect count: %zd, pass in cout:%zd",numberOfArguments - 1,expr.args.count);
        return nil;
    }
    //根据MFValue的type传入值的原因: 模拟在OC中的调用
    for (NSUInteger i = 1; i < numberOfArguments; i++) {
        const char *typeEncoding = [sig getArgumentTypeAtIndex:i];
        void *ptr = alloca(mf_size_with_encoding(typeEncoding));
        __autoreleasing MFValue *argValue = args[i -1];
        [argValue assignToCValuePointer:ptr typeEncoding:typeEncoding];
        [invocation setArgument:ptr atIndex:i];
        
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
    id assignSelf = (__bridge  id)(*(void **)args[0]);
    BOOL classMethod = object_isClass(assignSelf);
    if (classMethod) {
        [scope setValue:[MFValue valueInstanceWithClass:assignSelf] withIndentifier:@"self"];
    }else{
        [scope setValue:[MFValue valueInstanceWithObject:assignSelf] withIndentifier:@"self"];
    }
    SEL sel = *(void **)args[1];
    MFMethodMapTableItem *map = [[MFMethodMapTable shareInstance] getMethodMapTableItemWith:class classMethod:classMethod sel:sel];
    NSMethodSignature *methodSignature = [NSMethodSignature signatureWithObjCTypes:typeEncoding.UTF8String];
    NSMutableArray<MFValue *> *argValues = [NSMutableArray array];
    NSUInteger numberOfArguments = [methodSignature numberOfArguments];
    // 在OC中，传入值都为原数值并非MFValue，需要转换
    for (NSUInteger i = 2; i < numberOfArguments; i++) {
        MFValue *argValue;
        const char *type = [methodSignature getArgumentTypeAtIndex:i];
        if (strcmp(type, "@?") == 0) {
            id block =  (__bridge id)(*(void **)args[i]);
            block = [block copy];
            argValue = [MFValue valueInstanceWithObject:block];
            argValue.typePair.type.type = TypeBlock;
        }else{
            void *arg = args[i];
            argValue = [[MFValue alloc] initWithCValuePointer:arg typeEncoding:[methodSignature getArgumentTypeAtIndex:i] bridgeTransfer:NO];
        }
        
        [argValues addObject:argValue];
    }
    [[MFStack argsStack] push:argValues];
    __autoreleasing MFValue *retValue = [map.methodImp execute:scope];
    [retValue assignToCValuePointer:ret typeEncoding:[methodSignature methodReturnType]];
}


static void replace_method(Class clazz, ORMethodImplementation *methodImp, MFScopeChain *scope){
    ORMethodDeclare *declare = methodImp.declare;
    NSString *methodName = declare.selectorName;
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
        needFreeTypeEncoding = YES;
        typeEncoding = mf_str_append(typeEncoding, "@"); //self
        typeEncoding = mf_str_append(typeEncoding, ":"); //_cmd
        for (ORTypeVarPair *pair in methodImp.declare.parameterTypes) {
            const char *paramTypeEncoding = OCTypeEncodingForPair(pair);
            const char *beforeTypeEncoding = typeEncoding;
            typeEncoding = mf_str_append(typeEncoding, paramTypeEncoding);
            free((void *)beforeTypeEncoding);
            free((void *)paramTypeEncoding);
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

void getterInter(ffi_cif *cif, void *ret, void **args, void *userdata){
    ORPropertyDeclare *propDef = (__bridge ORPropertyDeclare *)userdata;
    id _self = (__bridge id)(*(void **)args[0]);
    NSString *propName = propDef.var.var.varname;
    id propValue = objc_getAssociatedObject(_self, mf_propKey(propName));
    const char *type = OCTypeEncodingForPair(propDef.var);
    __autoreleasing MFValue *value;
    if (!propValue) {
        value = [MFValue defaultValueWithTypeEncoding:type];
        [value assignToCValuePointer:ret typeEncoding:type];
    }else if(*type == '@'){
        if ([propValue isKindOfClass:[MFWeakPropertyBox class]]) {
            MFWeakPropertyBox *box = propValue;
            if (box.target) {
                *(void **)ret = (__bridge void *)box.target;
            }else{
                value = [MFValue defaultValueWithTypeEncoding:type];
                [value assignToCValuePointer:ret typeEncoding:type];
            }
        }else{
            *(void **)ret = (__bridge void *)propValue;
        }
    }else{
        value = propValue;
        [value assignToCValuePointer:ret typeEncoding:type];
    }
}
void setterInter(ffi_cif *cif, void *ret, void **args, void *userdata){
    ORPropertyDeclare *propDef = (__bridge ORPropertyDeclare *)userdata;
    id _self = (__bridge id)(*(void **)args[0]);
    const char *type = OCTypeEncodingForPair(propDef.var);
    id value;
    if (*type == '@') {
        value = (__bridge id)(*(void **)args[2]);
    }else{
        value = [[MFValue alloc] initWithCValuePointer:args[2] typeEncoding:type bridgeTransfer:NO];
    }
    NSString *propName = propDef.var.var.varname;
    MFPropertyModifier modifier = propDef.modifier;
    if ((modifier & MFPropertyModifierMemMask) == MFPropertyModifierMemWeak) {
        value = [[MFWeakPropertyBox alloc] initWithTarget:value];
    }
    objc_AssociationPolicy associationPolicy = mf_AssociationPolicy_with_PropertyModifier(modifier);
    objc_setAssociatedObject(_self, mf_propKey(propName), value, associationPolicy);
}

static void replace_getter_method(Class clazz, ORPropertyDeclare *prop){
    SEL getterSEL = NSSelectorFromString(prop.var.var.varname);
    const char *retTypeEncoding  = OCTypeEncodingForPair(prop.var);
    ffi_type *returnType = mf_ffi_type_with_type_encoding(retTypeEncoding);
    unsigned int argCount = 2;
    ffi_type **argTypes = malloc(sizeof(ffi_type *) * argCount);
    argTypes[0] = &ffi_type_pointer;
    argTypes[1] = &ffi_type_pointer;
    void *imp = NULL;
    ffi_cif *cifPtr = malloc(sizeof(ffi_cif));
    ffi_prep_cif(cifPtr, FFI_DEFAULT_ABI, argCount, returnType, argTypes);
    ffi_closure *closure = ffi_closure_alloc(sizeof(ffi_closure), (void **)&imp);
    ffi_prep_closure_loc(closure, cifPtr, getterInter, (__bridge void *)prop, imp);
    const char * typeEncoding = mf_str_append(retTypeEncoding, "@:");
    class_replaceMethod(clazz, getterSEL, (IMP)imp, typeEncoding);
    free((void *)typeEncoding);
}

static void replace_setter_method(Class clazz, ORPropertyDeclare *prop){
    NSString *name = prop.var.var.varname;
    NSString *str1 = [[name substringWithRange:NSMakeRange(0, 1)] uppercaseString];
    NSString *str2 = name.length > 1 ? [name substringFromIndex:1] : nil;
    SEL setterSEL = NSSelectorFromString([NSString stringWithFormat:@"set%@%@:",str1,str2]);
    const char *prtTypeEncoding  = OCTypeEncodingForPair(prop.var);
    ffi_type *returnType = &ffi_type_void;
    unsigned int argCount = 3;
    ffi_type **argTypes = malloc(sizeof(ffi_type *) * argCount);
    argTypes[0] = &ffi_type_pointer;
    argTypes[1] = &ffi_type_pointer;
    argTypes[2] = mf_ffi_type_with_type_encoding(prtTypeEncoding);
    if (argTypes[2] == NULL) {
//        mf_throw_error(lineNumber, @"", @"");
    }
    void *imp = NULL;
    ffi_cif *cifPtr = malloc(sizeof(ffi_cif));
    ffi_prep_cif(cifPtr, FFI_DEFAULT_ABI, argCount, returnType, argTypes);
    ffi_closure *closure = ffi_closure_alloc(sizeof(ffi_closure), (void **)&imp);
    ffi_prep_closure_loc(closure, cifPtr, setterInter, (__bridge void *)prop, imp);
    const char * typeEncoding = mf_str_append("v@:", prtTypeEncoding);
    class_replaceMethod(clazz, setterSEL, (IMP)imp, typeEncoding);
    free((void *)typeEncoding);
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
        NSArray <ORTypeVarPair *>*params = funcDeclare.funVar.pairs;
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
        copy_undef_vars(forStatement.varExpressions, forChain, fromScope, destScope);
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
        [scope setValue:obj withIndentifier:self.funVar.pairs[idx].var.varname];
    }];
    return nil;
}
@end
@implementation ORValueExpression (Execute)
- (nullable MFValue *)execute:(MFScopeChain *)scope {
    switch (self.value_type) {
        case OCValueVariable:{
            MFValue *value = [scope getValueWithIdentifierInChain:self.value];
            if (!value) {
                value = [MFValue valueInstanceWithClass:NSClassFromString(self.value)];
            }
            NSCAssert(value, @"must exsited");
            return value;
        }
        case OCValueSelf:
        case OCValueSuper:{
            return [scope getValueWithIdentifier:@"self"];
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
                NSAssert(value != nil, @"the vale of NSArray can't be nil");
                [array addObject:value];
            }
            return [MFValue valueInstanceWithObject:[array copy]];
        }
        case OCValueNSNumber:{
            MFValue *value = [self.value execute:scope];
            NSNumber *result = nil;
            UnaryExecuteBaseType(result, @, value);
            return [MFValue valueInstanceWithObject:result];
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
    MFValue *variable = [self.caller execute:scope];
    id instance = variable.objectValue;
    if (!instance) {
        if (variable.classValue) {
            instance = variable.classValue;
        }else{
            NSCAssert(0, @"objectValue or classValue must has one");
        }
    }
    SEL sel = NSSelectorFromString(self.selectorName);
    NSMutableArray <MFValue *>*argValues = [NSMutableArray array];
    for (ORValueExpression *exp in self.values){
        [argValues addObject:[exp execute:scope]];
    }
    if (self.caller.value_type == OCValueSuper) {
        return invoke_sueper_values(instance, sel, argValues);
    }
    NSMethodSignature *sig = [instance methodSignatureForSelector:sel];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:sig];
    invocation.target = instance;
    invocation.selector = sel;
    NSUInteger argCount = [sig numberOfArguments];
    //根据MFValue的type传入值的原因: 模拟在OC中的调用
    //FIXME: 多参数问题，self.values.count + 2 > argCount 时，采用多参数，超出参数压栈
    for (NSUInteger i = 2; i < argCount; i++) {
        const char *typeEncoding = [sig getArgumentTypeAtIndex:i];
        void *ptr = alloca(mf_size_with_encoding(typeEncoding));
        [argValues[i-2] assignToCValuePointer:ptr typeEncoding:typeEncoding];
        [invocation setArgument:ptr atIndex:i];
    }
    // func replaceIMP execute
    [invocation invoke];
    char *returnType = (char *)[sig methodReturnType];
    returnType = removeTypeEncodingPrefix(returnType);
    MFValue *retValue;
    if (*returnType != 'v') {
        void *retValuePointer = malloc([sig methodReturnLength]);
        [invocation getReturnValue:retValuePointer];
        NSString *selectorName = NSStringFromSelector(sel);
        if ([selectorName isEqualToString:@"alloc"] || [selectorName isEqualToString:@"new"] ||
            [selectorName isEqualToString:@"copy"] || [selectorName isEqualToString:@"mutableCopy"]) {
            retValue = [[MFValue alloc] initWithCValuePointer:retValuePointer typeEncoding:returnType bridgeTransfer:YES];
        }else{
            retValue = [[MFValue alloc] initWithCValuePointer:retValuePointer typeEncoding:returnType bridgeTransfer:NO];
        }
        
        free(retValuePointer);
    }else{
        retValue = [MFValue voidValueInstance];
    }
    return retValue;
}@end
@implementation ORCFuncCall(Execute)
- (nullable MFValue *)execute:(MFScopeChain *)scope {
    NSMutableArray *args = [NSMutableArray array];
    for (ORValueExpression *exp in self.expressions){
        [args addObject:[exp execute:scope]];
    }
    if ([self.caller isKindOfClass:[ORMethodCall class]] && [(ORMethodCall *)self.caller isDot]){
        // TODO: 调用block
        // make.left.equalTo(xxxx);
        MFValue *value = [(ORMethodCall *)self.caller execute:scope];
        //FIXME: see initWithCValuePointer 'FIXME' note
        return invoke_MFBlockValue(value, args);
//        if (value.typePair.type.type == TypeBlock) {
//            return invoke_MFBlockValue(value, args);
//        }else{
//            NSCAssert(0, @"must be a block value");
//        }
    }
    if (self.caller.value_type == OCValueVariable) {
        MFValue *blockValue = [scope getValueWithIdentifier:self.caller.value];
        if (blockValue.typePair.type.type == TypeBlock) {
            return invoke_MFBlockValue(blockValue, args);
        }else{
            // global function calll
            [[MFStack argsStack] push:args];
            ORBlockImp *imp = blockValue.objectValue;
            return [imp execute:scope];
        }
    }
    return nil;
}
@end
@implementation ORBlockImp(Execute)
- (nullable MFValue *)execute:(MFScopeChain *)scope {
    // C函数声明执行, 向全局作用域注册函数
    if (scope == [MFScopeChain topScope] && self.declare && self.declare.funVar.ptCount == 0) {
        NSString *funcName = self.declare.funVar.varname;
        if ([scope getValueWithIdentifier:funcName] == nil) {
            [scope setValue:[MFValue valueInstanceWithObject:self] withIndentifier:funcName];
            return nil;
        }
    }
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
            for (ORTypeVarPair *param in manBlock.func.declare.funVar.pairs) {
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
            ORMethodCall *setCaller = [ORMethodCall new];
            setCaller.caller = [(ORMethodCall *)self.value caller];
            setCaller.names = [@[setterName] mutableCopy];
            setCaller.values = [@[resultExp] mutableCopy];
            [setCaller execute:scope];
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
    MFValue *resultValue = [MFValue new];
    resultValue.typePair = currentValue.typePair;
    switch (self.operatorType) {
        case UnaryOperatorIncrementSuffix:{
            SuffixUnaryExecuteInt(++, currentValue , resultValue);
            SuffixUnaryExecuteFloat(++, currentValue , resultValue);
            break;
        }
        case UnaryOperatorDecrementSuffix:{
            SuffixUnaryExecuteInt(--, currentValue , resultValue);
            SuffixUnaryExecuteFloat(--, currentValue , resultValue);
            break;
        }
        case UnaryOperatorIncrementPrefix:{
            PrefixUnaryExecuteInt(++, currentValue , resultValue);
            PrefixUnaryExecuteFloat(++, currentValue , resultValue);
            break;
        }
        case UnaryOperatorDecrementPrefix:{
            PrefixUnaryExecuteInt(--, currentValue , resultValue);
            PrefixUnaryExecuteFloat(--, currentValue , resultValue);
            break;
        }
        case UnaryOperatorNot:{
            return [MFValue valueInstanceWithBOOL:!currentValue.isSubtantial];
        }
        case UnaryOperatorSizeOf:{
            size_t result = 0;
            UnaryExecute(result, sizeof, currentValue);
            return [MFValue valueInstanceWithLongLong:result];
        }
        case UnaryOperatorBiteNot:{
            PrefixUnaryExecuteInt(~, currentValue , resultValue);
            break;
        }
        case UnaryOperatorNegative:{
            PrefixUnaryExecuteInt(-, currentValue , resultValue);
            PrefixUnaryExecuteFloat(-, currentValue , resultValue);;
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
                MFValueGetValueInPointer(resultValue, currentValue);
            }
            resultValue.typePair.var.ptCount -= 1;
            return resultValue;
        }
        default:
            break;
    }
    return resultValue;
}@end
@implementation ORBinaryExpression(Execute)
- (nullable MFValue *)execute:(MFScopeChain *)scope {
    MFValue *rightValue = [self.right execute:scope];
    MFValue *leftValue = [self.left execute:scope];
    MFValue *resultValue = [MFValue new];
    [resultValue setValueType:leftValue.typePair.type.type];
    switch (self.operatorType) {
        case BinaryOperatorAdd:{
            BinaryExecuteInt(leftValue, +, rightValue, resultValue);
            BinaryExecuteFloat(leftValue, +, rightValue, resultValue);
            break;
        }
        case BinaryOperatorSub:{
            BinaryExecuteInt(leftValue, -, rightValue, resultValue);
            BinaryExecuteFloat(leftValue, -, rightValue, resultValue);
            break;
        }
        case BinaryOperatorDiv:{
            BinaryExecuteInt(leftValue, /, rightValue, resultValue);
            BinaryExecuteFloat(leftValue, /, rightValue, resultValue);
            break;
        }
        case BinaryOperatorMulti:{
            BinaryExecuteInt(leftValue, *, rightValue, resultValue);
            BinaryExecuteFloat(leftValue, *, rightValue, resultValue);
            break;
        }
        case BinaryOperatorMod:{
            BinaryExecuteInt(leftValue, %, rightValue, resultValue);
            break;
        }
        case BinaryOperatorShiftLeft:{
            BinaryExecuteInt(leftValue, <<, rightValue, resultValue);
            break;
        }
        case BinaryOperatorShiftRight:{
            BinaryExecuteInt(leftValue, >>, rightValue, resultValue);
            break;
        }
        case BinaryOperatorAnd:{
            BinaryExecuteInt(leftValue, &, rightValue, resultValue);
            break;
        }
        case BinaryOperatorOr:{
            BinaryExecuteInt(leftValue, |, rightValue, resultValue);
            break;
        }
        case BinaryOperatorXor:{
            BinaryExecuteInt(leftValue, ^, rightValue, resultValue);
            break;
        }
        case BinaryOperatorLT:{
            LogicBinaryOperatorExecute(leftValue, <, rightValue);
            return [MFValue valueInstanceWithBOOL:logicResultValue];
        }
        case BinaryOperatorGT:{
            LogicBinaryOperatorExecute(leftValue, >, rightValue);
            return [MFValue valueInstanceWithBOOL:logicResultValue];
        }
        case BinaryOperatorLE:{
            LogicBinaryOperatorExecute(leftValue, <=, rightValue);
            return [MFValue valueInstanceWithBOOL:logicResultValue];
        }
        case BinaryOperatorGE:{
            LogicBinaryOperatorExecute(leftValue, >=, rightValue);
            return [MFValue valueInstanceWithBOOL:logicResultValue];
        }
        case BinaryOperatorNotEqual:{
            LogicBinaryOperatorExecute(leftValue, !=, rightValue);
            return [MFValue valueInstanceWithBOOL:logicResultValue];
        }
        case BinaryOperatorEqual:{
            LogicBinaryOperatorExecute(leftValue, ==, rightValue);
            return [MFValue valueInstanceWithBOOL:logicResultValue];
        }
        case BinaryOperatorLOGIC_AND:{
            LogicBinaryOperatorExecute(leftValue, &&, rightValue);
            return [MFValue valueInstanceWithBOOL:logicResultValue];
        }
        case BinaryOperatorLOGIC_OR:{
            LogicBinaryOperatorExecute(leftValue, ||, rightValue);
            return [MFValue valueInstanceWithBOOL:logicResultValue];
        }
        default:
            break;
    }
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
        ifStatement = ifStatement.last;
    }
    for (ORIfStatement *statement in statements) {
        MFValue *conditionValue = [statement.condition execute:scope];
        if (conditionValue.isSubtantial) {
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
    BOOL hasMatch = NO;
    for (ORCaseStatement *statement in self.cases) {
        if (statement.value) {
            if (!hasMatch) {
                MFValue *caseValue = [statement.value execute:scope];
                LogicBinaryOperatorExecute(value, ==, caseValue);
                hasMatch = logicResultValue;
                if (!hasMatch) {
                    continue;
                }
            }
            MFValue *result = [statement.funcImp execute:scope];
            if (result.isBreak) {
                result.resultType = MFStatementResultTypeNormal;
                return result;
            }else if (result.isNormal){
                continue;
            }else{
                return result;
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
    for (ORExpression *exp in self.varExpressions) {
        [exp execute:current];
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
        for (ORExpression *exp in self.expressions) {
            [exp execute:(MFScopeChain *)current];
        }
    }
    return [MFValue normalEnd];
}@end
@implementation ORForInStatement (Execute)
- (nullable MFValue *)execute:(MFScopeChain *)scope {
    MFScopeChain *current = [MFScopeChain scopeChainWithNext:scope];
    MFValue *arrayValue = [self.value execute:current];
    for (id element in arrayValue.objectValue) {
        //TODO: 每执行一次，在作用域中重新设置一次
        [current setValue:[MFValue valueInstanceWithObject:element] withIndentifier:self.expression.pair.var.varname];
        MFValue *result = [self.funcImp execute:current];
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
    Class class = classValue.classValue;
    class_replaceProperty(class, [propertyName UTF8String], self.propertyAttributes, 3);
    MFPropertyMapTableItem *propItem = [[MFPropertyMapTableItem alloc] initWithClass:class property:self];
    [[MFPropertyMapTable shareInstance] addPropertyMapTableItem:propItem];
    replace_getter_method(class, self);
    replace_setter_method(class, self);
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
/// 执行时，根据继承顺序执行
- (nullable MFValue *)execute:(MFScopeChain *)scope{
    Class clazz = NSClassFromString(self.className);
    MFScopeChain *current = [MFScopeChain scopeChainWithNext:scope];
    if (!clazz) {
        Class superClass = NSClassFromString(self.superClassName);
        clazz = objc_allocateClassPair(superClass, self.className.UTF8String, 0);
        objc_registerClassPair(clazz);
    }
    // 添加Class变量到作用域
    [current setValue:[MFValue valueInstanceWithClass:clazz] withIndentifier:@"Class"];
    for (ORMethodImplementation *method in self.methods) {
        replace_method(clazz, method, current);
    }
    for (ORPropertyDeclare *property in self.properties) {
        [property execute:current];
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
