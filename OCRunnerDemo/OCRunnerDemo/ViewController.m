//
//  ViewController.m
//  OCRunnerDemo
//
//  Created by Jiang on 2020/5/23.
//  Copyright © 2020 SilverFruity. All rights reserved.
//

#import "ViewController.h"
#import <Masonry/Masonry.h>
#import <OCRunner/MFBlock.h>
@interface ShareInstance: NSObject
@property (nonatomic,copy)NSDictionary *cache;
@end
@implementation ShareInstance

+ (instancetype)shared{
    static id _instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [ShareInstance new];
    });
    return _instance;
}
- (instancetype)init
{
    self = [super init];
    self.cache = @{@"1":@"0",@"2":@"2"};
    return self;
}
- (NSString *)cacheForKey:(NSString *)key{
    return self.cache[key];
}
@end


@interface ViewController ()

@end

@implementation ViewController


- (void)viewDidLoad {
    [super viewDidLoad];

}
- (void)sendStackBlock{
    __weak typeof(self) weakSelf = self;
    [self receiveStackBlock:^(NSString *str) {
        NSLog(@"%@",weakSelf);
        NSLog(@"%@",str);
    }];
    [self receiveStackBlock:^(NSString *str) {
        NSLog(@"global block %@",str);
    }];
}
- (void)receiveStackBlock:(void (^)(NSString *str))block{
    if (block) {
        block(@"123");
    }
}
- (void)showNext:(UIBarButtonItem *)sender{
    UIViewController *vc = [NSClassFromString(@"HotFixController") new];
    if (vc) {
        [self.navigationController pushViewController:vc animated:YES];
    }
}
@end
