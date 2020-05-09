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
@implementation ORTypeSpecial(Execute)
- (nullable MFValue *)execute:(MFScopeChain *)scope {
    return nil;
}@end
@implementation ORVariable (Execute)
- (nullable MFValue *)execute:(MFScopeChain *)scope {
    return nil;
}@end
@implementation ORTypeVarPair(Execute)
- (nullable MFValue *)execute:(MFScopeChain *)scope {
    return nil;
}@end
@implementation ORFuncVariable(Execute)
- (nullable MFValue *)execute:(MFScopeChain *)scope {
    return nil;
}@end
@implementation ORFuncDeclare(Execute)
- (nullable MFValue *)execute:(MFScopeChain *)scope {
    [scope.parameters enumerateObjectsUsingBlock:^(MFValue * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
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
//    NSMutableArray *params = [NSMutableArray array];
//    for (ORValueExpression *exp in self.values){
//        [params addObject:[exp execute:scope]];
//    }
//    NSString *selector = [self.names componentsJoinedByString:@":"];
//    SEL sel = NSSelectorFromString(selector);
//    NSMethodSignature *sig = [instance methodSignatureForSelector:sel];
//    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:sig];
//    invocation.target = instance;
//    invocation.selector = sel;
//    NSUInteger argCount = [sig numberOfArguments];
//    for (NSUInteger i = 2; i < argCount; i++) {
//        const char *typeEncoding = [sig getArgumentTypeAtIndex:i];
//        void *ptr = malloc(mf_size_with_encoding(typeEncoding));
//        [argValues[i-2] assignToCValuePointer:ptr typeEncoding:typeEncoding];
//        [invocation setArgument:ptr atIndex:i];
//        free(ptr);
//    }
//    [invocation invoke];
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
@implementation OCCollectionGetValue(Execute)
- (nullable MFValue *)execute:(MFScopeChain *)scope {
    return [MFValue normalEnd];
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
    switch (self.operatorType) {
        case UnaryOperatorNot:
            value.uintValue = ![self.value execute:scope].isSubtantial;
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
    //FIXME: 新增一个作用域
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
    for (id element in [self.value execute:current].objectValue) {
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
    
    return nil;
}
@end
@implementation ORMethodDeclare(Execute)
- (nullable MFValue *)execute:(MFScopeChain *)scope {
    [scope.parameters enumerateObjectsUsingBlock:^(MFValue * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
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
@implementation ORClass(Execute)
- (nullable MFValue *)execute:(MFScopeChain *)scope{
    if (NSClassFromString(self.className)) {
        //TODO: 注册method到作用域中,method已存在则Class中替换方法，不存在则新增
        //TODO: 注册property到作用域中,Class添加属性
    }else{
        //TODO: 新建类
        Class superClass = NSClassFromString(self.superClassName);
        if (!superClass) {
            //TODO: 加入败者组，等待父类先加载
            return nil;
        }
        Class newClass = objc_allocateClassPair(superClass, self.className.UTF8String, 0);
        //TODO: 添加属性
        for (ORPropertyDeclare *property in self.properties) {
            NSString *propertyName = property.var.var.varname;
            //FIXME: type encode problem
            objc_property_attribute_t type = { "T", [[NSString stringWithFormat:@"@\"%@\"",property.var.type.name] UTF8String] };
            objc_property_attribute_t ownership = { "&", "N" };
            objc_property_attribute_t backingivar = { "V", [[NSString stringWithFormat:@"_%@", propertyName] UTF8String] };
            objc_property_attribute_t attrs[] = { type, ownership, backingivar };
            if (class_addProperty(newClass, [propertyName UTF8String], attrs, 3)) {
                class_addMethod(newClass, NSSelectorFromString(propertyName), (IMP)registerClassGetter, "@@:");
                class_addMethod(newClass, NSSelectorFromString([NSString stringWithFormat:@"set%@:",[propertyName capitalizedString]]), (IMP)registerClassSetter, "v@:@");
            }
            class_addIvar(newClass, strcat("_", propertyName.UTF8String), sizeof(int), log2(sizeof(int)), @encode(int));
        }
//        //TODO: 添加protocol
//        for (NSString *protocolName in self.protocols) {
//            Protocol *protocol = NSProtocolFromString(protocolName);
//            class_addProtocol(newClass, protocol);
//        }
        //TODO: 添加方法
        for (ORMethodImplementation *method in self.methods) {
            NSString *selector = [method.declare.methodNames componentsJoinedByString:@":"];
            class_addMethod(newClass, NSSelectorFromString(selector), NULL, "parameter encoding");
        }
        objc_registerClassPair(newClass);
        //TODO: 顶级作用域添加类变量
        [scope.top setValue:[MFValue valueInstanceWithClass:newClass] withIndentifier:self.className];
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
