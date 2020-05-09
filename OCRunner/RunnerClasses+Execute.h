//
//  ORunner+Execute.h
//  MangoFix
//
//  Created by Jiang on 2020/5/8.
//  Copyright © 2020 yongpengliang. All rights reserved.
//

#import "RunnerClasses.h"
#import "MFValue.h"
NS_ASSUME_NONNULL_BEGIN

@interface ORTypeSpecial (Execute)
- (nullable MFValue *)execute:(MFScopeChain *)scope;
@end
@interface ORVariable  (Execute)
- (nullable MFValue *)execute:(MFScopeChain *)scope;
@end
@interface ORTypeVarPair (Execute)
- (nullable MFValue *)execute:(MFScopeChain *)scope;
@end
@interface ORFuncVariable (Execute)
- (nullable MFValue *)execute:(MFScopeChain *)scope;
@end
@interface ORFuncDeclare (Execute)
- (nullable MFValue *)execute:(MFScopeChain *)scope;
@end
@interface ORValueExpression  (Execute)
- (nullable MFValue *)execute:(MFScopeChain *)scope;
@end
@interface ORMethodCall (Execute)
- (nullable MFValue *)execute:(MFScopeChain *)scope;
@end
@interface ORCFuncCall (Execute)
- (nullable MFValue *)execute:(MFScopeChain *)scope;
@end
@interface ORBlockImp (Execute)
- (nullable MFValue *)execute:(MFScopeChain *)scope;
@end
@interface OCCollectionGetValue (Execute)
- (nullable MFValue *)execute:(MFScopeChain *)scope;
@end
@interface ORAssignExpression  (Execute)
- (nullable MFValue *)execute:(MFScopeChain *)scope;
@end
@interface ORDeclareExpression  (Execute)
- (nullable MFValue *)execute:(MFScopeChain *)scope;
@end
@interface ORUnaryExpression  (Execute)
- (nullable MFValue *)execute:(MFScopeChain *)scope;
@end
@interface ORBinaryExpression (Execute)
- (nullable MFValue *)execute:(MFScopeChain *)scope;
@end
@interface ORTernaryExpression (Execute)
- (nullable MFValue *)execute:(MFScopeChain *)scope;
@end
@interface ORStatement  (Execute)
- (nullable MFValue *)execute:(MFScopeChain *)scope;
@end
@interface ORIfStatement  (Execute)
- (nullable MFValue *)execute:(MFScopeChain *)scope;
@end
@interface ORWhileStatement  (Execute)
- (nullable MFValue *)execute:(MFScopeChain *)scope;
@end
@interface ORDoWhileStatement  (Execute)
- (nullable MFValue *)execute:(MFScopeChain *)scope;
@end
@interface ORCaseStatement  (Execute)
- (nullable MFValue *)execute:(MFScopeChain *)scope;
@end
@interface ORSwitchStatement  (Execute)
- (nullable MFValue *)execute:(MFScopeChain *)scope;
@end
@interface ORForStatement  (Execute)
- (nullable MFValue *)execute:(MFScopeChain *)scope;
@end
@interface ORForInStatement  (Execute)
- (nullable MFValue *)execute:(MFScopeChain *)scope;
@end
@interface ORReturnStatement  (Execute)
- (nullable MFValue *)execute:(MFScopeChain *)scope;
@end
@interface ORBreakStatement  (Execute)
- (nullable MFValue *)execute:(MFScopeChain *)scope;
@end
@interface ORContinueStatement  (Execute)
- (nullable MFValue *)execute:(MFScopeChain *)scope;
@end
@interface ORPropertyDeclare (Execute)
- (nullable MFValue *)execute:(MFScopeChain *)scope;
@end
@interface ORMethodDeclare (Execute)
- (nullable MFValue *)execute:(MFScopeChain *)scope;
@end
@interface ORMethodImplementation (Execute)
- (nullable MFValue *)execute:(MFScopeChain *)scope;
@end
@interface ORClass (Execute)
- (nullable MFValue *)execute:(MFScopeChain *)scope;
@end

char *const OCTypeEncodingForPair(ORTypeVarPair * pair);

NS_ASSUME_NONNULL_END
