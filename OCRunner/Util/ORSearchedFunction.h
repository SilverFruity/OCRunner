//
//  ORSearchedFunction.h
//  OCRunner
//
//  Created by Jiang on 2020/6/9.
//  Copyright © 2020 SilverFruity. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RunnerClasses+Execute.h"
NS_ASSUME_NONNULL_BEGIN

@interface ORSearchedFunction : NSObject
@property (nonatomic,strong)ORDeclaratorNode *funPair;
@property (nonatomic,strong,readonly)ORFunctionDeclNode *funVar;
@property (nonatomic,copy)NSString *name;
@property (nonatomic,assign)void *pointer;
+ (instancetype)functionWithName:(NSString *)name;
+ (NSDictionary <NSString *, ORSearchedFunction *>*)functionTableForNames:(NSArray *)names;
- (nullable MFValue *)execute:(nonnull MFScopeChain *)scope;
@end

NS_ASSUME_NONNULL_END
