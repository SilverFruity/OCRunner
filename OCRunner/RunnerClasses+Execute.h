//
//  ORunner+Execute.h
//  MangoFix
//
//  Created by Jiang on 2020/5/8.
//  Copyright © 2020 yongpengliang. All rights reserved.
//

#import "RunnerClasses.h"
#import "MFValue.h"
#import <objc/runtime.h>
NS_ASSUME_NONNULL_BEGIN
@class MFScopeChain;
@protocol OCExecute <NSObject>
- (nullable MFValue *)execute:(MFScopeChain *)scope;
@end
@interface ORExpression (Execute) <OCExecute>
- (nullable MFValue *)execute:(MFScopeChain *)scope;
@end
@interface ORFuncDeclare (Execute) <OCExecute>
- (nullable MFValue *)execute:(MFScopeChain *)scope;
@end
@interface ORBlockImp (Execute) <OCExecute>
- (nullable MFValue *)execute:(MFScopeChain *)scope;
@end
@interface ORStatement  (Execute) <OCExecute>
- (nullable MFValue *)execute:(MFScopeChain *)scope;
@end
@interface ORPropertyDeclare (Execute) <OCExecute>
- (nullable MFValue *)execute:(MFScopeChain *)scope;
@property (nonatomic, assign)  const objc_property_attribute_t * propertyAttributes;
@end
@interface ORMethodDeclare (Execute) <OCExecute>
- (nullable MFValue *)execute:(MFScopeChain *)scope;
@end
@interface ORMethodImplementation (Execute) <OCExecute>
- (nullable MFValue *)execute:(MFScopeChain *)scope;
@end
@interface ORClass (Execute) <OCExecute>
- (nullable MFValue *)execute:(MFScopeChain *)scope;
@end

char *const OCTypeEncodingForPair(ORTypeVarPair * pair);

NS_ASSUME_NONNULL_END
