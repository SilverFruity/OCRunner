//
//  ORCallFrameStack.m
//  OCRunner
//
//  Created by Jiang on 2021/6/4.
//
#import "ORCallFrameStack.h"
#import "MFValue.h"
#import "MFScopeChain.h"
@interface ORCallFrameStack()
@property(nonatomic, strong) NSMutableArray<NSArray *> *array;
@end
@implementation ORCallFrameStack
- (instancetype)init
{
    self = [super init];
    if (self) {
        self.array = [NSMutableArray array];
    }
    return self;
}
+ (void)pushMethodCall:(ORMethodNode *)imp instance:(MFValue *)instance{
    [[ORCallFrameStack threadStack].array addObject:@[instance, imp]];
}
+ (void)pushFunctionCall:(ORFunctionNode *)imp scope:(MFScopeChain *)scope{
    [[ORCallFrameStack threadStack].array addObject:@[scope, imp]];
}
+ (void)pop{
    [[ORCallFrameStack threadStack].array removeLastObject];
}

+ (NSString *)history{
    NSMutableArray *frames = [ORCallFrameStack threadStack].array;
    NSMutableString *log = [@"OCRunner Frames:\n\n" mutableCopy];
//    for (int i = 0; i < frames.count; i++) {
//        NSArray *frame = frames[i];
//        if ([frame.firstObject isKindOfClass:[MFValue class]]) {
//            MFValue *instance = frame.firstObject;
//            ORMethodNode *imp = frame.lastObject;
//            
//            [log appendFormat:@"%@ %@ %@\n", imp.declare.isClassMethod ? @"+" : @"-", instance.objectValue, imp.declare.selectorName];
//        }else{
//            MFScopeChain *scope = frame.firstObject;
//            ORFunctionNode *imp = frame.lastObject;
//            if (imp.declare.var.varname == nil){
//                [log appendFormat:@"Block Call: Captured external variables '%@' \n",[scope.vars.allKeys componentsJoinedByString:@","]];
//                // 比如dispatch_after中的block，此时只会孤零零的提醒你一个Block Call
//                // 异步调用时，此时通过语法树回溯，可以定位到 block 所在的类以及方法名
//                if (i == 0) {
//                    ORNode *parent = imp.parentNode;
//                    while (parent != nil ) {
//                        if ([parent isKindOfClass:[ORClassNode class]]) {
//                            [log appendFormat:@"Block Code in Class: %@\n", [(ORClassNode *)parent className]];
//                        }else if ([parent isKindOfClass:[ORMethodNode class]]){
//                            ORMethodNode *imp = (ORMethodNode *)parent;
//                            [log appendFormat:@"Block Code in Method: %@%@\n", imp.declare.isClassMethod ? @"+" : @"-", imp.declare.selectorName];
//                        }else if ([parent isKindOfClass:[ORFunctionCall class]]){
//                            ORFunctionCall *imp = (ORFunctionCall *)parent;
//                            [log appendFormat:@"Block Code in Function call: %@\n", [(ORValueNode *)imp.caller value]];
//                        }else if ([parent isKindOfClass:[ORMethodCall class]]){
//                            ORMethodCall *imp = (ORMethodCall *)parent;
//                            [log appendFormat:@"Block Code in Method call: %@\n", imp.selectorName];
//                        }else if ([parent isKindOfClass:[ORInitDeclaratorNode class]]){
//                            ORInitDeclaratorNode *imp = (ORInitDeclaratorNode *)parent;
//                            [log appendFormat:@"Block Code in Decl: %@ %@\n", imp.declarator.type.name, imp.declarator.var.varname];
//                        }
//                        parent = parent.parentNode;
//                    }
//                }
//            }else{
//                [log appendFormat:@" CFunction: %@\n", imp.declare.var.varname];
//            }
//        }
//    }
    return log;
}
@end
