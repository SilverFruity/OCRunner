//
//  MFWeakPropertyBox.h
//  MangoFix
//
//  Created by yongpengliang on 2019/4/26.
//  Copyright © 2019 yongpengliang. All rights reserved.
//

#import <Foundation/Foundation.h>
@class MFValue;
NS_ASSUME_NONNULL_BEGIN

@interface MFWeakPropertyBox : NSObject

@property (weak)MFValue *target;

- (instancetype)initWithTarget:(MFValue *)target;

@end

NS_ASSUME_NONNULL_END
