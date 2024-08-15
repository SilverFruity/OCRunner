//
//  ORCallOCPropertyBlockTest.h
//  OCRunnerTests
//
//  Created by Jiang on 2020/5/15.
//  Copyright © 2020 SilverFruity. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ORCallOCPropertyBlockTest : NSObject
@property(copy,nonatomic) id(^propertyBlock)(id,id);
- (NSString *)testCallOCReturnBlock;

- (NSDictionary *)testCapture;
@end

NS_ASSUME_NONNULL_END
