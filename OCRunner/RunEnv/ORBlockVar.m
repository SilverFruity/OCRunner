//
//  ORBlockValue.m
//  OCRunner
//
//  Created by Jiang on 2020/5/14.
//  Copyright © 2020 SilverFruity. All rights reserved.
//

#import "ORBlockVar.h"

@implementation ORBlockVar
- (instancetype)initWithImp:(ORBlockImp *)imp scope:(MFScopeChain *)scope{
    self = [super init];
    self.func = imp;
    self.outScope = scope;
    return self;
}
- (MFValue *)execute{
    return [self.func execute:self.outScope];
}
@end
