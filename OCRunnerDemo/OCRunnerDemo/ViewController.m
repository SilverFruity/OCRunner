//
//  ViewController.m
//  OCRunnerDemo
//
//  Created by Jiang on 2020/5/23.
//  Copyright © 2020 SilverFruity. All rights reserved.
//

#import "ViewController.h"
#import <Masonry/Masonry.h>
#import <MFBlock.h>
#import <WebKit/WebKit.h>
#if __has_include(<Aspects/Aspects.h>)
#import <Aspects/Aspects.h>
#endif

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


@interface ViewController () <WKNavigationDelegate>
@property (nonatomic, strong)WKWebView *webView;
@end

@implementation ViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor grayColor];
    WKWebView *webView = [WKWebView new];
    webView.navigationDelegate = self;
    [self.view addSubview:webView];
    [webView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.equalTo(@(150));
        make.right.equalTo(self.view);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom);
    }];
    [webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://www.baidu.com"]]];

#if __has_include(<Aspects/Aspects.h>)
    UIButton *aspectButton = ({
        UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(50, 300, 150, 50)];
        [button setTitle:@"Test Aspect" forState:UIControlStateNormal];
        [button addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
        button.backgroundColor = UIColor.blackColor;
        button;
    });
    [self.view addSubview:aspectButton];

    [self aspect_hookSelector:@selector(buttonAction:)
                  withOptions:AspectPositionBefore
                   usingBlock:^(id<AspectInfo> aspectInfo, UIButton *sender) {
                       NSLog(@"buttonAction aspects, sender: %@", sender);
                   }
                        error:nil];
#endif
}

#if __has_include(<Aspects/Aspects.h>)
- (void)buttonAction:(UIButton *)sender
{
    NSLog(@"buttonAction origin, sender: %@", sender);
}
#endif

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler{
    decisionHandler(WKNavigationActionPolicyAllow);
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
