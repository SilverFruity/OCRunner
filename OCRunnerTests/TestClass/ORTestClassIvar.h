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
    NSObject *_objectIvar;
    int _intIvar;
}
- (nullable id)testObjectIvar;
- (NSInteger)testIntIvar;
@end

NS_ASSUME_NONNULL_END
