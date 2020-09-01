//
//  MFPropertyMapTable.h
//  MangoFix
//
//  Created by yongpengliang on 2019/4/26.
//  Copyright © 2019 yongpengliang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RunnerClasses+Execute.h"

NS_ASSUME_NONNULL_BEGIN

@interface MFPropertyMapTableItem:NSObject

@property (strong, nonatomic) Class clazz;
@property (strong, nonatomic) ORPropertyDeclare *property;

- (instancetype)initWithClass:(Class)clazz  property:(ORPropertyDeclare *)property;

@end

@interface MFPropertyMapTable : NSObject
{
@public
NSMutableDictionary<NSString *, MFPropertyMapTableItem *> *_dic;
}
+ (instancetype)shareInstance;

- (void)addPropertyMapTableItem:(MFPropertyMapTableItem *)propertyMapTableItem;
- (nullable MFPropertyMapTableItem *)getPropertyMapTableItemWith:(Class)clazz name:(NSString *)name;


@end

NS_ASSUME_NONNULL_END
