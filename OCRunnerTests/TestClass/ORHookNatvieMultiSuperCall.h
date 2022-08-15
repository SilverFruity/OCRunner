//
//  ORHookNatvieMultiSuperCall.h
//  OCRunnerDemoTests
//
//  Created by Jiang on 2022/8/15.
//  Copyright © 2022 SilverFruity. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NativeFinalObject: NSObject
- (int)test:(int)count;
@end
@interface NativeHotBaseController: NativeFinalObject
@end
@interface NativeViewController3 : NativeHotBaseController
@end
NS_ASSUME_NONNULL_END
