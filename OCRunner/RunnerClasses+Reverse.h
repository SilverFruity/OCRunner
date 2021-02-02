//
//  RunnerClasses+Reverse.h
//  OCRunner
//
//  Created by Jiang on 2021/2/1.
//

#import <Foundation/Foundation.h>
#import <ORPatchFile/ORPatchFile.h>
NS_ASSUME_NONNULL_BEGIN
@protocol OCReverse <NSObject>
- (void)reverse;
@end

@interface ORNode (Reverse) <OCReverse>
- (void)reverse;
@end

NS_ASSUME_NONNULL_END
