//
//  ORBlockValue.h
//  OCRunner
//
//  Created by Jiang on 2020/5/14.
//  Copyright © 2020 SilverFruity. All rights reserved.
//

#import <OCRunner/OCRunner.h>

NS_ASSUME_NONNULL_BEGIN

@interface ORBlockVar: NSObject
@property (strong, nonatomic) MFScopeChain *outScope;
@property (strong, nonatomic) ORBlockImp *func;
- (instancetype)initWithImp:(ORBlockImp *)imp scope:(MFScopeChain *)scope;
- (MFValue *)execute;
@end

NS_ASSUME_NONNULL_END
