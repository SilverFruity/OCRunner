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
#import <oc2mangoLib/oc2mangoLib.h>
#import <objc/message.h>
#import "ORCoreImp.h"
#import "ORSearchedFunction.h"
#import "ORffiResultCache.h"
#import "ORInterpreter.h"
#import <oc2mangoLib/InitialSymbolTableVisitor.h>
static void invoke_MFBlockValue(ORThreadContext *ctx, or_value blockValue, or_value **args, NSUInteger argCount){
    id block = (__bridge id)*blockValue.pointer;
#if DEBUG
    if (block == nil) {
        NSLog(@"%@",[ORCallFrameStack history]);
    }
#endif
    assert(block != nil);
    const char *blockTypeEncoding = NSBlockGetSignature(*blockValue.pointer);
    NSMethodSignature *sig = [NSMethodSignature signatureWithObjCTypes:blockTypeEncoding];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:sig];
    [invocation setTarget:block];
    NSUInteger numberOfArguments = [sig numberOfArguments];
    if (numberOfArguments - 1 != argCount) {
        [ctx opStackPush:or_Object_value(nil)];
        return;
    }
    //根据MFValue的type传入值的原因: 模拟在OC中的调用
    for (NSUInteger i = 1; i < numberOfArguments; i++) {
        or_value *argValue = args[i -1];
        // 基础类型转换
        argValue->typeencode = [sig getArgumentTypeAtIndex:i];
        [invocation setArgument:argValue->pointer atIndex:i];
    }
    [invocation invoke];
    const char *retType = [sig methodReturnType];
    retType = removeTypeEncodingPrefix((char *)retType);
    if (*retType == 'v') {
        [ctx opStackPush:or_voidValue()];
        return;
    }
    void *retValuePtr = alloca(mf_size_with_encoding(retType));
    [invocation getReturnValue:retValuePtr];
    [ctx opStackPush:or_value_create(retType, retValuePtr)];
    return;
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
static void replace_method(Class clazz, ORMethodNode *methodImp){
    const char *typeEncoding = methodImp.symbol.decl.typeEncode;
    Class c2 = methodImp.declare.isClassMethod ? objc_getMetaClass(class_getName(clazz)) : clazz;
    MFMethodMapTableItem *item = [[MFMethodMapTableItem alloc] initWithClass:c2 method:methodImp];
    [[MFMethodMapTable shareInstance] addMethodMapTableItem:item];
    
    ORMethodDeclNode *declare = methodImp.declare;
    NSMutableArray *decls = [NSMutableArray array];
    for (ORDeclaratorNode *param in declare.parameters) {
        [decls addObject:param.symbol.decl];
    }
    or_ffi_result *result = register_method(&methodIMP, decls, declare.returnType.symbol.decl, (__bridge_retained void *)methodImp);
    [[ORffiResultCache shared] saveffiResult:result WithKey:[NSValue valueWithPointer:(__bridge void *)methodImp]];
    SEL sel = NSSelectorFromString(methodImp.declare.selectorName);
    or_method_replace(methodImp.declare.isClassMethod, clazz, sel, result->function_imp, typeEncoding);
}

static void replace_getter_method(Class clazz, ORPropertyNode *prop){
    SEL getterSEL = NSSelectorFromString(prop.var.var.varname);
    const char *retTypeEncoding  = prop.var.symbol.decl.typeEncode;
    const char * typeEncoding = mf_str_append(retTypeEncoding, "@:");
    or_ffi_result *result = register_method(&getterImp, @[], prop.var.symbol.decl, (__bridge  void *)prop);
    [[ORffiResultCache shared] saveffiResult:result WithKey:[NSValue valueWithPointer:(__bridge void *)prop]];
    or_method_replace(NO, clazz, getterSEL, result->function_imp, typeEncoding);
    free((void *)typeEncoding);
}

static void replace_setter_method(Class clazz, ORPropertyNode *prop){
    NSString *name = prop.var.var.varname;
    NSString *str1 = [[name substringWithRange:NSMakeRange(0, 1)] uppercaseString];
    NSString *str2 = name.length > 1 ? [name substringFromIndex:1] : nil;
    SEL setterSEL = NSSelectorFromString([NSString stringWithFormat:@"set%@%@:",str1,str2]);
    const char *prtTypeEncoding  = prop.var.symbol.decl.typeEncode;
    const char * typeEncoding = mf_str_append("v@:", prtTypeEncoding);
    or_ffi_result *result = register_method(&setterImp, @[prop.var.symbol.decl], [ocDecl declWithTypeEncode:OCTypeStringVoid],(__bridge_retained  void *)prop);
    or_method_replace(NO, clazz, setterSEL, result->function_imp, typeEncoding);
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
//    if (!exprOrStatement) {
//        return;
//    }
//    Class exprOrStatementClass = [exprOrStatement class];
//    if (exprOrStatementClass == [ORValueNode class]) {
//        ORValueNode *expr = (ORValueNode *)exprOrStatement;
//        switch (expr.value_type) {
//            case OCValueDictionary:{
//                for (NSArray *kv in expr.value) {
//                    ORNode *keyExp = kv.firstObject;
//                    ORNode *valueExp = kv.firstObject;
//                    copy_undef_var(keyExp, chain, fromScope, destScope);
//                    copy_undef_var(valueExp, chain, fromScope, destScope);
//                }
//                break;
//            }
//            case OCValueArray:{
//                for (ORNode *valueExp in expr.value) {
//                    copy_undef_var(valueExp, chain, fromScope, destScope);
//                }
//                break;
//            }
//            case OCValueSelf:
//            case OCValueSuper:{
//                destScope.instance = fromScope.instance;
//                break;
//            }
//            case OCValueVariable:{
//                NSString *identifier = expr.value;
//                if (![chain isInChain:identifier]) {
//                   or_value value = [fromScope recursiveGetValueWithIdentifier:identifier];
//                    if (value) {
//                        [destScope setValue:value withIndentifier:identifier];
//                    }
//                }
//            }
//            default:
//                break;
//        }
//    }else if (exprOrStatementClass == ORAssignNode.class) {
//        ORAssignNode *expr = (ORAssignNode *)exprOrStatement;
//        copy_undef_var(expr.value, chain, fromScope, destScope);
//        copy_undef_var(expr.expression, chain, fromScope, destScope);
//        return;
//    }else if (exprOrStatementClass == ORBinaryNode.class){
//        ORBinaryNode *expr = (ORBinaryNode *)exprOrStatement;
//        copy_undef_var(expr.left, chain, fromScope, destScope);
//        copy_undef_var(expr.right, chain, fromScope, destScope);
//        return;
//    }else if (exprOrStatementClass == ORTernaryNode.class){
//        ORTernaryNode *expr = (ORTernaryNode *)exprOrStatement;
//        copy_undef_var(expr.expression, chain, fromScope, destScope);
//        copy_undef_vars(expr.values, chain, fromScope, destScope);
//        return;
//    }else if (exprOrStatementClass == ORUnaryNode.class){
//        ORUnaryNode *expr = (ORUnaryNode *)exprOrStatement;
//        copy_undef_var(expr.value, chain, fromScope, destScope);
//        return;
//
//    }else if (exprOrStatementClass == ORFunctionCall.class){
//        ORFunctionCall *expr = (ORFunctionCall *)exprOrStatement;
//        copy_undef_var(expr.caller, chain, fromScope, destScope);
//        copy_undef_vars(expr.expressions, chain, fromScope, destScope);
//        return;
//    }else if (exprOrStatementClass == ORSubscriptNode.class){
//        ORSubscriptNode *expr = (ORSubscriptNode *)exprOrStatement;
//        copy_undef_var(expr.caller, chain, fromScope, destScope);
//        copy_undef_var(expr.keyExp, chain, fromScope, destScope);
//        return;
//
//    }else if (exprOrStatementClass == ORMethodCall.class){
//        ORMethodCall *expr = (ORMethodCall *)exprOrStatement;
//        copy_undef_var(expr.caller, chain, fromScope, destScope);
//        copy_undef_vars(expr.values, chain, fromScope, destScope);
//        return;
//
//    }else if (exprOrStatementClass == ORFunctionNode.class){
//        ORFunctionNode *expr = (ORFunctionNode *)exprOrStatement;
//        ORFunctionDeclNode *funcDeclare = expr.declare;
//        MFVarDeclareChain *funcChain = [MFVarDeclareChain varDeclareChainWithNext:chain];
//        NSArray <ORDeclaratorNode *>*params = funcDeclare.params;
//        for (ORDeclaratorNode *param in params) {
//            [funcChain addIndentifer:param.var.varname];
//        }
//        copy_undef_var(expr.scopeImp, funcChain, fromScope, destScope);
//        return;
//    }else if (exprOrStatementClass == ORBlockNode.class){
//        ORBlockNode *scopeImp = (ORBlockNode *)exprOrStatement;
//        MFVarDeclareChain *scopeChain = [MFVarDeclareChain varDeclareChainWithNext:chain];
//        copy_undef_vars(scopeImp.statements, scopeChain, fromScope, destScope);
//        return;
//    }
//    else if (exprOrStatementClass == ORInitDeclaratorNode.class){
//        ORInitDeclaratorNode *expr = (ORInitDeclaratorNode *)exprOrStatement;
//        NSString *name = expr.declarator.var.varname;
//        [chain addIndentifer:name];
//        copy_undef_var(expr.expression, chain, fromScope, destScope);
//        return;
//
//    }else if (exprOrStatementClass == ORIfStatement.class){
//        ORIfStatement *ifStatement = (ORIfStatement *)exprOrStatement;
//        copy_undef_var(ifStatement.condition, chain, fromScope, destScope);
//        MFVarDeclareChain *ifChain = [MFVarDeclareChain varDeclareChainWithNext:chain];
//        copy_undef_var(ifStatement.scopeImp, ifChain, fromScope, destScope);
//        copy_undef_var(ifStatement.last, chain, fromScope, destScope);
//        return;
//    }else if (exprOrStatementClass == ORSwitchStatement.class){
//        ORSwitchStatement *swithcStatement = (ORSwitchStatement *)exprOrStatement;
//        copy_undef_var(swithcStatement.value, chain, fromScope, destScope);
//        copy_undef_vars(swithcStatement.cases, chain, fromScope, destScope);
//        MFVarDeclareChain *defChain = [MFVarDeclareChain varDeclareChainWithNext:chain];
//        copy_undef_vars(swithcStatement.cases, defChain, fromScope, destScope);
//        return;
//
//    }else if (exprOrStatementClass == ORCaseStatement.class){
//        ORCaseStatement *caseStatement = (ORCaseStatement *)exprOrStatement;
//        copy_undef_var(caseStatement.value, chain, fromScope, destScope);
//        MFVarDeclareChain *caseChain = [MFVarDeclareChain varDeclareChainWithNext:chain];
//        copy_undef_var(caseStatement.scopeImp, caseChain, fromScope, destScope);
//        return;
//    }else if (exprOrStatementClass == ORForStatement.class){
//        ORForStatement *forStatement = (ORForStatement *)exprOrStatement;
//        MFVarDeclareChain *forChain = [MFVarDeclareChain varDeclareChainWithNext:chain];
//        copy_undef_vars(forStatement.varExpressions, forChain, fromScope, destScope);
//        copy_undef_var(forStatement.condition, forChain, fromScope, destScope);
//        copy_undef_vars(forStatement.expressions, forChain, fromScope, destScope);
//        copy_undef_var(forStatement.scopeImp, forChain, fromScope, destScope);
//    }else if (exprOrStatementClass == ORForInStatement.class){
//        ORForInStatement *forEachStatement = (ORForInStatement *)exprOrStatement;
//        MFVarDeclareChain *forEachChain = [MFVarDeclareChain varDeclareChainWithNext:chain];
//        copy_undef_var(forEachStatement.expression, forEachChain, fromScope, destScope);
//        copy_undef_var(forEachStatement.value, forEachChain, fromScope, destScope);
//        copy_undef_var(forEachStatement.scopeImp, forEachChain, fromScope, destScope);
//    }else if (exprOrStatementClass == ORWhileStatement.class){
//        ORWhileStatement *whileStatement = (ORWhileStatement *)exprOrStatement;
//        copy_undef_var(whileStatement.condition, chain, fromScope, destScope);
//        MFVarDeclareChain *whileChain = [MFVarDeclareChain varDeclareChainWithNext:chain];
//        copy_undef_var(whileStatement.scopeImp, whileChain, fromScope, destScope);
//    }else if (exprOrStatementClass == ORDoWhileStatement.class){
//        ORDoWhileStatement *doWhileStatement = (ORDoWhileStatement *)exprOrStatement;
//        copy_undef_var(doWhileStatement.condition, chain, fromScope, destScope);
//        MFVarDeclareChain *doWhileChain = [MFVarDeclareChain varDeclareChainWithNext:chain];
//        copy_undef_var(doWhileStatement.scopeImp, doWhileChain, fromScope, destScope);
//    }else if (exprOrStatementClass == ORControlStatNode.class){
//        ORControlStatNode *returnStatement = (ORControlStatNode *)exprOrStatement;
//        copy_undef_var(returnStatement.expression, chain, fromScope, destScope);
//    }
}


@implementation ORPropertyNode( Execute)
- (const objc_property_attribute_t *)propertyAttributes{
    NSValue *value = objc_getAssociatedObject(self, mf_propKey(@"propertyAttributes"));
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
    NSValue *value = objc_getAssociatedObject(self, mf_propKey(@"propertyAttributes"));
    objc_property_attribute_t **attributes = [value pointerValue];
    if (attributes != NULL) {
        free(attributes);
    }
}
- (objc_property_attribute_t )typeAttribute{
    objc_property_attribute_t type = {"T", self.var.symbol.decl.typeEncode };
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


#import <objc/runtime.h>


void evalEmptyNode(ORInterpreter *inter, ORThreadContext *ctx, MFScopeChain *scope, ORNode *node){
    return;
}
void evalTypeNode(ORInterpreter *inter, ORThreadContext *ctx, MFScopeChain *scope, ORTypeNode *node){
    return;
}
void evalVariableNode(ORInterpreter *inter, ORThreadContext *ctx, MFScopeChain *scope, ORVariableNode *node){
    return;
}
void evalDeclaratorNode(ORInterpreter *inter, ORThreadContext *ctx, MFScopeChain *scope, ORDeclaratorNode *node){
    return;
}
void evalFunctionDeclNode(ORInterpreter *inter, ORThreadContext *ctx, MFScopeChain *scope, ORFunctionDeclNode *node){
    return;
}
void evalCArrayDeclNode(ORInterpreter *inter, ORThreadContext *ctx, MFScopeChain *scope, ORCArrayDeclNode *node){
    eval(inter, ctx, scope, node.capacity);
or_value value = *[ctx opStackPop];
    if (![node.capacity isKindOfClass:[ORIntegerValue class]]
        && [node.capacity isKindOfClass:[ORCArrayDeclNode class]] == NO) {
        ORIntegerValue *integerValue = [ORIntegerValue new];
        integerValue.value = (*(or_value_box *)value.pointer).longlongValue;
        node.capacity = integerValue;
    }
    return;
}
void evalBlockNode(ORInterpreter *inter, ORThreadContext *ctx, MFScopeChain *scope, ORBlockNode *node){
    //{ }
    for (id statement in node.statements) {
        eval(inter, ctx, scope, statement);
        if (ctx->flow_flag != ORControlFlowFlagNormal) {
            return;
        }
    }
    return;
}
void evalConstantValue(ORInterpreter *inter, ORThreadContext *ctx, ORNode *node){
    ocDecl *decl = node.symbol.decl;
    void *value = inter->constants + decl.offset;
    or_value result = or_value_create(decl.typeEncode, value);
    [ctx opStackPush:result];
    return;
}
void evalValueNode(ORInterpreter *inter, ORThreadContext *ctx, MFScopeChain *scope, ORValueNode *node){
    switch (node.value_type) {
        case OCValueString:{
            void *buffer = inter->constants + node.symbol.decl.offset;
            [ctx opStackPush:or_Object_value([NSString stringWithUTF8String:buffer])];
            return;
        }
        case OCValueCString:{
            void *buffer = inter->constants + node.symbol.decl.offset;
            or_value value = or_CString_value(buffer);
            [ctx opStackPush:value];
            return;
        }
        case OCValueSelector:{
            void *buffer = inter->constants + node.symbol.decl.offset;
            [ctx opStackPush:or_SEL_value(NSSelectorFromString([NSString stringWithUTF8String:buffer]))];
            return;
        }
        case OCValueProtocol:{
            void *buffer = inter->constants + node.symbol.decl.offset;
            [ctx opStackPush:or_Object_value(NSProtocolFromString([NSString stringWithUTF8String:buffer]))];
            return;
        }
        case OCValueSelf:
        {
            void *result = [ctx seekLocalVar:node.symbol.decl.offset];
            or_value value = or_value_create(node.symbol.decl.typeEncode, result);
            [ctx opStackPush:value];
            break;
        }
        case OCValueSuper:
        {
            void *result = [ctx seekLocalVar:node.symbol.decl.offset];
            or_value value = or_value_create(node.symbol.decl.typeEncode, result);
            [ctx opStackPush:value];
            break;
        }
        case OCValueVariable:{
            if (node.symbol.decl->isClassRef) {
                Class class = NSClassFromString(node.value);
                if (class) {
                    [ctx opStackPush:or_Class_value(class)];
                    return;
                }
    #if DEBUG
                if (node.value) NSLog(@"\n---------OCRunner Warning---------\n"
                                      @"Can't find object or class: %@\n"
                                      @"-----------------------------------", node.value);
    #endif
                return;
            }
            void *result = [ctx seekLocalVar:node.symbol.decl.offset];
            or_value value = or_value_create(node.symbol.decl.typeEncode, result);
            [ctx opStackPush:value];
            return;
        }
        case OCValueDictionary:{
            NSMutableArray *exps = node.value;
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            for (NSMutableArray <ORNode *>*kv in exps) {
                ORNode *keyExp = kv.firstObject;
                ORNode *valueExp = kv.lastObject;
                eval(inter, ctx, scope, keyExp);
                eval(inter, ctx, scope, valueExp);
                or_value valueValue = *[ctx opStackPop];
                or_value keyValue = *[ctx opStackPop];
                id key = (__bridge id) *keyValue.pointer;
                id value = (__bridge id) *valueValue.pointer;
                if (key && value){
                    dict[key] = value;
                }else{
                    NSLog(@"OCRunner Error: the key %@ or value %@ of NSDictionary can't be nil", key?:@"", value?:@"");
                }
            }
            [ctx opStackPush:or_Object_value([dict copy])];
            return;
        }
        case OCValueArray:{
            NSMutableArray *exps = node.value;
            NSMutableArray *array = [NSMutableArray array];
            for (ORNode *exp in exps) {
                eval(inter, ctx, scope, exp);
                or_value valueValue = *[ctx opStackPop];
                id value = (__bridge id) *valueValue.pointer;
                if (value) {
                    [array addObject:value];
                }else{
                    NSLog(@"OCRunner Error: the value of NSArray can't be nil, %@", array);
                }
            }
            [ctx opStackPush:or_Object_value([array copy])];
            return;
        }
        case OCValueNSNumber:{
            eval(inter, ctx, scope, node.value);
            or_value value = *[ctx opStackPop];
            NSNumber *result = nil;
            UnaryExecuteBaseType(result, @, value);
            [ctx opStackPush:or_Object_value(result)];
            return;
        }
        case OCValueNil:{
            [ctx opStackPush:or_Object_value(nil)];
            return;
        }
        case OCValueNULL:{
            [ctx opStackPush:or_nullValue()];
            return;
        }
        default:
            break;
    }

}
void evalIntegerValue(ORInterpreter *inter, ORThreadContext *ctx, MFScopeChain *scope, ORIntegerValue *node){
    evalConstantValue(inter, ctx, node);
}
void evalUIntegerValue(ORInterpreter *inter, ORThreadContext *ctx, MFScopeChain *scope, ORUIntegerValue *node){
    evalConstantValue(inter, ctx, node);
}
void evalDoubleValue(ORInterpreter *inter, ORThreadContext *ctx, MFScopeChain *scope, ORDoubleValue *node){
    evalConstantValue(inter, ctx, node);
}
void evalBoolValue(ORInterpreter *inter, ORThreadContext *ctx, MFScopeChain *scope, ORBoolValue *node){
    evalConstantValue(inter, ctx, node);
}
void evalMethodCall(ORInterpreter *inter, ORThreadContext *ctx, MFScopeChain *scope, ORMethodCall *node){
    if ([node.caller isKindOfClass:[ORMethodCall class]]) {
        [(ORMethodCall *)node.caller setIsAssignedValue:node.isAssignedValue];
    }
    eval(inter, ctx, scope, node.caller);
    or_value variable = *[ctx opStackPop];
//    if (*variable.typeencode == OCTypeStruct || *variable.typeencode == OCTypeUnion) {
//        if ([node.names.firstObject hasPrefix:@"set"]) {
//            NSString *setterName = node.names.firstObject;
//            ORNode *valueExp = node.values.firstObject;
//            NSString *fieldKey = [setterName substringFromIndex:3];
//            NSString *first = [[fieldKey substringToIndex:1] lowercaseString];
//            NSString *other = setterName.length > 1 ? [fieldKey substringFromIndex:1] : @"";
//            fieldKey = [NSString stringWithFormat:@"%@%@", first, other];
//            eval(inter, ctx, scope, valueExp);
//            or_value value = *[ctx opStackPop];
//            if (variable.type == OCTypeStruct) {
//                [variable setFieldWithValue:value forKey:fieldKey];
//            }else{
//                [variable setUnionFieldWithValue:value forKey:fieldKey];
//            }
//            return;
//        }else{
//            if (variable.type == OCTypeStruct) {
//                if (node.isAssignedValue) {
//                    return [variable fieldNoCopyForKey:node.names.firstObject];
//                }else{
//                    return [variable fieldForKey:node.names.firstObject];
//                }
//            }else{
//                return [variable unionFieldForKey:node.names.firstObject];;
//            }
//            return;
//        }
//    }
    id instance = (__bridge  id)*variable.pointer;
    SEL sel = NSSelectorFromString(node.selectorName);
    unichar argsMem[node.values.count * sizeof(or_value)];
    NSInteger inputArgCount = node.values.count + 2;
    or_value *args[inputArgCount];
    or_value self_value = or_Object_value(instance);
    or_value sel_value = or_SEL_value(sel);
    args[0] = &self_value;
    args[1] = &sel_value;
    for (int i = 0; i < node.values.count; i++) {
        eval(inter, ctx, scope, node.values[i]);
        or_value arg = *[ctx opStackPop];
        void *dst = argsMem + i * sizeof(or_value);
        memcpy(dst, &arg, sizeof(or_value));
        args[i + 2] = dst;
    }
    // instance为nil时，依然要执行参数相关的表达式
    if ([node.caller isKindOfClass:[ORValueNode class]]) {
        if (node.caller.symbol.decl->isSuper) {
//            return invoke_sueper_values(instance, sel, argValues);
        }
    }
    if (instance == nil) {
        return;
    }
    
    //如果在方法缓存表的中已经找到相关方法，直接调用，省去一次中间类型转换问题。优化性能，在方法递归时，调用耗时减少33%，0.15s -> 0.10s
    BOOL isClassMethod = object_isClass(instance);
    Class class = isClassMethod ? objc_getMetaClass(class_getName(instance)) : [instance class];
    MFMethodMapTableItem *map = [[MFMethodMapTable shareInstance] getMethodMapTableItemWith:class classMethod:isClassMethod sel:sel];
    if (map) {
        [ctx enter];
        for (int i = 0; i < inputArgCount; i++) {
            [ctx pushLocalVar:args[i]->pointer size:or_value_mem_size(args[i])];
        }
        eval(inter, ctx, scope, map.methodImp);
        [ctx exit];
        return;
    }
    NSMethodSignature *sig = [instance methodSignatureForSelector:sel];
    if (sig == nil) {
        NSLog(@"OCRunner Error: %@ Unrecognized Selector %@", instance, node.selectorName);
        return;
    }
    NSUInteger argCount = [sig numberOfArguments];
    //解决多参数调用问题
    if (inputArgCount > argCount && sig != nil) {
        or_value_create([sig methodReturnType], NULL);
        or_value result = *[ctx opStackPop];
        void *msg_send = &objc_msgSend;
//        invoke_functionPointer(msg_send, methodArgs, result, argCount);
        [ctx opStackPush:result];
        return;
    }else{
        void *retValuePointer = alloca([sig methodReturnLength]);
        char *returnType = (char *)[sig methodReturnType];
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:sig];
        invocation.target = instance;
        invocation.selector = sel;
        for (NSUInteger i = 2; i < argCount; i++) {
            or_value *value = args[i];
            // 基础类型转换
            or_value_set_typeencode(value, [sig getArgumentTypeAtIndex:i]);
            [invocation setArgument:value->pointer atIndex:i];
        }
        // func replaceIMP execute
        [invocation invoke];
        returnType = removeTypeEncodingPrefix(returnType);
        if (*returnType == 'v') {
            return;
        }
        [invocation getReturnValue:retValuePointer];;
        // 针对一下方法调用，需要和CF一样，最终都要release. 与JSPatch和Mango中的__bridge_transfer效果相同
//        if (sel == @selector(alloc) || sel == @selector(new)||
//            sel == @selector(copy) || sel == @selector(mutableCopy)) {
//            CFRelease(*(void **)retValuePointer);
//        }
        [ctx opStackPush:or_value_create(returnType, retValuePointer)];
        return;
    }
}
void evalFunctionCall(ORInterpreter *inter, ORThreadContext *ctx, MFScopeChain *scope, ORFunctionCall *node){
    NSUInteger argCount = node.expressions.count;
    unichar argsMem[argCount * sizeof(or_value)];
    or_value *args[argCount];
    for (int i = 0; i < argCount; i++) {
        eval(inter, ctx, scope, node.expressions[i]);
        or_value arg = *[ctx opStackPop];
        void *dst = argsMem + i * sizeof(or_value);
        memcpy(dst, &arg, sizeof(or_value));
        args[i] = dst;
    }
    if ([node.caller isKindOfClass:[ORMethodCall class]]
        && [(ORMethodCall *)node.caller methodOperator] == MethodOpretorDot){
        // TODO: 调用block
        // make.left.equalTo(xxxx);
        eval(inter, ctx, scope, (ORMethodCall *)node.caller);
        or_value value = *[ctx opStackPop];
        invoke_MFBlockValue(ctx, value, args, argCount);
        return;
    }
    //TODO: 递归函数优化, 优先查找全局函数
    id functionImp = [[ORGlobalFunctionTable shared] getFunctionNodeWithName:node.caller.value];
    if ([functionImp isKindOfClass:[ORFunctionNode class]]){
        // global function calll
        [ctx enter];
        for (int i = 0; i < argCount; i++) {
            [ctx pushLocalVar:args[i]->pointer size:or_value_mem_size(args[i])];
        }
        eval(inter, ctx, scope, (ORFunctionNode *)functionImp);
        [ctx exit];
        return;
    }else if([functionImp isKindOfClass:[ORSearchedFunction class]]) {
        // 调用系统函数
//        or_value result = nil;
//        [ORArgsStack push:args];
//        or_value result = [(ORSearchedFunction *)functionImp execute:scope];
//        return result;
    }else{
//        or_value blockValue = [scope recursiveGetValueWithIdentifier:node.caller.value];
//        //调用block
//        if (blockValue.isBlockValue) {
//            return invoke_MFBlockValue(blockValue, args);
//        //调用函数指针 int (*xxx)(int a ) = &x;  xxxx();
//        }else if (blockValue.funDecl) {
//            ORSearchedFunction *function = [ORSearchedFunction functionWithName:blockValue.funDecl.var.varname];
//            while (blockValue.pointerCount > 1) {
//                blockValue.pointerCount--;
//            }
//            function.funPair = blockValue.funDecl;
//            function.pointer = blockValue->realBaseValue.pointerValue;
//            [ORArgsStack push:args];
//            eval(inter, ctx, scope, function);
//        }
    }
    return;

}
void evalFunctionNode(ORInterpreter *inter, ORThreadContext *ctx, MFScopeChain *scope, ORFunctionNode *node){
    // C函数声明执行, 向全局作用域注册函数
     if ([ctx isEmpty]
         && node.declare.var.varname
         && node.declare.var.ptCount == 0) {
         NSString *funcName = node.declare.var.varname;
         // NOTE: 恢复后，再执行时，应该覆盖旧的实现
         [[ORGlobalFunctionTable shared] setFunctionNode:node WithName:funcName];
         ctx->flow_flag = ORControlFlowFlagNormal;
         return;
     }
     MFScopeChain *current = [MFScopeChain scopeChainWithNext:scope];
     if (node.declare && node.declare.var.isBlock) {
         // xxx = ^void (int x){ }, block作为值
         MFBlock *manBlock = [[MFBlock alloc] init];
         manBlock.func = [node convertToNormalFunctionImp];
         MFScopeChain *blockScope = [MFScopeChain scopeChainWithNext:[MFScopeChain topScope]];
         copy_undef_var(node, [MFVarDeclareChain new], scope, blockScope);
         manBlock.outScope = blockScope;
         manBlock.retType = manBlock.func.declare;
         manBlock.paramTypes = manBlock.func.declare.params;
         __autoreleasing id ocBlock = [manBlock ocBlock];
         ctx->flow_flag = ORControlFlowFlagNormal;
         CFRelease((__bridge void *)ocBlock);
         [ctx opStackPush:or_Object_value(ocBlock)];
         return;
     }
     [ORCallFrameStack pushFunctionCall:node scope:current];
     eval(inter, ctx, current, node.scopeImp);
     ctx->flow_flag = ORControlFlowFlagNormal;
     [ORCallFrameStack pop];
     return;
}
void evalSubscriptNode(ORInterpreter *inter, ORThreadContext *ctx, MFScopeChain *scope, ORSubscriptNode *node){
//    or_value bottomValue = eval(inter, ctx, scope, node.keyExp);
//    or_value arrValue = eval(inter, ctx, scope, node.caller);
//    return [arrValue subscriptGetWithIndex:bottomValue];
}
void evalAssignNode(ORInterpreter *inter, ORThreadContext *ctx, MFScopeChain *scope, ORAssignNode *node){
    ORNode *resultExp;
#define SetResultExpWithBinaryOperator(type)\
    ORBinaryNode *exp = [ORBinaryNode new];\
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
        case AstEnumValueNode:
        case AstEnumUnaryNode:
        {
            eval(inter, ctx, scope, node.value);
or_value left = *[ctx opStackPop];
            eval(inter, ctx, scope, resultExp);
or_value right = *[ctx opStackPop];
            or_value_write_to(right, left.pointer, left.typeencode);
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
            eval(inter, ctx, scope, setCaller);
            break;
        }
        case AstEnumSubscriptNode:
        {
//            or_value resultValue = eval(inter, ctx, scope, resultExp);
//            ORSubscriptNode *subExp = (ORSubscriptNode *)node.value;
//            or_value caller = eval(inter, ctx, scope, subExp.caller);
//            or_value indexValue = eval(inter, ctx, scope, subExp.keyExp);
//            [caller subscriptSetValue:resultValue index:indexValue];
        }
        default:
            break;
    }
    ctx->flow_flag = ORControlFlowFlagNormal;
    return;

}
void evalInitDeclaratorNode(ORInterpreter *inter, ORThreadContext *ctx, MFScopeChain *scope, ORInitDeclaratorNode *node){
    BOOL staticVar = node.declarator.type.modifier & DeclarationModifierStatic;
    if ([node.declarator.var isKindOfClass:[ORCArrayDeclNode class]]) {
        eval(inter, ctx, scope, node.declarator.var);
    }
    void (^initializeBlock)(void) = ^void {
        ocDecl *decl = node.declarator.symbol.decl;
        or_value value;
        if (node.expression) {
            eval(inter, ctx, scope, node.expression);
            value = *[ctx opStackPop];
//            value.modifier = decl.declModifer;
            or_value_set_typeencode(&value, decl.typeEncode);
//            value.typeEncode = decl.typeEncode;
        }else{
            value = or_value_create(decl.typeEncode, NULL);
//            value.modifier = decl.declModifer;
//            if (isObjectWithTypeEncode(value.typeencode)
//                && NSClassFromString(value.typeName) == nil
//                && ![value.typeName isEqualToString:@"id"]) {
//                NSString *reason = [NSString stringWithFormat:@"Unknown Type Identifier: %@",value.typeName];
//                @throw [NSException exceptionWithName:@"OCRunner" reason:reason userInfo:nil];
//            }
        }
//        if (decl.isFunction)
//            value.funDecl = (ORFunctionDeclNode *)node.declarator;
        if (scope == [MFScopeChain topScope] || scope.next == [MFScopeChain topScope]) {
            MFValue *val = [MFValue valueWithTypeEncode:value.typeencode pointer:value.pointer];
            [scope setValue:val withIndentifier:node.declarator.var.varname];
        }
        [ctx pushLocalVar:value.pointer size:or_value_mem_size(&value)];
        return;
    };
    if (staticVar) {
//        NSString *key = [NSString stringWithFormat:@"%p",(void *)node];
//        or_value value = [[MFStaticVarTable shareInstance] getStaticVarValueWithKey:key];
//        if (value) {
//            [scope setValue:value withIndentifier:node.declarator.var.varname];
//        }else{
//            or_value value = initializeBlock();
//            [[MFStaticVarTable shareInstance] setStaticVarValue:value withKey:key];
//        }
    }else{
        initializeBlock();
    }
    ctx->flow_flag = ORControlFlowFlagNormal;
    return;
}
void evalUnaryNode(ORInterpreter *inter, ORThreadContext *ctx, MFScopeChain *scope, ORUnaryNode *node){
    eval(inter, ctx, scope, node.value);
    or_value currentValue = *[ctx opStackPop];
    or_value cal_result;
    cal_result.typeencode = currentValue.typeencode;
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
            cal_result.box.boolValue = !or_value_isSubtantial(currentValue);
            cal_result.typeencode = OCTypeStringBOOL;
            break;
        }
        case UnaryOperatorSizeOf:{
            size_t result = 0;
            UnaryExecute(result, sizeof, currentValue);
            cal_result.box.longlongValue = result;
            cal_result.typeencode = OCTypeStringLongLong;
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
            or_value resultValue = or_value_create(currentValue.typeencode, NULL);
//            void *pointer = currentValue.pointer;
//            resultValue.pointerCount += 1;
//            resultValue.pointer = &pointer;
            [ctx opStackPush:resultValue];
            return;
        }
        case UnaryOperatorAdressValue:{
            or_value resultValue = or_value_create(currentValue.typeencode, NULL);
//            resultValue.pointerCount -= 1;
            if (node.parentNode.nodeType == AstEnumAssignNode) {
//                [resultValue setValuePointerWithNoCopy:*(void **)currentValue.pointer];
            }else{
                resultValue.pointer = *(void **)currentValue.pointer;
            }
            [ctx opStackPush:resultValue];
            return;
        }
        default:
            break;
    }
    [ctx opStackPush:cal_result];
    return;
}
BOOL OR_NO_VALUE = NO;
BOOL OR_YES_VALUE = NO;
void evalBinaryNode(ORInterpreter *inter, ORThreadContext *ctx, MFScopeChain *scope, ORBinaryNode *node){
    switch (node.operatorType) {
        case BinaryOperatorLOGIC_AND:{
            eval(inter, ctx, scope, node.left);
            or_value leftValue = *[ctx opStackPop];
            if (or_value_isSubtantial(leftValue)) {
                eval(inter, ctx, scope, node.right);
                or_value rightValue = *[ctx opStackPop];
                [ctx opStackPush:or_BOOL_value(or_value_isSubtantial(rightValue))];
                return;
            }
            [ctx opStackPush:or_BOOL_value(NO)];
            return;
        }
        case BinaryOperatorLOGIC_OR:{
            eval(inter, ctx, scope, node.left);
            or_value leftValue = *[ctx opStackPop];
            if (or_value_isSubtantial(leftValue)) {
                [ctx opStackPush:or_BOOL_value(YES)];
                return;
            }
            eval(inter, ctx, scope, node.right);
            or_value rightValue = *[ctx opStackPop];
            [ctx opStackPush:or_BOOL_value(or_value_isSubtantial(rightValue))];
            return;
        }
        default: break;
    }
    eval(inter, ctx, scope, node.left);
    eval(inter, ctx, scope, node.right);
    
    or_value rightValue = *[ctx opStackPop];
    or_value leftValue = *[ctx opStackPop];
    
    or_value cal_result;
    cal_result.typeencode = leftValue.typeencode;
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
            cal_result.typeencode = OCTypeStringBOOL;
            break;
        }
        case BinaryOperatorGT:{
            LogicBinaryOperatorExecute(leftValue, >, rightValue);
            cal_result.box.boolValue = logicResultValue;
            cal_result.typeencode = OCTypeStringBOOL;
            break;
        }
        case BinaryOperatorLE:{
            LogicBinaryOperatorExecute(leftValue, <=, rightValue);
            cal_result.box.boolValue = logicResultValue;
            cal_result.typeencode = OCTypeStringBOOL;
            break;
        }
        case BinaryOperatorGE:{
            LogicBinaryOperatorExecute(leftValue, >=, rightValue);
            cal_result.box.boolValue = logicResultValue;
            cal_result.typeencode = OCTypeStringBOOL;
            break;
        }
        case BinaryOperatorNotEqual:{
            LogicBinaryOperatorExecute(leftValue, !=, rightValue);
            cal_result.box.boolValue = logicResultValue;
            cal_result.typeencode = OCTypeStringBOOL;
            break;
        }
        case BinaryOperatorEqual:{
            LogicBinaryOperatorExecute(leftValue, ==, rightValue);
            cal_result.box.boolValue = logicResultValue;
            cal_result.typeencode = OCTypeStringBOOL;
            break;
        }
        default:
            break;
    }
    [ctx opStackPush:cal_result];
    
    return;

}
void evalTernaryNode(ORInterpreter *inter, ORThreadContext *ctx, MFScopeChain *scope, ORTernaryNode *node){
    eval(inter, ctx, scope, node.expression);
    or_value condition = *[ctx opStackPop];
    if (node.values.count == 1) { // condition ?: value
        if (or_value_isSubtantial(condition)) {
            [ctx opStackPush:condition];
            return;
        }else{
            eval(inter, ctx, scope, node.values.lastObject);
        }
    }else{ // condition ? value1 : value2
        if (or_value_isSubtantial(condition)) {
            eval(inter, ctx, scope, node.values.firstObject);
        }else{
            eval(inter, ctx, scope, node.values.lastObject);
        }
    }
}
void evalIfStatement(ORInterpreter *inter, ORThreadContext *ctx, MFScopeChain *scope, ORIfStatement *node){
    NSMutableArray *statements = [NSMutableArray array];
    ORIfStatement *ifStatement = node;
    while (ifStatement) {
        [statements insertObject:ifStatement atIndex:0];
        ifStatement = ifStatement.last;
    }
    for (ORIfStatement *statement in statements) {
        eval(inter, ctx, scope, statement.condition);
        if (or_value_isSubtantial(*[ctx opStackPop])) {
            MFScopeChain *current = [MFScopeChain scopeChainWithNext:scope];
            eval(inter, ctx, current, statement.scopeImp);
            return;
        }
    }
    if (node.condition == nil) {
        MFScopeChain *current = [MFScopeChain scopeChainWithNext:scope];
        eval(inter, ctx, current, node.scopeImp);
    }
    ctx->flow_flag = ORControlFlowFlagNormal;
    return;
}
void evalWhileStatement(ORInterpreter *inter, ORThreadContext *ctx, MFScopeChain *scope, ORWhileStatement *node){
    MFScopeChain *current = [MFScopeChain scopeChainWithNext:scope];
    while (1) {
        eval(inter, ctx, scope, node.condition);
        if (!or_value_isSubtantial(*[ctx opStackPop])) {
            break;
        }
        eval(inter, ctx, current, node.scopeImp);
        if (ctx->flow_flag == ORControlFlowFlagBreak) {
            ctx->flow_flag = ORControlFlowFlagNormal;
            break;
        }else if (ctx->flow_flag == ORControlFlowFlagContinue){
            ctx->flow_flag = ORControlFlowFlagNormal;
        }else if (ctx->flow_flag & ORControlFlowFlagReturn){
            return;
        }else if (ctx->flow_flag == ORControlFlowFlagNormal){
            
        }
    }
    ctx->flow_flag = ORControlFlowFlagNormal;
    return;
}
void evalDoWhileStatement(ORInterpreter *inter, ORThreadContext *ctx, MFScopeChain *scope, ORDoWhileStatement *node){
    MFScopeChain *current = [MFScopeChain scopeChainWithNext:scope];
    while (1) {
        eval(inter, ctx, current, node.scopeImp);
        if (ctx->flow_flag == ORControlFlowFlagBreak) {
            ctx->flow_flag = ORControlFlowFlagNormal;
            break;
        }else if (ctx->flow_flag == ORControlFlowFlagContinue){
            ctx->flow_flag = ORControlFlowFlagNormal;
        }else if (ctx->flow_flag & ORControlFlowFlagReturn){
            return;
        }else if (ctx->flow_flag == ORControlFlowFlagNormal){
            
        }
        eval(inter, ctx, scope, node.condition);
        if (!or_value_isSubtantial(*[ctx opStackPop])) {
            break;
        }
    }
    ctx->flow_flag = ORControlFlowFlagNormal;
    return;
}
void evalCaseStatement(ORInterpreter *inter, ORThreadContext *ctx, MFScopeChain *scope, ORCaseStatement *node){
    MFScopeChain *current = [MFScopeChain scopeChainWithNext:scope];
    eval(inter, ctx, current, node.scopeImp);
}
void evalSwitchStatement(ORInterpreter *inter, ORThreadContext *ctx, MFScopeChain *scope, ORSwitchStatement *node){
    eval(inter, ctx, scope, node.value);
or_value value = *[ctx opStackPop];
    BOOL hasMatch = NO;
    for (ORCaseStatement *statement in node.cases) {
        if (statement.value) {
            if (!hasMatch) {
                eval(inter, ctx, scope, statement.value);
                or_value caseValue = *[ctx opStackPop];
                LogicBinaryOperatorExecute(value, ==, caseValue);
                hasMatch = logicResultValue;
                if (!hasMatch) {
                    continue;
                }
            }
            eval(inter, ctx, scope, statement);
            if (ctx->flow_flag == ORControlFlowFlagBreak) {
                ctx->flow_flag = ORControlFlowFlagNormal;
                return;
            }else if (ctx->flow_flag == ORControlFlowFlagNormal){
                continue;
            }else{
                return;
            }
        }else{
            eval(inter, ctx, scope, statement);
            if (ctx->flow_flag == ORControlFlowFlagBreak) {
                ctx->flow_flag = ORControlFlowFlagNormal;
                return;
            }
        }
    }
    ctx->flow_flag = ORControlFlowFlagNormal;
    return;
}
void evalForStatement(ORInterpreter *inter, ORThreadContext *ctx, MFScopeChain *scope, ORForStatement *node){
    MFScopeChain *current = [MFScopeChain scopeChainWithNext:scope];
    for (ORNode *exp in node.varExpressions) {
        eval(inter, ctx, current, exp);
    }
    while (1) {
        eval(inter, ctx, scope, node.condition);
        if (!or_value_isSubtantial(*[ctx opStackPop])) {
            break;
        }
        eval(inter, ctx, current, node.scopeImp);
        if (ctx->flow_flag & ORControlFlowFlagReturn){
            return;
        }else if (ctx->flow_flag == ORControlFlowFlagBreak) {
            ctx->flow_flag = ORControlFlowFlagNormal;
            return;
        }else if (ctx->flow_flag == ORControlFlowFlagContinue){
            continue;
        }
        for (ORNode *exp in node.expressions) {
            eval(inter, ctx, (MFScopeChain *)current, exp);
        }
    }
    ctx->flow_flag = ORControlFlowFlagNormal;
    return;
}
void evalForInStatement(ORInterpreter *inter, ORThreadContext *ctx, MFScopeChain *scope, ORForInStatement *node){
    MFScopeChain *current = [MFScopeChain scopeChainWithNext:scope];
    eval(inter, ctx, current, node.value);
or_value arrayValue = *[ctx opStackPop];
    for (id element in (__bridge id)*arrayValue.pointer) {
        //TODO: 每执行一次，在作用域中重新设置一次
        node.expression.symbol.decl;
//        [current setValue:[MFValue valueWithObject:element] withIndentifier:node.expression.var.varname];
        eval(inter, ctx, current, node.scopeImp);
        if (ctx->flow_flag & ORControlFlowFlagReturn){
            return;
        }else if (ctx->flow_flag == ORControlFlowFlagBreak) {
            ctx->flow_flag = ORControlFlowFlagNormal;
            return;
        }else if (ctx->flow_flag == ORControlFlowFlagContinue){
            continue;
        }
    }
    ctx->flow_flag = ORControlFlowFlagNormal;
    return;
}
void evalControlStatNode(ORInterpreter *inter, ORThreadContext *ctx, MFScopeChain *scope, ORControlStatNode *node){
    switch (node.type) {
        case ORControlStatBreak:
        {
            ctx->flow_flag = ORControlFlowFlagBreak;
            break;
        }
        case ORControlStatContinue:
        {
            ctx->flow_flag = ORControlFlowFlagContinue;
            break;
        }
        case ORControlStatReturn:
        {
            ctx->flow_flag = ORControlFlowFlagReturn;
            if (node.expression) {
                eval(inter, ctx, scope, node.expression);
            }
            break;
        }
        default:
            break;
    }
}
void evalPropertyNode(ORInterpreter *inter, ORThreadContext *ctx, MFScopeChain *scope, ORPropertyNode *node){
    NSString *propertyName = node.var.var.varname;
    Class class = NSClassFromString([(ORClassNode *)node.parentNode className]);
    class_replaceProperty(class, [propertyName UTF8String], node.propertyAttributes, 3);
    MFPropertyMapTableItem *propItem = [[MFPropertyMapTableItem alloc] initWithClass:class property:node];
    [[MFPropertyMapTable shareInstance] addPropertyMapTableItem:propItem];
    replace_getter_method(class, node);
    replace_setter_method(class, node);
    return;
}
void evalMethodDeclNode(ORInterpreter *inter, ORThreadContext *ctx, MFScopeChain *scope, ORMethodDeclNode *node){
    return;
}
void evalMethodNode(ORInterpreter *inter, ORThreadContext *ctx, MFScopeChain *scope, ORMethodNode *node){
    MFScopeChain *current = [MFScopeChain scopeChainWithNext:scope];
//    [ORCallFrameStack pushMethodCall:node instance:scope.instance];
    eval(inter, ctx, current, node.scopeImp);
    ctx->flow_flag = ORControlFlowFlagNormal;
//    [ORCallFrameStack pop];
    return;
}
void evalClassNode(ORInterpreter *inter, ORThreadContext *ctx, MFScopeChain *scope, ORClassNode *node){
    Class clazz = NSClassFromString(node.className);
    MFScopeChain *current = [MFScopeChain scopeChainWithNext:scope];
    if (!clazz) {
        Class superClass = NSClassFromString(node.superClassName);
        if (!superClass) {
            // 针对仅实现 @implementation xxxx @end 的类, 默认继承NSObjectt
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
    }
    // 添加Class变量到作用域
    [current setValue:[MFValue valueWithClass:clazz] withIndentifier:@"Class"];
    // 先添加属性
    for (ORPropertyNode *property in node.properties) {
        eval(inter, ctx, current, property);
    }
    // 在添加方法，这样可以解决属性的懒加载不生效的问题
    for (ORMethodNode *method in node.methods) {
        replace_method(clazz, method);
    }
    return;
}
void evalProtocolNode(ORInterpreter *inter, ORThreadContext *ctx, MFScopeChain *scope, ORProtocolNode *node){
//    if (NSProtocolFromString(node.protcolName) != nil) {
//        [ctx opStackPush:[MFValue voidValue]];
return;
//    }
//    Protocol *protocol = objc_allocateProtocol(node.protcolName.UTF8String);
//    for (NSString *name in node.protocols) {
//        Protocol *superP = NSProtocolFromString(name);
//        protocol_addProtocol(protocol, superP);
//    }
//    for (ORPropertyNode *prop in node.properties) {
//        protocol_addProperty(protocol, prop.var.var.varname.UTF8String, prop.propertyAttributes, 3, NO, YES);
//    }
//    for (ORMethodDeclNode *declare in node.methods) {
//        const char *typeEncoding = declare.returnType.typeEncode;
//        typeEncoding = mf_str_append(typeEncoding, "@:"); //add self and _cmd
//        for (ORDeclaratorNode *pair in declare.parameters) {
//            const char *paramTypeEncoding = pair.typeEncode;
//            const char *beforeTypeEncoding = typeEncoding;
//            typeEncoding = mf_str_append(typeEncoding, paramTypeEncoding);
//            free((void *)beforeTypeEncoding);
//        }
//        protocol_addMethodDescription(protocol, NSSelectorFromString(declare.selectorName), typeEncoding, NO, !declare.isClassMethod);
//    }
//    objc_registerProtocol(protocol);
    return;
}
void evalStructStatNode(ORInterpreter *inter, ORThreadContext *ctx, MFScopeChain *scope, ORStructStatNode *node){
    return;
}
void evalUnionStatNode(ORInterpreter *inter, ORThreadContext *ctx, MFScopeChain *scope, ORUnionStatNode *node){
    return;
}
void evalEnumStatNode(ORInterpreter *inter, ORThreadContext *ctx, MFScopeChain *scope, OREnumStatNode *node){
    return;
}
void evalTypedefStatNode(ORInterpreter *inter, ORThreadContext *ctx, MFScopeChain *scope, ORTypedefStatNode *node){
    return;
}

void eval(ORInterpreter *inter, ORThreadContext *ctx, MFScopeChain *scope, ORNode *node){
    switch (node.nodeType) {
        case AstEnumEmptyNode:{
            evalEmptyNode(inter, ctx, scope, node);
            break;
        }
        case AstEnumTypeNode:{
            evalTypeNode(inter, ctx, scope, node);
            break;
        }
        case AstEnumVariableNode:{
            evalVariableNode(inter, ctx, scope, node);
            break;
        }
        case AstEnumDeclaratorNode:{
            evalDeclaratorNode(inter, ctx, scope, node);
            break;
        }
        case AstEnumFunctionDeclNode:{
            evalFunctionDeclNode(inter, ctx, scope, node);
            break;
        }
        case AstEnumCArrayDeclNode:{
            evalCArrayDeclNode(inter, ctx, scope, node);
            break;
        }
        case AstEnumBlockNode:{
            evalBlockNode(inter, ctx, scope, node);
            break;
        }
        case AstEnumValueNode:{
            evalValueNode(inter, ctx, scope, node);
            break;
        }
        case AstEnumIntegerValue:{
            evalIntegerValue(inter, ctx, scope, node);
            break;
        }
        case AstEnumUIntegerValue:{
            evalUIntegerValue(inter, ctx, scope, node);
            break;
        }
        case AstEnumDoubleValue:{
            evalDoubleValue(inter, ctx, scope, node);
            break;
        }
        case AstEnumBoolValue:{
            evalBoolValue(inter, ctx, scope, node);
            break;
        }
        case AstEnumMethodCall:{
            evalMethodCall(inter, ctx, scope, node);
            break;
        }
        case AstEnumFunctionCall:{
            evalFunctionCall(inter, ctx, scope, node);
            break;
        }
        case AstEnumFunctionNode:{
            evalFunctionNode(inter, ctx, scope, node);
            break;
        }
        case AstEnumSubscriptNode:{
            evalSubscriptNode(inter, ctx, scope, node);
            break;
        }
        case AstEnumAssignNode:{
            evalAssignNode(inter, ctx, scope, node);
            break;
        }
        case AstEnumInitDeclaratorNode:{
            evalInitDeclaratorNode(inter, ctx, scope, node);
            break;
        }
        case AstEnumUnaryNode:{
            evalUnaryNode(inter, ctx, scope, node);
            break;
        }
        case AstEnumBinaryNode:{
            evalBinaryNode(inter, ctx, scope, node);
            break;
        }
        case AstEnumTernaryNode:{
            evalTernaryNode(inter, ctx, scope, node);
            break;
        }
        case AstEnumIfStatement:{
            evalIfStatement(inter, ctx, scope, node);
            break;
        }
        case AstEnumWhileStatement:{
            evalWhileStatement(inter, ctx, scope, node);
            break;
        }
        case AstEnumDoWhileStatement:{
            evalDoWhileStatement(inter, ctx, scope, node);
            break;
        }
        case AstEnumCaseStatement:{
            evalCaseStatement(inter, ctx, scope, node);
            break;
        }
        case AstEnumSwitchStatement:{
            evalSwitchStatement(inter, ctx, scope, node);
            break;
        }
        case AstEnumForStatement:{
            evalForStatement(inter, ctx, scope, node);
            break;
        }
        case AstEnumForInStatement:{
            evalForInStatement(inter, ctx, scope, node);
            break;
        }
        case AstEnumControlStatNode:{
            evalControlStatNode(inter, ctx, scope, node);
            break;
        }
        case AstEnumPropertyNode:{
            evalPropertyNode(inter, ctx, scope, node);
            break;
        }
        case AstEnumMethodDeclNode:{
            evalMethodDeclNode(inter, ctx, scope, node);
            break;
        }
        case AstEnumMethodNode:{
            evalMethodNode(inter, ctx, scope, node);
            break;
        }
        case AstEnumClassNode:{
            evalClassNode(inter, ctx, scope, node);
            break;
        }
        case AstEnumProtocolNode:{
            evalProtocolNode(inter, ctx, scope, node);
            break;
        }
        case AstEnumStructStatNode:{
            evalStructStatNode(inter, ctx, scope, node);
            break;
        }
        case AstEnumUnionStatNode:{
            evalUnionStatNode(inter, ctx, scope, node);
            break;
        }
        case AstEnumEnumStatNode:{
            evalEnumStatNode(inter, ctx, scope, node);
            break;
        }
        case AstEnumTypedefStatNode:{
            evalTypedefStatNode(inter, ctx, scope, node);
            break;
        }
        default:
            break;
    }
    return;
}
