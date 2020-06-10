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
@class ORTypeVarPair;
@class ORFuncVariable;
@interface ORSearchedFunction : NSObject <OCExecute>
@property (nonatomic,strong)ORTypeVarPair *funPair;
@property (nonatomic,strong,readonly)ORFuncVariable *funVar;
@property (nonatomic,copy)NSString *name;
@property (nonatomic,assign)void *pointer;
+ (NSDictionary <NSString *, ORSearchedFunction *>*)functionTableForNames:(NSArray *)names;
@end

NS_ASSUME_NONNULL_END
