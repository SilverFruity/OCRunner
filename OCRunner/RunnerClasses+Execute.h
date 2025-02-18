//
//  ORunner+Execute.h
//  MangoFix
//
//  Created by Jiang on 2020/5/8.
//  Copyright © 2020 yongpengliang. All rights reserved.
//

// Cocoapods
#import <ORPatchFile/ORPatchFile.h>
// While need compile static framework
//#import "ORPatchFile.h"
#import <objc/runtime.h>


@class MFValue;
NS_ASSUME_NONNULL_BEGIN
@class MFScopeChain;

MFValue *evalORNode(ORNode *node, MFScopeChain * scope);

@interface ORMethodCall (Execute)
#if DEBUG
- (NSString *)unrecognizedSelectorTip:(id)instance;
#endif
@end

@interface ORPropertyDeclare (Execute)
@property (nonatomic, assign, readonly)  const objc_property_attribute_t * propertyAttributes;
@end


NS_ASSUME_NONNULL_END
