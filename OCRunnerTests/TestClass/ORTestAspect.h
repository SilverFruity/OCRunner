//
//  ORTestAspect.h
//  OCRunnerDemoTests
//
//  Created by 程聪 on 2025/12/29.
//  Copyright © 2025 SilverFruity. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ORTestAspect : NSObject
@property(nonatomic, strong) id argFromOrigin;
@property(nonatomic, strong) id argFromHotfix;
@property(nonatomic, strong) id argFromAspect;

- (void)foo:(id)arg;
@end

NS_ASSUME_NONNULL_END
