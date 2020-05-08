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
- (nullable MFValue *)executeResult;
@end
@interface ORVariable  (Execute)
- (nullable MFValue *)executeResult;
@end
@interface ORTypeVarPair (Execute)
- (nullable MFValue *)executeResult;
@end
@interface ORFuncVariable (Execute)
- (nullable MFValue *)executeResult;
@end
@interface ORFuncDeclare (Execute)
- (nullable MFValue *)executeResult;
@end
@interface ORValueExpression  (Execute)
- (nullable MFValue *)executeResult;
@end
@interface ORMethodCall (Execute)
- (nullable MFValue *)executeResult;
@end
@interface ORCFuncCall (Execute)
- (nullable MFValue *)executeResult;
@end
@interface ORBlockImp (Execute)
- (nullable MFValue *)executeResult;
@end
@interface OCCollectionGetValue (Execute)
- (nullable MFValue *)executeResult;
@end
@interface ORAssignExpression  (Execute)
- (nullable MFValue *)executeResult;
@end
@interface ORDeclareExpression  (Execute)
- (nullable MFValue *)executeResult;
@end
@interface ORUnaryExpression  (Execute)
- (nullable MFValue *)executeResult;
@end
@interface ORBinaryExpression (Execute)
- (nullable MFValue *)executeResult;
@end
@interface ORTernaryExpression (Execute)
- (nullable MFValue *)executeResult;
@end
@interface ORStatement  (Execute)
- (nullable MFValue *)executeResult;
@end
@interface ORIfStatement  (Execute)
- (nullable MFValue *)executeResult;
@end
@interface ORWhileStatement  (Execute)
- (nullable MFValue *)executeResult;
@end
@interface ORDoWhileStatement  (Execute)
- (nullable MFValue *)executeResult;
@end
@interface ORCaseStatement  (Execute)
- (nullable MFValue *)executeResult;
@end
@interface ORSwitchStatement  (Execute)
- (nullable MFValue *)executeResult;
@end
@interface ORForStatement  (Execute)
- (nullable MFValue *)executeResult;
@end
@interface ORForInStatement  (Execute)
- (nullable MFValue *)executeResult;
@end
@interface ORReturnStatement  (Execute)
- (nullable MFValue *)executeResult;
@end
@interface ORBreakStatement  (Execute)
- (nullable MFValue *)executeResult;
@end
@interface ORContinueStatement  (Execute)
- (nullable MFValue *)executeResult;
@end
@interface ORPropertyDeclare (Execute)
- (nullable MFValue *)executeResult;
@end
@interface ORMethodDeclare (Execute)
- (nullable MFValue *)executeResult;
@end
@interface ORMethodImplementation (Execute)
- (nullable MFValue *)executeResult;
@end
@interface ORClass (Execute)
- (nullable MFValue *)executeResult;
@end

char *const OCTypeEncodingForPair(ORTypeVarPair * pair);

NS_ASSUME_NONNULL_END
