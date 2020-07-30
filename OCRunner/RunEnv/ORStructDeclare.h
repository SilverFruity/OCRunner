//
//  MFStructDeclare.h
//  MangoFix
//
//  Created by jerry.yong on 2017/11/16.
//  Copyright © 2017年 yongpengliang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RunnerClasses+Execute.h"
NS_ASSUME_NONNULL_BEGIN

@interface ORStructDeclare : NSObject
@property (copy, nonatomic) NSString *name;
@property (assign, nonatomic)const char *typeEncoding;
@property (strong, nonatomic) NSArray<NSString *> *keys;
@property (strong, nonatomic) NSDictionary<NSString *,NSNumber *> *keyOffsets;
@property (strong, nonatomic) NSDictionary<NSString *,NSNumber *> *keySizes;
@property (strong, nonatomic) NSDictionary<NSString *,NSString *> *keyTypeEncodes;
+ (instancetype)structDecalre:(const char *)encode keys:(NSArray *)keys;
- (instancetype)initWithTypeEncode:(const char *)typeEncoding keys:(NSArray<NSString *> *)keys;

@end
@interface ORStructDeclareTable : NSObject
+ (instancetype)shareInstance;
- (void)addAlias:(NSString *)alias forTypeName:(NSString *)name;
- (void)addAlias:(NSString *)alias forStructTypeEncode:(const char *)typeEncode;
- (void)addStructDeclare:(ORStructDeclare *)structDeclare;
- (nullable ORStructDeclare *)getStructDeclareWithName:(NSString *)name;
@end


@interface ORTypeVarPair (Struct)
- (ORStructDeclare *)strcutDeclare;
@end

@interface ORSymbolItem: NSObject
@property (copy, nonatomic)NSString *typeEncode;
@property (copy, nonatomic)NSString *typeName;
@end

@interface ORTypeSymbolTable: NSObject
+ (instancetype)shareInstance;
- (void)addTypePair:(ORTypeVarPair *)typePair;
- (void)addTypePair:(ORTypeVarPair *)item forAlias:(NSString *)alias;
- (void)addSybolItem:(ORSymbolItem *)item forAlias:(NSString *)alias;
- (ORSymbolItem *)symbolItemForTypeName:(NSString *)typeName;
@end
NS_ASSUME_NONNULL_END
