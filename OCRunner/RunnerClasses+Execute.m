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
    ORMethodImplementation *imp = map.method;
    __autoreleasing MFValue *retValue = [imp execute:scope];
//    [retValue assignToCValuePointer:ret typeEncoding:[methodSignature methodReturnType]];
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
    SEL sel = NSSelectorFromString(selector);
    NSMethodSignature *sig = [instance methodSignatureForSelector:sel];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:sig];
    invocation.target = instance;
    invocation.selector = sel;
    NSUInteger argCount = [sig numberOfArguments];
    for (NSUInteger i = 2; i < argCount; i++) {
        const char *typeEncoding = [sig getArgumentTypeAtIndex:i];
        void *ptr = malloc(mf_size_with_encoding(typeEncoding));
//        [argValues[i-2] assignToCValuePointer:ptr typeEncoding:typeEncoding];
        [invocation setArgument:ptr atIndex:i];
        free(ptr);
    }
    // func replaceIMP execute
    [invocation invoke];
    return nil;
}@end
@implementation ORCFuncCall(Execute)
- (nullable MFValue *)execute:(MFScopeChain *)scope {
    NSMutableArray *params = [NSMutableArray array];
    for (ORValueExpression *exp in self.expressions){
        [params addObject:[exp execute:scope]];
    }
    if ([self.caller isKindOfClass:[ORMethodCall class]] && [(ORMethodCall *)self.caller isDot]){
        // make.left.equalTo(xxxx);
    }
    // C 函数调用
    return nil;
}@end
@implementation ORBlockImp(Execute)
- (nullable MFValue *)execute:(MFScopeChain *)scope {
    MFScopeChain *current = [MFScopeChain scopeChainWithNext:scope];
    if (self.declare) {
        [self.declare execute:current];
    }
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
    MFValue *resultValue = [MFValue new];
    [resultValue setValueType:TypeObject];
    resultValue.pointerValue = (__bridge_retained void *)[arrValue subscriptGetWithIndex:bottomValue];
    return resultValue;
}
@end
@implementation ORAssignExpression (Execute)
- (nullable MFValue *)execute:(MFScopeChain *)scope {
    MFValue *rightValue = [self.expression execute:scope];
    switch (self.assignType) {
        case AssignOperatorAssign:
            break;
        case AssignOperatorAssignAnd:
            break;
        case AssignOperatorAssignOr:
            break;
        case AssignOperatorAssignXor:
            break;
        case AssignOperatorAssignAdd:
            break;
        case AssignOperatorAssignSub:
            break;
        case AssignOperatorAssignDiv:
            break;
        case AssignOperatorAssignMuti:
            break;
        case AssignOperatorAssignMod:
            break;
        case AssignOperatorAssignShiftLeft:
            break;
        case AssignOperatorAssignShiftRight:
            break;
            
        default:
            break;
    }
    return [MFValue normalEnd];
}@end
@implementation ORDeclareExpression (Execute)
- (nullable MFValue *)execute:(MFScopeChain *)scope {
    if (self.expression) {
        MFValue *value = [self.expression execute:scope];
        [scope setValue:value withIndentifier:self.pair.var.varname];
    }else{
        [scope setValue:[MFValue defaultValueWithTypeEncoding:OCTypeEncodingForPair(self.pair)] withIndentifier:self.pair.var.varname];
    }
    return [MFValue normalEnd];
}@end
@implementation ORUnaryExpression (Execute)
- (nullable MFValue *)execute:(MFScopeChain *)scope {
    MFValue *value = [MFValue new];
    MFValue *juddgeValue = [self.value execute:scope];
    ValueDefineWithMFValue(0, juddgeValue);
    switch (self.operatorType) {
        case UnaryOperatorNot:{
//            UnaryExecute(!, 0 , juddgeValue);
        }
            
//            value.uintValue = ![self.value execute:scope].isSubtantial;
            break;
            
            
        default:
            break;
    }
    return value;
}@end
@implementation ORBinaryExpression(Execute)
- (nullable MFValue *)execute:(MFScopeChain *)scope {
    return nil;
}@end
@implementation ORTernaryExpression(Execute)
- (nullable MFValue *)execute:(MFScopeChain *)scope {
    return nil;
}@end
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
    BOOL hasMatch = NO;
    for (ORCaseStatement *statement in self.cases) {
        if (statement.value) {
            if (!hasMatch) {
                //FIXME: MFValue值比较的问题
                hasMatch = [statement.value execute:scope] == value;
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
    //TODO: 新增一个作用域
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
}@end
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
        
    }else{
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

char *const OCTypeEncodingForPair(ORTypeVarPair * pair){
    char encoding[20];
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
case ##type:\
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
        CaseTypeEncoding(TypeFunction, "?")
        default:
            break;
    }
    append("\0");
    char *const result = malloc(sizeof(char) * 20);
    strcpy(result, encoding);
    return result;
}
