//
//  ORORGCDTests.h
//  OCRunnerTests
//
//  Created by Jiang on 2020/5/20.
//  Copyright © 2020 SilverFruity. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ORGCDTests : NSObject
- (void)testGCDWithCompletionBlock:(void(^)(NSString * data))completion;
- (void)testGCDAfterWithCompletionBlock:(void(^)(NSString * data))completion;
- (BOOL)testDispatchSemaphore;
- (NSInteger)testDispatchSource;
@end

NS_ASSUME_NONNULL_END
