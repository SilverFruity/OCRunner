//
//  TestFakeModel.h
//  OCRunnerDemoTests
//
//  Created by carefree on 2021/11/25.
//  Copyright © 2021 SilverFruity. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TestFakeSubModel : NSObject

@property (nonatomic, assign) CGFloat numberToFloat;
@property (nonatomic, copy) NSString *numberToString;
@property (nonatomic, assign) NSInteger stringToInteger;

@end

@interface TestFakeModel : NSObject
@property (nonatomic, assign) NSInteger numberToInteger;
@property (nonatomic, copy) NSString *numberToString;
@property (nonatomic, strong) TestFakeSubModel *sub;
@end

@interface TestFakeModel (TestProperty)
@property (nonatomic, assign) int categoryProperty;
@end

NS_ASSUME_NONNULL_END
