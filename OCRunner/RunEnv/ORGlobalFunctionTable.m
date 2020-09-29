//
//  ORFunctionTable.m
//  OCRunner
//
//  Created by Jiang on 2020/9/29.
//

#import "ORGlobalFunctionTable.h"

static ORGlobalFunctionTable *ORFunctionTableInstance = nil;

@implementation ORGlobalFunctionTable
+ (instancetype)shared{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ORFunctionTableInstance = [ORGlobalFunctionTable new];
    });
    return ORFunctionTableInstance;
}
- (instancetype)init
{
    self = [super init];
    if (self) {
        self.functions = [NSMutableDictionary dictionary];
    }
    return self;
}
- (void)setFunctionNode:(id)function WithName:(NSString *)name{
    self.functions[name] = function;
}
- (id)getFunctionNodeWithName:(NSString *)name{
    return self.functions[name];
}
@end
