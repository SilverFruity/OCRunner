#import <Masonry/Masonry.h>
#import <UIKit/UIKit.h>
#import <MJRefresh/MJRefresh.h>

@implementation OCRunnerDemo.SwiftViewController
- (void)updateFrame:(NSObject *)arg arg1:(NSNumber *)arg1{
    [self ORGupdateFrame:arg arg1:arg1];
    NSLog(@"OC updateFrame %@ %@",arg,arg1);
}
@end

@interface HotFixController : UIViewController <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, copy) void (^block)(void);
@end

@implementation HotFixController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.tableView];
    self.tableView.backgroundColor = [UIColor redColor];
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.bottom.right.top.mas_equalTo(self.view);
    }];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    return nil;
}

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:(UITableViewStyleGrouped)];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.separatorStyle = UITableViewCellSelectionStyleNone;
        _tableView.showsVerticalScrollIndicator = NO;
        _tableView.estimatedRowHeight = 0;
        _tableView.estimatedSectionHeaderHeight = 0;
        _tableView.estimatedSectionFooterHeight = 0;
        _tableView.backgroundColor = [UIColor whiteColor];
        __weak typeof(self) weakSelf = self;
        _tableView.mj_header = [MJRefreshNormalHeader headerWithRefreshingBlock:^{
            __strong id strongSelf = weakSelf;
            [strongSelf.tableView.mj_header endRefreshing];
        }];
        [self.tableView.mj_header endRefreshingWithCompletionBlock:^{
            __strong id strongSelf = weakSelf;
            strongSelf.block();
        }];
    }
    return _tableView;
}
- (void)dealloc{
    NSLog(@"HotFixController dealloc");
}
@end
