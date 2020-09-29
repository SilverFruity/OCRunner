//
//  ORFunctionTable.h
//  OCRunner
//
//  Created by Jiang on 2020/9/29.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ORGlobalFunctionTable : NSObject
+ (instancetype)shared;
@property (strong, nonatomic) NSMutableDictionary<NSString *,id> *functions;
- (void)setFunctionNode:(id)function WithName:(NSString *)name;
- (id)getFunctionNodeWithName:(NSString *)name;
@end

NS_ASSUME_NONNULL_END
