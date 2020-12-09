//
//  ORTestClassIvar.h
//  OCRunnerTests
//
//  Created by Jiang on 2020/5/15.
//  Copyright © 2020 SilverFruity. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ORTestClassIvar : NSObject
{
    NSString *_objectIvar;
    int _intIvar;
    unsigned int _uintIvar;
    double _doubleIvar;
}
- (nullable NSString *)testObjectIvar;
- (int)testIntIvar;
- (unsigned int)testUIntIvar;
- (double)testDoubleIvar;
@end

NS_ASSUME_NONNULL_END
