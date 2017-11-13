//
//  ViewController.m
//  GPLoadingMoreViewDemo
//
//  Created by liuxj on 2017/11/13.
//  Copyright © 2017年 liuxj. All rights reserved.
//

#import "ViewController.h"
#import "GPLoadingMoreView.h"

static NSString *const kCellID  = @"kCellID";

@interface ViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *table;
@property (nonatomic, strong) NSMutableArray *datas;

@end

@implementation ViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    _table = [[UITableView alloc] init];
    _table.dataSource = self;
    _table.delegate = self;
    _table.rowHeight = 44;
    [_table registerClass:[UITableViewCell class] forCellReuseIdentifier:kCellID];
    _table.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
    [self.view addSubview:_table];
    
    __weak typeof(self) weakself = self;
    [_table addLoadMoreViewWithActionHandler:^{
        __strong typeof(weakself) self = weakself;
        [self loadMore];
    }];
    
}

- (void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
     [self.table triggerLoadMoreView];
}


- (void)loadMore {
    if (self.datas.count == 50) {
        [self.table endLoadingWithNoMoreDataText:@"更多商家入驻中，敬请期待~"];
    }else {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            for (NSInteger index = 0; index < 10; index ++) {
                [self.datas addObject:@(index)];
            }
            [self.table reloadData];
            [self.table endLoadingMore];
        });
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellID];
    cell.textLabel.text = [NSString stringWithFormat:@"-- %@ --",@(indexPath.row)];
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.datas.count;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.navigationController pushViewController:[UIViewController new] animated:YES];
}

- (NSMutableArray *)datas {
    if (!_datas) {
        _datas = @[].mutableCopy;
    }
    return _datas;
}




@end
