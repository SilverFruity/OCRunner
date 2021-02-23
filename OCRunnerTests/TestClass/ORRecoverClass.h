//
//  ORRecoverClass.h
//  OCRunnerDemoTests
//
//  Created by Jiang on 2021/2/23.
//  Copyright © 2021 SilverFruity. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ORRecoverClass : NSObject
@property (nonatomic, assign)int value1;
@property (nonatomic, copy)NSString *value2;
+ (int)classMethodTest;
- (int)methodTest1;
- (int)methodTest2;
@end

NS_ASSUME_NONNULL_END
