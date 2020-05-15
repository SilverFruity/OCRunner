//
//  ORTestClassProperty.h
//  OCRunnerTests
//
//  Created by Jiang on 2020/5/15.
//  Copyright © 2020 SilverFruity. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ORTestClassProperty : NSObject
@property(nonatomic,copy)NSString *strTypeProperty;
@property (assign, nonatomic) NSInteger num;
- (NSString *)testObjectPropertyTest;
- (id)testWeakObjectProperty;
- (id)testIvar;
- (NSInteger)testProMathAdd;

- (NSInteger)testBasePropertyTest;
- (NSInteger)testPropertyIvar;
@end

NS_ASSUME_NONNULL_END
