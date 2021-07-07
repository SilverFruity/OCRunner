//
//  ORunner+Execute.h
//  MangoFix
//
//  Created by Jiang on 2020/5/8.
//  Copyright © 2020 yongpengliang. All rights reserved.
//

#import <ORPatchFile/ORPatchFile.h>
//#import <oc2mangoLib/oc2mangoLib.h>
#import <objc/runtime.h>


@class MFValue;
NS_ASSUME_NONNULL_BEGIN
@class MFScopeChain;
@protocol OCExecute <NSObject>
- (nullable MFValue *)execute:(MFScopeChain *)scope;
@end
@interface ORNode (Execute) <OCExecute>
- (nullable MFValue *)execute:(MFScopeChain *)scope;
@end
@interface ORTypeNode (Execute) <OCExecute>
- (nullable MFValue *)execute:(MFScopeChain *)scope;
@end
@interface ORVariableNode  (Execute) <OCExecute>
- (nullable MFValue *)execute:(MFScopeChain *)scope;
@end
@interface ORDeclaratorNode (Execute) <OCExecute>
- (nullable MFValue *)execute:(MFScopeChain *)scope;
@end

@interface ORFunctionDeclNode (Execute) <OCExecute>
- (nullable MFValue *)execute:(MFScopeChain *)scope;
@end
@interface ORValueNode  (Execute) <OCExecute>
- (nullable MFValue *)execute:(MFScopeChain *)scope;
@end
@interface ORMethodCall (Execute) <OCExecute>
- (nullable MFValue *)execute:(MFScopeChain *)scope;
@end
@interface ORFunctionCall (Execute) <OCExecute>
- (nullable MFValue *)execute:(MFScopeChain *)scope;
@end
@interface ORBlockNode (Execute) <OCExecute>
- (nullable MFValue *)execute:(MFScopeChain *)scope;
@end
@interface ORFunctionNode (Execute) <OCExecute>
- (nullable MFValue *)execute:(MFScopeChain *)scope;
@end
@interface ORSubscriptNode (Execute) <OCExecute>
- (nullable MFValue *)execute:(MFScopeChain *)scope;
@end
@interface ORAssignNode  (Execute) <OCExecute>
- (nullable MFValue *)execute:(MFScopeChain *)scope;
@end
@interface ORInitDeclaratorNode  (Execute) <OCExecute>
- (nullable MFValue *)execute:(MFScopeChain *)scope;
@end
@interface ORUnaryNode  (Execute) <OCExecute>
- (nullable MFValue *)execute:(MFScopeChain *)scope;
@end
@interface ORBinaryNode (Execute) <OCExecute>
- (nullable MFValue *)execute:(MFScopeChain *)scope;
@end
@interface ORTernaryNode (Execute) <OCExecute>
- (nullable MFValue *)execute:(MFScopeChain *)scope;
@end

@interface ORIfStatement  (Execute) <OCExecute>
- (nullable MFValue *)execute:(MFScopeChain *)scope;
@end
@interface ORWhileStatement  (Execute) <OCExecute>
- (nullable MFValue *)execute:(MFScopeChain *)scope;
@end
@interface ORDoWhileStatement  (Execute) <OCExecute>
- (nullable MFValue *)execute:(MFScopeChain *)scope;
@end
@interface ORCaseStatement  (Execute) <OCExecute>
- (nullable MFValue *)execute:(MFScopeChain *)scope;
@end
@interface ORSwitchStatement  (Execute) <OCExecute>
- (nullable MFValue *)execute:(MFScopeChain *)scope;
@end
@interface ORForStatement  (Execute) <OCExecute>
- (nullable MFValue *)execute:(MFScopeChain *)scope;
@end
@interface ORForInStatement  (Execute) <OCExecute>
- (nullable MFValue *)execute:(MFScopeChain *)scope;
@end
@interface ORControlStatNode  (Execute) <OCExecute>
- (nullable MFValue *)execute:(MFScopeChain *)scope;
@end
@interface ORPropertyNode (Execute) <OCExecute>
- (nullable MFValue *)execute:(MFScopeChain *)scope;
@property (nonatomic, assign, readonly)  const objc_property_attribute_t * propertyAttributes;
@end
@interface ORMethodDeclNode (Execute) <OCExecute>
- (nullable MFValue *)execute:(MFScopeChain *)scope;
@end
@interface ORMethodNode (Execute) <OCExecute>
- (nullable MFValue *)execute:(MFScopeChain *)scope;
@end
@interface ORClassNode (Execute) <OCExecute>
- (nullable MFValue *)execute:(MFScopeChain *)scope;
@end

@interface ORStructStatNode (Execute) <OCExecute>
- (nullable MFValue *)execute:(MFScopeChain *)scope;
@end

@interface OREnumStatNode (Execute) <OCExecute>
- (nullable MFValue *)execute:(MFScopeChain *)scope;
@end

@interface ORTypedefStatNode (Execute) <OCExecute>
- (nullable MFValue *)execute:(MFScopeChain *)scope;
@end

@interface ORProtocolNode (Execute) <OCExecute>
- (nullable MFValue *)execute:(MFScopeChain *)scope;
@end

@interface ORCArrayDeclNode (Execute) <OCExecute>
- (nullable MFValue *)execute:(MFScopeChain *)scope;
@end

@interface ORUnionStatNode (Execute) <OCExecute>
- (nullable MFValue *)execute:(MFScopeChain *)scope;
@end

NS_ASSUME_NONNULL_END
