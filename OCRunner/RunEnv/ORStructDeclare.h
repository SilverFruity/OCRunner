//
//  MFStructDeclare.h
//  MangoFix
//
//  Created by jerry.yong on 2017/11/16.
//  Copyright © 2017年 yongpengliang. All rights reserved.
//

#import <Foundation/Foundation.h>
NSMutableArray * startStructDetect(const char *typeEncode);
NSMutableArray * startDetectTypeEncode(NSString *content);
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
