//
//  ORCallSuperNoArgTest.h
//  OCRunnerTests
//
//  Created by Jiang on 2020/5/15.
//  Copyright © 2020 SilverFruity. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


@interface MFCallSuperNoArgTestSupserTest : NSObject

- (BOOL)testCallSuperNoArgTestSupser;

@property(nonatomic, assign, getter=customGetterTest, setter=customSetterTest:) BOOL test;

@end

@interface MFCallSuperNoArgTest : MFCallSuperNoArgTestSupserTest

- (BOOL)testCallSuperNoArgTestSupser;

@end

@interface Car : NSObject

- (int)run;

@end

@interface BMW : Car

- (int)run;

@end

@interface MiniBMW : BMW

@end

NS_ASSUME_NONNULL_END
