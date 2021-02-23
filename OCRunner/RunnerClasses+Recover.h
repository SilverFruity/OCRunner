//
//  RunnerClasses+Reverse.h
//  OCRunner
//
//  Created by Jiang on 2021/2/1.
//

#import <Foundation/Foundation.h>
#import <ORPatchFile/ORPatchFile.h>
NS_ASSUME_NONNULL_BEGIN
@protocol OCRecover <NSObject>
- (void)recover;
@end

@interface ORNode (Recover) <OCRecover>
- (void)recover;
@end

NS_ASSUME_NONNULL_END
