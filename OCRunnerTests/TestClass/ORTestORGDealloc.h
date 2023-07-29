//
//  ORTestORGDealloc.h
//  OCRunnerDemoTests
//
//  Created by Jiang on 2023/7/29.
//  Copyright © 2023 SilverFruity. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ORTestORGDealloc : NSObject
@property (nonatomic, assign)int *counter;
- (instancetype)initWithCounter:(int *)counter;
@end

NS_ASSUME_NONNULL_END
