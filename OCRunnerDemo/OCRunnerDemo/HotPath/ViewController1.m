//
//  ViewController.m
//  OCRunnerDemo
//
//  Created by Jiang on 2020/5/23.
//  Copyright © 2020 SilverFruity. All rights reserved.
//

#import "ViewController.h"
#import <Masonry/Masonry.h>
void cfunctionCallBlock(void (^block)(NSString *)){
    if (block) block(@"cfunctionCallBlock");
}
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
    self.cache = @{@"1":@"100",@"2":@"2"};
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
    UIButton *swiftButton = [[UIButton alloc] initWithFrame:CGRectMake(150,150,200,40)];
    [swiftButton setTitle:@"SwiftViewController" forState:UIControlStateNormal];
    [swiftButton setTitleColor:UIColor.blueColor forState:UIControlStateNormal];
    [swiftButton addTarget:self action:@selector(pushSwiftControlelr1) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:swiftButton];
    
    self.view.backgroundColor = UIColor.whiteColor;
    UIView *view = [[UIView alloc] init];
    view.backgroundColor = [UIColor redColor];
    [self.view addSubview:view];
    [view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.view);
        make.width.equalTo(@(200));
        make.height.equalTo(@(200));
    }];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:0.25 animations:^{
            view.transform = CGAffineTransformScale(view.transform, 0.5, 0.5);
        }];
    });
    UIView *frameView = [[UIView alloc] initWithFrame:CGRectMake(0, 100, 50, 50)];
    frameView.backgroundColor = [UIColor greenColor];
    [self.view addSubview:frameView];
    
    UILabel *label = [UILabel new];
    [self.view addSubview:label];
    [label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.top.equalTo(self.view).offset(100);
    }];
    label.text = [[ShareInstance shared] cacheForKey:@"1"];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"点击" style:UIBarButtonItemStylePlain target:self action:@selector(showNext:)];
    NSLog(@"%@",@(-1));
    
    id vc = [[UIApplication sharedApplication].keyWindow.rootViewController childViewControllers].firstObject;
    [vc updateFrame];
    [self sendStackBlock];
    [self receiveStackBlock:nil];
    [self receiveStackBlock:^(NSString *str){ NSLog(@"%@",str); }];
    cfunctionCallBlock(nil);
    cfunctionCallBlock(^(NSString *str){ NSLog(@"%@",str); });
}
- (void)receiveStackBlock:(void (^)(NSString *))block{
    if (block) block(@"receiveStackBlock:");
}
- (void)showNext:(UIBarButtonItem *)sender{
    HotFixController *vc = [HotFixController new];
    __weak id weakVC = vc;
    vc.block = ^{
        __strong id strongSelf = weakVC;
        [weakVC.navigationController popViewControllerAnimated:YES];
        NSLog(@"%@",$curScope.vars[@"strongSelf"]);
    };
    vc.view.backgroundColor = [UIColor whiteColor];
    [self.navigationController pushViewController:vc animated:YES];
    NSLog(@"xxxxxxx%@", sender);
}
- (void)pushSwiftControlelr1{
    UIViewController *vc = [[NSClassFromString(@"OCRunnerDemo.SwiftViewController1") alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

@end

int fibonaccia(int n){
    if (n == 1 || n == 2)
        return 1;
    return fibonaccia(n - 1) + fibonaccia(n - 2);
}
fibonaccia(20);
