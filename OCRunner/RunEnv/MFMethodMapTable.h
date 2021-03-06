//
//  MFMethodMapTable.h
//  MangoFix
//
//  Created by jerry.yong on 2018/2/23.
//  Copyright © 2018年 yongpengliang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RunnerClasses+Execute.h"

NS_ASSUME_NONNULL_BEGIN

@interface MFMethodMapTableItem:NSObject

@property (strong, nonatomic) Class clazz;
@property (strong, nonatomic) ORMethodImplementation *methodImp;

- (instancetype)initWithClass:(Class)clazz method:(ORMethodImplementation *)method;

@end

@interface MFMethodMapTable : NSObject

+ (instancetype)shareInstance;
- (void)removeMethodsForClass:(Class)clazz;
- (void)addMethodMapTableItem:(MFMethodMapTableItem *)methodMapTableItem;
- (nullable MFMethodMapTableItem *)getMethodMapTableItemWith:(Class)clazz classMethod:(BOOL)classMethod sel:(SEL)sel;


@end

NS_ASSUME_NONNULL_END
