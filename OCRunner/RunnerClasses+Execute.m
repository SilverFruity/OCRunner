//
//  ORunner+Execute.m
//  MangoFix
//
//  Created by Jiang on 2020/5/8.
//  Copyright © 2020 yongpengliang. All rights reserved.
//

#import "RunnerClasses+Execute.h"

@implementation ORTypeSpecial(Execute)
- (nullable MFValue *)executeResult {
    return nil;
}@end
@implementation ORVariable (Execute)
- (nullable MFValue *)executeResult {
    return nil;
}@end
@implementation ORTypeVarPair(Execute)
- (nullable MFValue *)executeResult {
    return nil;
}@end
@implementation ORFuncVariable(Execute)
- (nullable MFValue *)executeResult {
    return nil;
}@end
@implementation ORFuncDeclare(Execute)
- (nullable MFValue *)executeResult {
    return nil;
}@end
@implementation ORValueExpression (Execute)
- (nullable MFValue *)executeResult {
    return nil;
}@end
@implementation ORMethodCall(Execute)
- (nullable MFValue *)executeResult {
    return nil;
}@end
@implementation ORCFuncCall(Execute)
- (nullable MFValue *)executeResult {
    return nil;
}@end
@implementation ORBlockImp(Execute)
- (nullable MFValue *)executeResult {
    return nil;
}@end
@implementation OCCollectionGetValue(Execute)
- (nullable MFValue *)executeResult {
    return nil;
}@end
@implementation ORAssignExpression (Execute)
- (nullable MFValue *)executeResult {
    return nil;
}@end
@implementation ORDeclareExpression (Execute)
- (nullable MFValue *)executeResult {
    return nil;
}@end
@implementation ORUnaryExpression (Execute)
- (nullable MFValue *)executeResult {
    MFValue *value = [MFValue new];
    switch (self.operatorType) {
        case UnaryOperatorNot:
            value.uintValue = !self.value.executeResult.isSubtantial;
            break;
        
            
        default:
            break;
    }
    return value;
}@end
@implementation ORBinaryExpression(Execute)
- (nullable MFValue *)executeResult {
    return nil;
}@end
@implementation ORTernaryExpression(Execute)
- (nullable MFValue *)executeResult {
    return nil;
}@end
@implementation ORStatement (Execute)
- (nullable MFValue *)executeResult {
    return nil;
}@end
@implementation ORIfStatement (Execute)
- (nullable MFValue *)executeResult {
    NSMutableArray *statements = [NSMutableArray array];
    ORIfStatement *ifStatement = self;
    while (ifStatement) {
        [statements insertObject:ifStatement atIndex:0];
        ifStatement = self.last;
    }
    for (ORIfStatement *statement in statements) {
        if (statement.condition.executeResult.isSubtantial) {
            return [statement.funcImp executeResult];
        }
    }
    if (self.condition == nil) {
        return [self.funcImp executeResult];
    }
    return nil;
}@end
@implementation ORWhileStatement (Execute)
- (nullable MFValue *)executeResult {
    while (1) {
        if (!self.condition.executeResult.isSubtantial) {
            break;
        }
        MFValue *resultValue = self.funcImp.executeResult;
        if (resultValue.resultType == MFStatementResultTypeBreak) {
            resultValue.resultType = MFStatementResultTypeNormal;
            break;
        }else if (resultValue.resultType == MFStatementResultTypeContinue){
            resultValue.resultType = MFStatementResultTypeNormal;
        }else if (resultValue.resultType == MFStatementResultTypeReturn){
            return resultValue;
        }else if (resultValue.resultType == MFStatementResultTypeNormal){
            return nil;
        }
    }
    return nil;
}
@end
@implementation ORDoWhileStatement (Execute)
- (nullable MFValue *)executeResult {
    while (1) {
        MFValue *resultValue = self.funcImp.executeResult;
        if (resultValue.resultType == MFStatementResultTypeBreak) {
            resultValue.resultType = MFStatementResultTypeNormal;
            break;
        }else if (resultValue.resultType == MFStatementResultTypeContinue){
            resultValue.resultType = MFStatementResultTypeNormal;
        }else if (resultValue.resultType == MFStatementResultTypeReturn){
            return resultValue;
        }else if (resultValue.resultType == MFStatementResultTypeNormal){
            return nil;
        }
        
        if (!self.condition.executeResult.isSubtantial) {
            break;
        }
    }
    return nil;
}
@end
@implementation ORCaseStatement (Execute)
- (nullable MFValue *)executeResult {
    return self.funcImp.executeResult;
}@end
@implementation ORSwitchStatement (Execute)
- (nullable MFValue *)executeResult {
    MFValue *value = self.value.executeResult;
    BOOL hasMatch = NO;
    for (ORCaseStatement *statement in self.cases) {
        if (statement.value) {
            if (!hasMatch) {
                hasMatch = statement.value.executeResult == value;
                if (!hasMatch) {
                    continue;
                }
            }
            MFValue *result = statement.funcImp.executeResult;
            if (result.resultType == MFStatementResultTypeBreak) {
                result.resultType = MFStatementResultTypeNormal;
                return value;
            }else if (result.resultType == MFStatementResultTypeNormal){
                continue;
            }else{
                return value;
            }
        }else{
            MFValue *result = statement.funcImp.executeResult;
            if (result.resultType == MFStatementResultTypeBreak) {
                result.resultType = MFStatementResultTypeNormal;
                return value;
            }
        }
    }
    return nil;
}@end
@implementation ORForStatement (Execute)
- (nullable MFValue *)executeResult {
    //FIXME: 新增一个作用域
    for (ORDeclareExpression *declare in self.declareExpressions) {
        [declare executeResult];
    }
    while (1) {
        if (!self.condition.executeResult.isSubtantial) {
            break;
        }
        MFValue *result = self.funcImp.executeResult;
        if (result.resultType == MFStatementResultTypeReturn) {
            return result;
        }else if (result.resultType == MFStatementResultTypeBreak){
            result.resultType = MFStatementResultTypeNormal;
            return result;
        }else if (result.resultType == MFStatementResultTypeContinue){
            continue;
        }
        for (ORValueExpression *exp in self.expressions) {
           [exp executeResult];
        }
    }
    //FIXME: 移除作用域
    return nil;
}@end
@implementation ORForInStatement (Execute)
- (nullable MFValue *)executeResult {
    //FIXME: 新增一个作用域
    //FIXME: 注册表新增一个变量
    [self.expression executeResult];
    for (id _ in self.value.executeResult.objectValue) {
        //FIXME: 执行时从注册表中获取
        MFValue *result = self.funcImp.executeResult;
        if (result.resultType == MFStatementResultTypeBreak) {
            result.resultType = MFStatementResultTypeNormal;
            return result;
        }else if(result.resultType == MFStatementResultTypeContinue){
            continue;
        }else{
            return result;
        }
    }
    //FIXME: 移除作用域
    return nil;
}@end
@implementation ORReturnStatement (Execute)
- (nullable MFValue *)executeResult {
    return nil;
}@end
@implementation ORBreakStatement (Execute)
- (nullable MFValue *)executeResult {
    return nil;
}@end
@implementation ORContinueStatement (Execute)
- (nullable MFValue *)executeResult {
    return nil;
}@end
@implementation ORPropertyDeclare(Execute)
- (nullable MFValue *)executeResult {
    return nil;
}@end
@implementation ORMethodDeclare(Execute)
- (nullable MFValue *)executeResult {
    return nil;
}@end
@implementation ORMethodImplementation(Execute)
- (nullable MFValue *)executeResult {
    return nil;
}@end
@implementation ORClass(Execute)
- (nullable MFValue *)executeResult {
    return nil;
}@end

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
