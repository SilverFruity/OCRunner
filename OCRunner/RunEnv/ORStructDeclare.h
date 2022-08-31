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
{
@private
    NSUInteger size_;
}

@property (copy, nonatomic) NSString *name;
@property (assign, nonatomic)const char *typeEncoding;
@property (strong, nonatomic) NSArray<NSString *> *keys;
@property (strong, nonatomic) NSDictionary<NSString *,NSNumber *> *keyOffsets;
@property (strong, nonatomic) NSDictionary<NSString *,NSNumber *> *keySizes;
@property (strong, nonatomic) NSDictionary<NSString *,NSString *> *keyTypeEncodes;
+ (instancetype)structDecalre:(const char *)encode keys:(NSArray *)keys;
- (instancetype)initWithTypeEncode:(const char *)typeEncoding keys:(NSArray<NSString *> *)keys;
- (NSInteger)structSize;
@end

@interface ORUnionDeclare : NSObject
@property (copy, nonatomic) NSString *name;
@property (assign, nonatomic)const char *typeEncoding;
@property (strong, nonatomic) NSArray<NSString *> *keys;
@property (strong, nonatomic) NSDictionary<NSString *,NSString *> *keyTypeEncodes;
+ (instancetype)unionDecalre:(const char *)encode keys:(NSArray *)keys;
@end

@interface ORTypeVarPair (Struct)
- (ORStructDeclare *)strcutDeclare;
@end

@interface ORSymbolItem: NSObject
@property (copy, nonatomic)NSString *typeEncode;
@property (copy, nonatomic)NSString *typeName;
@property (strong, nonatomic, nullable)id declare;
- (BOOL)isStruct;
- (BOOL)isUnion;
- (BOOL)isCArray;
@end

@interface ORTypeSymbolTable: NSObject
+ (instancetype)shareInstance;

- (ORSymbolItem *)addTypePair:(ORTypeVarPair *)typePair;
- (ORSymbolItem *)addTypePair:(ORTypeVarPair *)item forAlias:(NSString *)alias;

- (ORSymbolItem *)addUnion:(ORUnionDeclare *)declare;
- (ORSymbolItem *)addStruct:(ORStructDeclare *)declare;
- (ORSymbolItem *)addUnion:(ORUnionDeclare *)declare forAlias:(NSString *)alias;
- (ORSymbolItem *)addStruct:(ORStructDeclare *)declare forAlias:(NSString *)alias;
- (void)addSybolItem:(ORSymbolItem *)item forAlias:(NSString *)alias;
- (ORSymbolItem *)symbolItemForTypeName:(NSString *)typeName;
- (void)addCArray:(ORCArrayVariable *)cArray typeEncode:(const char *)typeEncode;
- (ORSymbolItem *)symbolItemForNode:(ORNode *)node;
- (void)clear;
@end
NS_ASSUME_NONNULL_END
