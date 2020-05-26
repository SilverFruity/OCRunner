//
//  ORTypeVarPair+TypeEncode.h
//  OCRunner
//
//  Created by Jiang on 2020/5/26.
//  Copyright © 2020 SilverFruity. All rights reserved.
//

#import <oc2mangoLib/oc2mangoLib.h>

NS_ASSUME_NONNULL_BEGIN

@interface ORTypeVarPair (TypeEncode)
- (const char *)typeEncode;
@end




@interface ORTypeVarPair(Instance)
+ (instancetype)typePairWithTypeKind:(TypeKind)type;
+ (instancetype)objectTypePair;
+ (instancetype)pointerTypePair;
@end
NS_ASSUME_NONNULL_END
