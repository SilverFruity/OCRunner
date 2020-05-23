//
//  MFStructDeclare.h
//  MangoFix
//
//  Created by jerry.yong on 2017/11/16.
//  Copyright © 2017年 yongpengliang. All rights reserved.
//

#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN
NSString *startRemovePointerOfTypeEncode(const char *typeEncode);
NSUInteger startDetectPointerCount(const char *typeEncode);
NSString *startStructNameDetect(const char *typeEncode);
NSMutableArray * startStructDetect(const char *typeEncode);
NSMutableArray * startDetectTypeEncodes(NSString *content);
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
- (void)addAlias:(NSString *)alias forTypeEncode:(const char *)typeEncode;
- (void)addStructDeclare:(ORStructDeclare *)structDeclare;
- (nullable ORStructDeclare *)getStructDeclareWithName:(NSString *)name;
@end
NS_ASSUME_NONNULL_END
