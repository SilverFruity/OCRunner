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
#import "or_value.h"
#import "ThreadContext.hpp"

void evalGetPropertyWithIvar(ThreadContext *ctx, ocSymbol *symbol){
    
    id instance = (__bridge id)*(void **)ctx->seek_localvar(0);
    NSString *propName = [symbol.name substringToIndex:1];
    MFValue *propValue = objc_getAssociatedObject(instance, mf_propKey(propName));
    if (!propValue) {
        ctx->op_stack_push(or_value_create(symbol.decl.typeEncode, NULL));
        
        ctx->op_stack_push( or_value_create(symbol.decl.typeEncode, NULL));
        return;
    }
    ctx->op_stack_push( or_value_create(symbol.decl.typeEncode, propValue.pointer));
}
void evalSetPropertyWithIvar(ThreadContext *ctx, ocSymbol *symbol, or_value *value){
    id instance = (__bridge id)*(void **)ctx->seek_localvar( 0);
    NSString *propName = [symbol.name substringToIndex:1];
    ocDecl *decl = symbol.decl;
    MFValue *result = [[MFValue alloc] initTypeEncode:decl.typeEncode pointer:value->pointer];
    if ((decl.propModifer & MFPropertyModifierMemMask) == MFPropertyModifierMemWeak) {
        result.modifier = DeclarationModifierWeak;
    }
    objc_AssociationPolicy associationPolicy = mf_AssociationPolicy_with_PropertyModifier(decl.propModifer);
    objc_setAssociatedObject(instance, mf_propKey(propName), result, associationPolicy);
}

static void invoke_MFBlockValue(ThreadContext *ctx, or_value blockValue, or_value **args, NSUInteger argCount){
    id block = (__bridge id)*blockValue.pointer;
#if DEBUG
//    if (block == nil) {
//        NSLog(@"%@",[ORCallFrameStack history]);
//    }
#endif
    assert(block != nil);
    const char *blockTypeEncoding = NSBlockGetSignature(*blockValue.pointer);
    NSMethodSignature *sig = [NSMethodSignature signatureWithObjCTypes:blockTypeEncoding];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:sig];
    [invocation setTarget:block];
    NSUInteger numberOfArguments = [sig numberOfArguments];
    if (numberOfArguments - 1 != argCount) {
        ctx->op_stack_push( or_Object_value(nil));
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
        ctx->op_stack_push( or_voidValue());
        return;
    }
    void *retValuePtr = alloca(mf_size_with_encoding(retType));
    [invocation getReturnValue:retValuePtr];
    ctx->op_stack_push( or_value_create(retType, retValuePtr));
    return;
}
void or_method_replace(BOOL isClassMethod, Class clazz, SEL sel, void *imp, const char *typeEncode){
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
    class_replaceMethod(c2, sel, (IMP)imp, typeEncode);
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
-(void)dealloc{
    NSValue *value = objc_getAssociatedObject(self, mf_propKey(@"propertyAttributes"));
    objc_property_attribute_t *attributes = (objc_property_attribute_t *)[value pointerValue];
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


void evalEmptyNode(ORInterpreter *inter, ThreadContext *ctx, MFScopeChain *scope, ORNode *node){
    return;
}
void evalTypeNode(ORInterpreter *inter, ThreadContext *ctx, MFScopeChain *scope, ORTypeNode *node){
    return;
}
void evalVariableNode(ORInterpreter *inter, ThreadContext *ctx, MFScopeChain *scope, ORVariableNode *node){
    return;
}
void evalFunctionDeclNode(ORInterpreter *inter, ThreadContext *ctx, MFScopeChain *scope, ORFunctionDeclNode *node){
    return;
}
void evalCArrayDeclNode(ORInterpreter *inter, ThreadContext *ctx, MFScopeChain *scope, ORCArrayDeclNode *node){
    eval(inter, ctx, scope, node.capacity);
    or_value value = *ctx->op_stack_pop();
    if (![node.capacity isKindOfClass:[ORIntegerValue class]]
        && [node.capacity isKindOfClass:[ORCArrayDeclNode class]] == NO) {
        ORIntegerValue *integerValue = [ORIntegerValue new];
        integerValue.value = (*(or_value_box *)value.pointer).longlongValue;
        node.capacity = integerValue;
    }
    return;
}
void evalBlockNode(ORInterpreter *inter, ThreadContext *ctx, MFScopeChain *scope, ORBlockNode *node){
    //{ }
    for (id statement in node.statements) {
        eval(inter, ctx, scope, statement);
        if (ctx->flow_flag != ORControlFlowFlagNormal) {
            return;
        }
    }
    return;
}
void evalConstantValue(ORInterpreter *inter, ThreadContext *ctx, ORNode *node){
    ocDecl *decl = node.symbol.decl;
    void *value = inter->constants + decl.offset;
    or_value result = or_value_create(decl.typeEncode, value);
    ctx->op_stack_push( result);
    return;
}
void evalValueNode(ORInterpreter *inter, ThreadContext *ctx, MFScopeChain *scope, ORValueNode *node){
    switch (node->_value_type) {
        case OCValueString:{
            void *buffer = inter->constants + node.symbol.decl.offset;
            __autoreleasing NSString *result = [NSString stringWithUTF8String:(const char *)buffer];
            ctx->op_stack_push( or_Object_value(result));
            return;
        }
        case OCValueCString:{
            void *buffer = inter->constants + node.symbol.decl.offset;
            or_value value = or_CString_value(buffer);
            ctx->op_stack_push( value);
            return;
        }
        case OCValueSelector:{
            void *buffer = inter->constants + node.symbol.decl.offset;
            ctx->op_stack_push( or_SEL_value(NSSelectorFromString([NSString stringWithUTF8String:(const char *)buffer])));
            return;
        }
        case OCValueProtocol:{
            void *buffer = inter->constants + node.symbol.decl.offset;
            ctx->op_stack_push( or_Object_value(NSProtocolFromString([NSString stringWithUTF8String:(const char *)buffer])));
            return;
        }
        case OCValueSelf:
        {
            void *result = ctx->seek_localvar( node.symbol.decl.offset);
            or_value value = or_value_create(node.symbol.decl.typeEncode, result);
            ctx->op_stack_push( value);
            break;
        }
        case OCValueSuper:
        {
            void *result = ctx->seek_localvar( node.symbol.decl.offset);
            or_value value = or_value_create(node.symbol.decl.typeEncode, result);
            ctx->op_stack_push( value);
            break;
        }
        case OCValueVariable:{
            if (node->_symbol->_decl->isClassRef) {
                Class clazz = NSClassFromString(node.value);
                if (clazz) {
                    ctx->op_stack_push( or_Class_value(clazz));
                    return;
                }
    #if DEBUG
                if (node.value) NSLog(@"\n---------OCRunner Warning---------\n"
                                      @"Can't find object or class: %@\n"
                                      @"-----------------------------------", node.value);
    #endif
                ctx->op_stack_push(or_nullValue());
                return;
            }else if (node->_symbol->_decl->isIvar){
                evalGetPropertyWithIvar(ctx, node.symbol);
                return;
            }
            void *result = ctx->seek_localvar( node->_symbol->_decl->_offset);
            or_value value = or_value_create(node->_symbol->_decl->_typeEncode, result);
            ctx->op_stack_push( value);
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
                or_value valueValue = *ctx->op_stack_pop();
                or_value keyValue = *ctx->op_stack_pop();
                id key = (__bridge id) *keyValue.pointer;
                id value = (__bridge id) *valueValue.pointer;
                if (key && value){
                    dict[key] = value;
                }else{
                    NSLog(@"OCRunner Error: the key %@ or value %@ of NSDictionary can't be nil", key?:@"", value?:@"");
                }
            }
            __autoreleasing NSDictionary *result = [dict copy];
            ctx->op_stack_push( or_Object_value(result));
            return;
        }
        case OCValueArray:{
            NSMutableArray *exps = node.value;
            NSMutableArray *array = [NSMutableArray array];
            for (ORNode *exp in exps) {
                eval(inter, ctx, scope, exp);
                or_value valueValue = *ctx->op_stack_pop();
                id value = (__bridge id) *valueValue.pointer;
                if (value) {
                    [array addObject:value];
                }else{
                    NSLog(@"OCRunner Error: the value of NSArray can't be nil, %@", array);
                }
            }
            __autoreleasing NSArray *result = [array copy];
            ctx->op_stack_push( or_Object_value(result));
            return;
        }
        case OCValueNSNumber:{
            eval(inter, ctx, scope, node.value);
            or_value value = *ctx->op_stack_pop();
            __autoreleasing NSNumber *result = nil;
            UnaryExecuteBaseType(result, @, value);
            ctx->op_stack_push( or_Object_value(result));
            return;
        }
        case OCValueNil:{
            ctx->op_stack_push( or_Object_value(nil));
            return;
        }
        case OCValueNULL:{
            ctx->op_stack_push( or_nullValue());
            return;
        }
        default:
            break;
    }

}
void evalIntegerValue(ORInterpreter *inter, ThreadContext *ctx, MFScopeChain *scope, ORIntegerValue *node){
    evalConstantValue(inter, ctx, node);
}
void evalUIntegerValue(ORInterpreter *inter, ThreadContext *ctx, MFScopeChain *scope, ORUIntegerValue *node){
    evalConstantValue(inter, ctx, node);
}
void evalDoubleValue(ORInterpreter *inter, ThreadContext *ctx, MFScopeChain *scope, ORDoubleValue *node){
    evalConstantValue(inter, ctx, node);
}
void evalBoolValue(ORInterpreter *inter, ThreadContext *ctx, MFScopeChain *scope, ORBoolValue *node){
    evalConstantValue(inter, ctx, node);
}
void evalMethodCall(ORInterpreter *inter, ThreadContext *ctx, MFScopeChain *scope, ORMethodCall *node){
    if (node.isStructRef) {
        void *dst = ctx->seek_localvar( node.symbol.decl.offset);
        or_value value = or_value_create(node.symbol.decl.typeEncode, dst);
        ctx->op_stack_push( value);
        return;
    }
    eval(inter, ctx, scope, node.caller);
    or_value variable = *ctx->op_stack_pop();
    void *dst = *variable.pointer;
    if (dst == NULL) {
        ctx->op_stack_push(or_nullValue());
        return;
    }
    id instance = (__bridge id)dst;
    SEL sel = NSSelectorFromString(node.selectorName);
    NSInteger argCount = node.values.count;
    NSInteger totalArgCount = argCount + 2;
    unichar argsMem[argCount * sizeof(or_value)];
    or_value *args[totalArgCount];
    or_value self_value = or_Object_value(instance);
    or_value sel_value = or_SEL_value(sel);
    args[0] = &self_value;
    args[1] = &sel_value;
    for (int i = 0; i < argCount; i++) {
        eval(inter, ctx, scope, node.values[i]);
        or_value arg = *ctx->op_stack_pop();
        void *dst = argsMem + i * sizeof(or_value);
        memcpy(dst, &arg, sizeof(or_value));
        args[i + 2] = (or_value *)dst;
    }
    // instance为nil时，依然要执行参数相关的表达式
    if (node.caller.nodeType == AstEnumValueNode) {
        if (instance && node.caller.symbol.decl->isSuper) {
//            return invoke_sueper_values(instance, sel, argValues);
        }
    }
    if (instance == nil) {
        return;
    }
    
    //如果在方法缓存表的中已经找到相关方法，直接调用，省去一次中间类型转换问题。优化性能，在方法递归时，调用耗时减少33%，0.15s -> 0.10s
    BOOL isClassMethod = object_isClass(instance);
    Class clazz = isClassMethod ? objc_getMetaClass(class_getName(instance)) : [instance class];
    MFMethodMapTableItem *map = [[MFMethodMapTable shareInstance] getMethodMapTableItemWith:clazz classMethod:isClassMethod sel:sel];
    if (map) {
        ctx->enter_call();
        for (int i = 0; i < totalArgCount; i++) {
            ctx->push_localvar(args[i]->pointer, or_value_mem_size(args[i]));
        }
        eval(inter, ctx, scope, map.methodImp);
        ctx->exit_call();
        return;
    }
    NSMethodSignature *sig = [instance methodSignatureForSelector:sel];
    if (sig == nil) {
        NSLog(@"OCRunner Error: %@ Unrecognized Selector %@", instance, node.selectorName);
        return;
    }
    NSUInteger methodSignArgCount = [sig numberOfArguments];
    const char *retunrType = [sig methodReturnType];
    // 基础类型转换
    for (NSUInteger i = 2; i < methodSignArgCount; i++) {
        or_value_set_typeencode(args[i], [sig getArgumentTypeAtIndex:i]);
    }
    or_value ret = or_value_create(retunrType, NULL);
    invoke_functionPointer((void *)&objc_msgSend, args, totalArgCount, &ret, methodSignArgCount);
    if (*retunrType == OCTypeVoid) {
        return;
    }
    if (*retunrType == OCTypeObject) {
        void *value = *(void **)ret.pointer;
        __autoreleasing id object = (__bridge id)value;
        value = (__bridge void *)object;
        or_value_set_pointer(&ret, &value);
    }
    ctx->op_stack_push(ret);
    return;
//    //解决多参数调用问题
//    if (totalArgCount > methodSignArgCount && sig != nil) {
//        or_value ret = or_value_create(retunrType, NULL);
//        ctx->op_stack_push(ret);
//        void *msg_send = (void *)&objc_msgSend;
//        invoke_functionPointer(msg_send, args, argCount, &ret);
//        if (*retunrType == OCTypeObject) {
//            void *value = *(void **)ret.pointer;
//            __autoreleasing id object = (__bridge id)value;
//            value = (__bridge void *)object;
//            or_value_set_pointer(&ret, &value);
//        }
//        return;
//    }else{
//        void *retValuePointer = alloca([sig methodReturnLength]);
//        char *returnType = (char *)[sig methodReturnType];
//        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:sig];
//        invocation.target = instance;
//        invocation.selector = sel;
//        for (NSUInteger i = 2; i < argCount; i++) {
//            or_value *value = args[i];
//            // 基础类型转换
//            or_value_set_typeencode(args[i], [sig getArgumentTypeAtIndex:i]);
//            [invocation setArgument:value->pointer atIndex:i];
//        }
//        // func replaceIMP execute
//        [invocation invoke];
//        returnType = removeTypeEncodingPrefix(returnType);
//        if (*returnType == OCTypeVoid) {
//            return;
//        }
//        [invocation getReturnValue:retValuePointer];;
//        // 针对一下方法调用，需要和CF一样，最终都要release. 与JSPatch和Mango中的__bridge_transfer效果相同
//        if (sel == @selector(alloc) || sel == @selector(new)||
//            sel == @selector(copy) || sel == @selector(mutableCopy)) {
//            void *value = *(void **)retValuePointer;
//            __autoreleasing id object = (__bridge id)value;
//            CFRelease(value);
//            or_value result = or_value_create(returnType, &object);
//            ctx->op_stack_push(result);
//            return;
//        }
//        or_value result = or_value_create(returnType, retValuePointer);
//        ctx->op_stack_push( result);
//        return;
//    }
}
void evalFunctionCall(ORInterpreter *inter, ThreadContext *ctx, MFScopeChain *scope, ORFunctionCall *node){
    NSUInteger argCount = node.expressions.count;
    unichar argsMem[argCount * sizeof(or_value)];
    or_value *args[argCount];
    for (int i = 0; i < argCount; i++) {
        eval(inter, ctx, scope, node.expressions[i]);
        or_value arg = *ctx->op_stack_pop();
        void *dst = argsMem + i * sizeof(or_value);
        memcpy(dst, &arg, sizeof(or_value));
        args[i] = (or_value *)dst;
    }
    if ([node.caller isKindOfClass:[ORMethodCall class]]
        && [(ORMethodCall *)node.caller methodOperator] == MethodOpretorDot){
        // TODO: 调用block
        // make.left.equalTo(xxxx);
        eval(inter, ctx, scope, (ORMethodCall *)node.caller);
        or_value value = *ctx->op_stack_pop();
        invoke_MFBlockValue(ctx, value, args, argCount);
        return;
    }
    //TODO: 递归函数优化, 优先查找全局函数
    if (node->_symbol && node->_symbol->_bbimp){
        // global function calll
        ctx->enter_call();
        for (int i = 0; i < argCount; i++) {
            ctx->push_localvar(args[i]->pointer, or_value_mem_size(args[i]));
        }
        eval(inter, ctx, scope, node->_symbol->_bbimp);
        ctx->exit_call();
        return;
//    }else if([functionImp isKindOfClass:[ORSearchedFunction class]]) {
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
void evalFunctionNode(ORInterpreter *inter, ThreadContext *ctx, MFScopeChain *scope, ORFunctionNode *node){
    // C函数声明执行, 向全局作用域注册函数
    if (!ctx->is_calling()) return;
    MFScopeChain *current = [MFScopeChain scopeChainWithNext:scope];
//     if (node.declare && node.declare.var.isBlock) {
//         // xxx = ^void (int x){ }, block作为值
//         MFBlock *manBlock = [[MFBlock alloc] init];
//         manBlock.func = [node convertToNormalFunctionImp];
//         MFScopeChain *blockScope = [MFScopeChain scopeChainWithNext:[MFScopeChain topScope]];
//         copy_undef_var(node, [MFVarDeclareChain new], scope, blockScope);
//         manBlock.outScope = blockScope;
//         manBlock.retType = manBlock.func.declare;
//         manBlock.paramTypes = manBlock.func.declare.params;
//         __autoreleasing id ocBlock = [manBlock ocBlock];
//         ctx->flow_flag = ORControlFlowFlagNormal;
//         CFRelease((__bridge void *)ocBlock);
//         ctx->op_stack_push( or_Object_value(ocBlock));
//         return;
//     }
     eval(inter, ctx, current, node.scopeImp);
     ctx->flow_flag = ORControlFlowFlagNormal;
     return;
}
void evalSubscriptNode(ORInterpreter *inter, ThreadContext *ctx, MFScopeChain *scope, ORSubscriptNode *node){
    eval(inter, ctx, scope, node.keyExp);
    or_value key = *ctx->op_stack_pop();
    eval(inter, ctx, scope, node.caller);
    or_value target = *ctx->op_stack_pop();
    or_value result;
    or_value_subscriptGet(&result, target, key);
    ctx->op_stack_push( result);
}

void evalAssignNode(ORInterpreter *inter, ThreadContext *ctx, MFScopeChain *scope, ORAssignNode *node){
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
    ocDecl *decl = node.value.symbol.decl;
    switch (node.value.nodeType) {
        case AstEnumValueNode:
        {
            eval(inter, ctx, scope, resultExp);
            or_value right = *ctx->op_stack_pop();
            
            ORValueNode *valueNode = (ORValueNode *)node.value;
            NSString *varname = valueNode.value;
            if (decl->isIvar) {
                //属性值设置
                evalSetPropertyWithIvar(ctx, node.value.symbol, &right);
                return;
            }else if (decl->isInternalIvar){
                //object ivar设置
                id instance = (__bridge id)ctx->seek_localvar( 0);
                Ivar ivar = class_getInstanceVariable(object_getClass(instance),varname.UTF8String);
                const char *ivarEncoding = ivar_getTypeEncoding(ivar);
                if (*ivarEncoding == OCTypeObject) {
                    object_setIvar(instance, ivar, (__bridge id _Nullable)(*(void **)right.pointer));
                    return;
                }
                char *ptr = (char *)(__bridge void *)(instance);
                ptr = ptr + ivar_getOffset(ivar);
                or_value_write_to(right, (void *)ptr, ivarEncoding);
                return;
            }else if ([varname characterAtIndex:0] == '_'){
                // ivar 检测，如果是ivar，设置decl的isInternalIvar为YES
                id instance = (__bridge id)ctx->seek_localvar( 0);
                Ivar ivar = class_getInstanceVariable(object_getClass(instance),varname.UTF8String);
                if (ivar) {
                    decl->isInternalIvar = YES;
                    const char *ivarEncoding = ivar_getTypeEncoding(ivar);
                    if (*ivarEncoding == OCTypeObject) {
                        object_setIvar(instance, ivar, (__bridge id _Nullable)(*(void **)right.pointer));
                        return;
                    }
                    char *ptr = (char *)(__bridge void *)(instance);
                    ptr = ptr + ivar_getOffset(ivar);
                    or_value_write_to(right, ptr, ivarEncoding);
                    return;
                }
            }
            void *dst = ctx->seek_localvar( valueNode.symbol.decl.offset);
            or_value_write_to(right, dst, node.symbol.decl.typeEncode);
            break;
        }
        case AstEnumUnaryNode:
        {
            eval(inter, ctx, scope, node.value);
            or_value left = *ctx->op_stack_pop();
            eval(inter, ctx, scope, resultExp);
            or_value right = *ctx->op_stack_pop();
            or_value_write_to(right, left.pointer, left.typeencode);
            break;
        }
        case AstEnumMethodCall:
        {
            ORMethodCall *methodCall = (ORMethodCall *)node.value;
            if (methodCall.isStructRef) {
                eval(inter, ctx, scope, resultExp);
                or_value right = *ctx->op_stack_pop();
                void *dst = ctx->seek_localvar( methodCall.symbol.decl.offset);
                or_value_write_to(right, dst, methodCall.symbol.decl.typeEncode);
                return;
            }
            if (!methodCall.methodOperator) {
                NSCAssert(0, @"must dot grammar");
            }
            //调用对象setter方法
            NSString *setterName = methodCall.selectorName;
            NSString *first = [[setterName substringToIndex:1] uppercaseString];
            NSString *other = setterName.length > 1 ? [setterName substringFromIndex:1] : @"";
            setterName = [NSString stringWithFormat:@"set%@%@",first,other];
            ORMethodCall *setCaller = [ORMethodCall new];
            setCaller.nodeType = AstEnumMethodCall;
            setCaller.caller = methodCall.caller;
            setCaller.selectorName = setterName;
            setCaller.values = [@[resultExp] mutableCopy];
            setCaller.isStructRef = YES;
            eval(inter, ctx, scope, setCaller);
            break;
        }
        case AstEnumSubscriptNode:
        {
            eval(inter, ctx, scope, resultExp);
            or_value right = *ctx->op_stack_pop();
            
            ORSubscriptNode *subExp = (ORSubscriptNode *)node.value;
            
            eval(inter, ctx, scope, subExp.caller);
            or_value caller = *ctx->op_stack_pop();
            
            eval(inter, ctx, scope, subExp.keyExp);
            or_value indexValue = *ctx->op_stack_pop();
            
            or_value_subscriptSet(caller, indexValue, right);
            break;
        }
        default:
            break;
    }

    ctx->flow_flag = ORControlFlowFlagNormal;
    return;

}
void evalDeclaratorNode(ORInterpreter *inter, ThreadContext *ctx, MFScopeChain *scope, ORDeclaratorNode *node){
    ocDecl *decl = node.symbol.decl;
    or_value value = or_value_create(decl.typeEncode, NULL);
//    value.modifier = decl.declModifer;
//    if (isObjectWithTypeEncode(value.typeencode)
//        && NSClassFromString(value.typeName) == nil
//        && ![value.typeName isEqualToString:@"id"]) {
//        NSString *reason = [NSString stringWithFormat:@"Unknown Type Identifier: %@",value.typeName];
//        @throw [NSException exceptionWithName:@"OCRunner" reason:reason userInfo:nil];
//    }
    machine_mem dst = ctx->push_localvar(value.pointer, or_value_mem_size(&value));
    if (scope == [MFScopeChain topScope] || scope.next == [MFScopeChain topScope]) {
        MFValue *val = [MFValue valueWithTypeEncode:value.typeencode pointer:dst];
        [scope setValue:val withIndentifier:node.var.varname];
    }
    return;
}
void evalInitDeclaratorNode(ORInterpreter *inter, ThreadContext *ctx, MFScopeChain *scope, ORInitDeclaratorNode *node){
//    BOOL staticVar = node.declarator.type.modifier & DeclarationModifierStatic;
//    if ([node.declarator.var isKindOfClass:[ORCArrayDeclNode class]]) {
//        eval(inter, ctx, scope, node.declarator.var);
//    }
//    if (staticVar) {
//        NSString *key = [NSString stringWithFormat:@"%p",(void *)node];
//        or_value value = [[MFStaticVarTable shareInstance] getStaticVarValueWithKey:key];
//        if (value) {
//            [scope setValue:value withIndentifier:node.declarator.var.varname];
//        }else{
//            or_value value = initializeBlock();
//            [[MFStaticVarTable shareInstance] setStaticVarValue:value withKey:key];
//        }
//    }else{
//    }
    ocDecl *decl = node.declarator->_symbol->_decl;
    eval(inter, ctx, scope, node.expression);
    or_value value = *ctx->op_stack_pop();
//  value.modifier = decl.declModifer;
    or_value_set_typeencode(&value, decl->_typeEncode);
//        if (decl.isFunction)
//            value.funDecl = (ORFunctionDeclNode *)node.declarator;
    machine_mem dst = ctx->push_localvar(value.pointer, or_value_mem_size(&value));
    if (*value.typeencode == OCTypeObject) {
        MFValue *val = [MFValue valueWithTypeEncode:value.typeencode pointer:dst];
        val.modifier = decl.declModifer;
        [scope setValue:val withIndentifier:node.declarator.var.varname];
    }
//    }
    ctx->flow_flag = ORControlFlowFlagNormal;
    return;
}
void evalUnaryNode(ORInterpreter *inter, ThreadContext *ctx, MFScopeChain *scope, ORUnaryNode *node){
    eval(inter, ctx, scope, node.value);
    or_value currentValue = *ctx->op_stack_pop();
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
            ctx->op_stack_push( resultValue);
            return;
        }
        case UnaryOperatorAdressValue:{
            or_value resultValue = or_value_create(currentValue.typeencode, NULL);
//            resultValue.pointerCount -= 1;
            if (node.parentNode.nodeType == AstEnumAssignNode) {
//                [resultValue setValuePointerWithNoCopy:*(void **)currentValue.pointer];
            }else{
                resultValue.pointer = *(void ***)currentValue.pointer;
            }
            ctx->op_stack_push( resultValue);
            return;
        }
        default:
            break;
    }
    ctx->op_stack_push( cal_result);
    return;
}

void evalBinaryNode(ORInterpreter *inter, ThreadContext *ctx, MFScopeChain *scope, ORBinaryNode *node){
    switch (node->_operatorType) {
        case BinaryOperatorLOGIC_AND:{
            eval(inter, ctx, scope, node->_left);
            or_value leftValue = *ctx->op_stack_pop();
            if (or_value_isSubtantial(leftValue)) {
                eval(inter, ctx, scope, node->_right);
                or_value rightValue = *ctx->op_stack_pop();
                ctx->op_stack_push( or_BOOL_value(or_value_isSubtantial(rightValue)));
                return;
            }
            ctx->op_stack_push( or_BOOL_value(NO));
            return;
        }
        case BinaryOperatorLOGIC_OR:{
            eval(inter, ctx, scope, node->_left);
            or_value leftValue = *ctx->op_stack_pop();
            if (or_value_isSubtantial(leftValue)) {
                ctx->op_stack_push( or_BOOL_value(YES));
                return;
            }
            eval(inter, ctx, scope, node->_right);
            or_value rightValue = *ctx->op_stack_pop();
            ctx->op_stack_push( or_BOOL_value(or_value_isSubtantial(rightValue)));
            return;
        }
        default: break;
    }
    eval(inter, ctx, scope, node->_left);
    eval(inter, ctx, scope, node->_right);
    
    or_value rightValue = *ctx->op_stack_pop();
    or_value leftValue = *ctx->op_stack_pop();
    
    or_value cal_result;
    cal_result.typeencode = leftValue.typeencode;
    switch (node->_operatorType) {
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
    ctx->op_stack_push( cal_result);
    
    return;

}
void evalTernaryNode(ORInterpreter *inter, ThreadContext *ctx, MFScopeChain *scope, ORTernaryNode *node){
    eval(inter, ctx, scope, node.expression);
    or_value condition = *ctx->op_stack_pop();
    if (node.values.count == 1) { // condition ?: value
        if (or_value_isSubtantial(condition)) {
            ctx->op_stack_push( condition);
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
void evalIfStatement(ORInterpreter *inter, ThreadContext *ctx, MFScopeChain *scope, ORIfStatement *node){
    for (ORIfStatement *statement in node->_statements) {
        if (statement->_condition) {
            eval(inter, ctx, scope, statement.condition);
            if (or_value_isSubtantial(*ctx->op_stack_pop())) {
                eval(inter, ctx, scope, statement.scopeImp);
                return;
            }
        }else{
            eval(inter, ctx, scope, node.scopeImp);
        }
    }
    ctx->flow_flag = ORControlFlowFlagNormal;
    return;
}
void evalWhileStatement(ORInterpreter *inter, ThreadContext *ctx, MFScopeChain *scope, ORWhileStatement *node){
    MFScopeChain *current = [MFScopeChain scopeChainWithNext:scope];
    while (1) {
        eval(inter, ctx, scope, node.condition);
        if (!or_value_isSubtantial(*ctx->op_stack_pop())) {
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
void evalDoWhileStatement(ORInterpreter *inter, ThreadContext *ctx, MFScopeChain *scope, ORDoWhileStatement *node){
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
        if (!or_value_isSubtantial(*ctx->op_stack_pop())) {
            break;
        }
    }
    ctx->flow_flag = ORControlFlowFlagNormal;
    return;
}
void evalCaseStatement(ORInterpreter *inter, ThreadContext *ctx, MFScopeChain *scope, ORCaseStatement *node){
    MFScopeChain *current = [MFScopeChain scopeChainWithNext:scope];
    eval(inter, ctx, current, node.scopeImp);
}
void evalSwitchStatement(ORInterpreter *inter, ThreadContext *ctx, MFScopeChain *scope, ORSwitchStatement *node){
    eval(inter, ctx, scope, node.value);
or_value value = *ctx->op_stack_pop();
    BOOL hasMatch = NO;
    for (ORCaseStatement *statement in node.cases) {
        if (statement.value) {
            if (!hasMatch) {
                eval(inter, ctx, scope, statement.value);
                or_value caseValue = *ctx->op_stack_pop();
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
void evalForStatement(ORInterpreter *inter, ThreadContext *ctx, MFScopeChain *scope, ORForStatement *node){
    MFScopeChain *current = [MFScopeChain scopeChainWithNext:scope];
    for (ORNode *exp in node.varExpressions) {
        eval(inter, ctx, current, exp);
    }
    while (1) {
        eval(inter, ctx, scope, node.condition);
        if (!or_value_isSubtantial(*ctx->op_stack_pop())) {
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
void evalForInStatement(ORInterpreter *inter, ThreadContext *ctx, MFScopeChain *scope, ORForInStatement *node){
    MFScopeChain *current = [MFScopeChain scopeChainWithNext:scope];
    eval(inter, ctx, current, node.value);
    or_value arrayValue = *ctx->op_stack_pop();
    id array = (__bridge id)*arrayValue.pointer;
    for (id element in array) {
        //TODO: 每执行一次，重新在内存中重新设置一次值
        void *dst = ctx->seek_localvar( node.expression.symbol.decl.offset);
        memcpy(dst, (void *)&element, sizeof(void *));
        
//        or_value value = or_value_create(OCTypeStringObject, (void *)&element);
//        void *dst = ctx->seek_localvar( node.expression.symbol.decl.offset);
//        or_value_write_to(value, dst, value.typeencode);
    
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
void evalControlStatNode(ORInterpreter *inter, ThreadContext *ctx, MFScopeChain *scope, ORControlStatNode *node){
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
void evalPropertyNode(ORInterpreter *inter, ThreadContext *ctx, MFScopeChain *scope, ORPropertyNode *node){
    NSString *propertyName = node.var.var.varname;
    Class clazz = NSClassFromString([(ORClassNode *)node.parentNode className]);
    class_replaceProperty(clazz, [propertyName UTF8String], node.propertyAttributes, 3);
    MFPropertyMapTableItem *propItem = [[MFPropertyMapTableItem alloc] initWithClass:clazz property:node];
    [[MFPropertyMapTable shareInstance] addPropertyMapTableItem:propItem];
    replace_getter_method(clazz, node);
    replace_setter_method(clazz, node);
    return;
}
void evalMethodDeclNode(ORInterpreter *inter, ThreadContext *ctx, MFScopeChain *scope, ORMethodDeclNode *node){
    return;
}
void evalMethodNode(ORInterpreter *inter, ThreadContext *ctx, MFScopeChain *scope, ORMethodNode *node){
    MFScopeChain *current = [MFScopeChain scopeChainWithNext:scope];
//    [ORCallFrameStack pushMethodCall:node instance:scope.instance];
    eval(inter, ctx, current, node.scopeImp);
    ctx->flow_flag = ORControlFlowFlagNormal;
//    [ORCallFrameStack pop];
    return;
}
void evalClassNode(ORInterpreter *inter, ThreadContext *ctx, MFScopeChain *scope, ORClassNode *node){
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
void evalProtocolNode(ORInterpreter *inter, ThreadContext *ctx, MFScopeChain *scope, ORProtocolNode *node){
//    if (NSProtocolFromString(node.protcolName) != nil) {
//        ctx->op_stack_push( [MFValue voidValue]);
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
void evalStructStatNode(ORInterpreter *inter, ThreadContext *ctx, MFScopeChain *scope, ORStructStatNode *node){
    return;
}
void evalUnionStatNode(ORInterpreter *inter, ThreadContext *ctx, MFScopeChain *scope, ORUnionStatNode *node){
    return;
}
void evalEnumStatNode(ORInterpreter *inter, ThreadContext *ctx, MFScopeChain *scope, OREnumStatNode *node){
    return;
}
void evalTypedefStatNode(ORInterpreter *inter, ThreadContext *ctx, MFScopeChain *scope, ORTypedefStatNode *node){
    return;
}

void eval(ORInterpreter *inter, ThreadContext *ctx, MFScopeChain *scope, ORNode *node){
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

void eval(ORInterpreter *inter, void *ctx, MFScopeChain *scope, ORNode *node){
    eval(inter, (ThreadContext *)ctx, scope, node);
}

void *thread_current_context(){
    return ThreadContext::current();
}
