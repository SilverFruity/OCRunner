//
//  ORunner.m
//  MangoFix
//
//  Created by Jiang on 2020/4/26.
//  Copyright © 2020 yongpengliang. All rights reserved.
//

#import "RunnerClasses.h"
@implementation ORCodeCheck
@end
@implementation ORTypeSpecial
+ (instancetype)specialWithType:(TypeKind)type name:(NSString *)name{
    ORTypeSpecial *s = [ORTypeSpecial new];
    s.type = type;
    s.name = name;
    return s;
}
@end
@implementation ORVariable
+ (instancetype)copyFromVar:(ORVariable *)var{
    ORVariable *new = [[self class] new];
    new.ptCount = var.ptCount;
    new.varname = var.varname;
    return new;
}
@end
@implementation ORTypeVarPair
@end
@implementation ORFuncVariable
@end
@implementation ORFuncDeclare
- (BOOL)isBlockDeclare{
    return self.var.ptCount < 0;
}
- (void)becomeNormalFuncDeclare{
    self.var.ptCount = 0;
}
@end
@implementation ORExpression
@end
@implementation ORValueExpression
@end
@implementation ORMethodCall
@end
@implementation ORCFuncCall
@end
@implementation ORBlockImp
- (instancetype)init
{
    self = [super init];
    self.statements = [NSMutableArray array];
    return self;
}
- (void)addStatements:(id)statements{
    if ([statements isKindOfClass:[NSArray class]]) {
        [self.statements addObjectsFromArray:statements];
    }else{
        [self.statements addObject:statements];
    }
}
- (void)copyFromImp:(ORBlockImp *)imp{
    self.statements = imp.statements;
}
@end
@implementation ORSubscriptExpression
@end
@implementation ORAssignExpression
@end
@implementation ORDeclareExpression
@end
@implementation ORUnaryExpression
@end
@implementation ORBinaryExpression
@end
@implementation ORTernaryExpression
- (instancetype)init
{
    self = [super init];
    self.values = [NSMutableArray array];
    return self;
}
@end
@implementation ORStatement
@end
@implementation ORIfStatement
@end
@implementation ORWhileStatement
@end
@implementation ORDoWhileStatement
@end
@implementation ORCaseStatement
@end
@implementation ORSwitchStatement
- (instancetype)init
{
    self = [super init];
    self.cases = [NSMutableArray array];
    return self;
}
@end
@implementation ORForStatement
@end
@implementation ORForInStatement
@end
@implementation ORReturnStatement
@end
@implementation ORBreakStatement
@end
@implementation ORContinueStatement
@end
@implementation ORPropertyDeclare
@end
@implementation ORMethodDeclare
@end
@implementation ORMethodImplementation
@end
@implementation ORClass
@end

