//
//  ORWeakPropertyAndIvar.h
//  OCRunnerDemoTests
//
//  Created by Jiang on 2020/12/9.
//  Copyright © 2020 SilverFruity. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ORWeakPropertyAndIvar : NSObject
@property (nonatomic, strong)NSMutableString *container;
- (instancetype)initWithContainer:(NSMutableString *)container;
- (void)propertyStrong;
- (void)propertyWeak;
- (void)ivarStrong;
- (void)ivarWeak;
@end

NS_ASSUME_NONNULL_END
