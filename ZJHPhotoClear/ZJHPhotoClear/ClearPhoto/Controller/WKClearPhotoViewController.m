//
//  WKClearPhotoViewController.m
//  WuKongClearPhotoDemo
//
//  Created by ZhangJingHao2345 on 2018/3/8.
//  Copyright © 2018年 ZhangJingHao2345. All rights reserved.
//

#import "WKClearPhotoViewController.h"
#import "WKClearPhotoCell.h"
#import "WKClearPhotoManager.h"
#import "MBProgressHUD.h"
#import "WKSimilarPhotoViewController.h"
#import "WKThinPhotoViewController.h"

@interface WKClearPhotoViewController () <UITableViewDataSource,UITableViewDelegate,WKClearPhotoManagerDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray *dataArr;
@property (nonatomic, strong) WKClearPhotoManager *photoMgr;
@property (nonatomic, weak) MBProgressHUD *hud;

@end

@implementation WKClearPhotoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"照片清理";
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self loadPhotoData];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.photoMgr.notificationStatus == WKPhotoNotificationStatusNeed) {
        [self loadPhotoData];
        self.photoMgr.notificationStatus = WKPhotoNotificationStatusDefualt;
    }
}

- (void)loadPhotoData {
    if (self.hud) {
        return;
    }
    
    MBProgressHUD *hud = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:hud];
    hud.mode = MBProgressHUDModeDeterminate;
    hud.label.text = @"扫描照片中";
    hud.removeFromSuperViewOnHide = YES;
    [hud showAnimated:YES];
    
    __weak typeof(self) weakSelf = self;
    [self.photoMgr loadPhotoWithProcess:^(NSInteger current, NSInteger total) {
        hud.progress = (CGFloat)current / total;
    } completionHandler:^(BOOL success, NSError *error) {
        [hud hideAnimated:YES];
        [weakSelf configData];
    }];
}

- (void)configData {
    self.hud = nil;
    
    WKClearPhotoItem *item1 =
    [[WKClearPhotoItem alloc] initWithType:WKClearPhotoTypeSimilar
                                  dataDict:self.photoMgr.similarInfo];
    WKClearPhotoItem *item2 =
    [[WKClearPhotoItem alloc] initWithType:WKClearPhotoTypeScreenshots
                                  dataDict:self.photoMgr.screenshotsInfo];
    WKClearPhotoItem *item3 =
    [[WKClearPhotoItem alloc] initWithType:WKClearPhotoTypeThinPhoto
                                  dataDict:self.photoMgr.thinPhotoInfo];
    self.dataArr = @[item1, item2, item3];
    
    CGFloat headW = self.view.frame.size.width;
    CGFloat headH = 150;
    UILabel *headLab = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, headW, headH)];
    headLab.text = [NSString stringWithFormat:@"优化后可节约空间 %.2fMB", self.photoMgr.totalSaveSpace / 1024.0/1024.0];
    headLab.textAlignment = NSTextAlignmentCenter;
    self.tableView.tableHeaderView = headLab;
    
    [self.tableView reloadData];
}

#pragma mark - WKClearPhotoManagerDelegate

// 相册变动代理方法
- (void)clearPhotoLibraryDidChange {
    [self loadPhotoData];
}

#pragma mark - UITableViewDataSource,UITableViewDelegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataArr.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cell_Id = @"WKClearPhotoCell_id";
    WKClearPhotoCell *cell = [tableView dequeueReusableCellWithIdentifier:cell_Id];
    if (cell == nil) {
        cell = [[WKClearPhotoCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cell_Id];
    }
    
    WKClearPhotoItem *item = self.dataArr[indexPath.row];
    [cell bindWithMode:item];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    WKClearPhotoItem *item = self.dataArr[indexPath.row];
    if (!item.count) {
        return;
    }
    
    switch (item.type) {
        case WKClearPhotoTypeSimilar: {
            WKSimilarPhotoViewController *vc = [WKSimilarPhotoViewController new];
            vc.similarArr = self.photoMgr.similarArr;
            [self.navigationController pushViewController:vc animated:YES];
        }
            break;
        case WKClearPhotoTypeScreenshots: {
            WKSimilarPhotoViewController *vc = [WKSimilarPhotoViewController new];
            vc.similarArr = self.photoMgr.screenshotsArr;
            vc.isScreenshots = YES;
            [self.navigationController pushViewController:vc animated:YES];
        }
            break;
        case WKClearPhotoTypeThinPhoto: {
            WKThinPhotoViewController *vc = [WKThinPhotoViewController new];
            vc.thinPhotoArr = self.photoMgr.thinPhotoArr;
            vc.thinPhotoItem = item;
            [self.navigationController pushViewController:vc animated:YES];
        }
            break;
            
        default:
            break;
    }
}

#pragma mark - Getter

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
        _tableView.dataSource = self;
        _tableView.delegate = self;
        _tableView.rowHeight = 60;
        [self.view addSubview:_tableView];
        
        _tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _tableView.delaysContentTouches = NO;
        CGFloat h1 = [UIApplication sharedApplication].statusBarFrame.size.height;
        CGFloat h2 = self.navigationController.navigationBar.bounds.size.height;
        
        if ([UIDevice currentDevice].systemVersion.floatValue >= 11.0) {
            _tableView.estimatedRowHeight = 0;
            if ([UIScreen mainScreen].bounds.size.height == 812) {
                _tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
                _tableView.contentInset = UIEdgeInsetsMake(h1 + h2, 0, 0, 0);
                _tableView.scrollIndicatorInsets = UIEdgeInsetsMake(h1 + h2, 0, 0, 0);
            }
        } else {
            _tableView.contentInset = UIEdgeInsetsMake(h1 + h2, 0, 0, 0);
        }
    }
    
    return _tableView;
}

- (WKClearPhotoManager *)photoMgr {
    if (!_photoMgr) {
        _photoMgr = [WKClearPhotoManager shareManager];
        _photoMgr.delegate = self;
    }
    return _photoMgr;
}

@end
