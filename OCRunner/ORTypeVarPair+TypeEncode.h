//
//  ORTypeVarPair+TypeEncode.h
//  OCRunner
//
//  Created by Jiang on 2020/5/26.
//  Copyright © 2020 SilverFruity. All rights reserved.
//

#import "RunnerClasses+Execute.h"

NS_ASSUME_NONNULL_BEGIN

@interface ORDeclaratorNode (TypeEncode)
- (const char *)blockSignature;
- (const char *)typeEncode;
@end




@interface ORDeclaratorNode(Instance)
+ (instancetype)typePairWithTypeKind:(OCType)type;
+ (instancetype)objectTypePair;
+ (instancetype)pointerTypePair;
@end

ORDeclaratorNode * ORTypeVarPairForTypeEncode(const char *typeEncode);
NS_ASSUME_NONNULL_END
