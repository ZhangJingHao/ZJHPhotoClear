//
//  WKSimilarPhotoViewController.m
//  WuKongClearPhotoDemo
//
//  Created by ZhangJingHao2345 on 2018/3/8.
//  Copyright © 2018年 ZhangJingHao2345. All rights reserved.
//

#import "WKSimilarPhotoViewController.h"
#import "WKSimilarPhotoCell.h"
#import "WKSimilarPhotoHeadView.h"
#import "WKPhotoInfoItem.h"
#import "WKClearPhotoManager.h"
#import "MBProgressHUD.h"

@interface WKSimilarPhotoViewController () <UICollectionViewDelegate, UICollectionViewDataSource>

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) NSMutableArray *dataArr;

@end

@implementation WKSimilarPhotoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"清理相似照片";
    if (self.isScreenshots) {
        self.title = @"截屏图片";
    }

    [self configData];
    [self setupUI];
}

- (void)configData {
    [self.dataArr removeAllObjects];
    
    for (NSDictionary *dict in self.similarArr) {
        NSString *keyStr = dict.allKeys.lastObject;
        NSArray *arr = dict.allValues.lastObject;
        NSMutableArray *mutArr = [NSMutableArray arrayWithCapacity:arr.count];
        for (int i = 0; i < arr.count; i++) {
            NSDictionary *infoDict = arr[i];
            WKPhotoInfoItem *item = [[WKPhotoInfoItem alloc] initWithDict:infoDict];
            [mutArr addObject:item];
            if (i != 0) {
                item.isSelected = YES;
            }
        }

        NSDictionary *temDict = @{keyStr : mutArr};
        [self.dataArr addObject:temDict];
    }
    [self.collectionView reloadData];
}

- (void)setupUI {
    CGFloat btnH = 50;
    CGFloat btnY = self.view.frame.size.height - btnH;
    CGFloat btnW = self.view.frame.size.width;
    UIButton *deleteBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, btnY, btnW, btnH)];
    [deleteBtn setTitle:@"删除相似照片" forState:UIControlStateNormal];
    deleteBtn.backgroundColor = [UIColor redColor];
    [self.view addSubview:deleteBtn];
    [deleteBtn addTarget:self action:@selector(clickDeleteBtn) forControlEvents:UIControlEventTouchUpInside];
}

- (void)clickDeleteBtn {
    
    NSMutableArray *assetArr = [NSMutableArray array];
    NSMutableArray *temDataArr = [NSMutableArray array];
    
    for (NSDictionary *dict in self.dataArr) {
        NSArray *arr = dict.allValues.lastObject;
        NSMutableArray *mutArr = [NSMutableArray array];
        for (WKPhotoInfoItem *item in arr) {
            if (item.isSelected) {
                [assetArr addObject:item.asset];
            } else {
                [mutArr addObject:item];
            }
        }
        
        if ( (self.isScreenshots && mutArr.count>0) || (!self.isScreenshots && mutArr.count > 1) ) {
            NSDictionary *temDict = @{dict.allKeys.lastObject : mutArr};
            [temDataArr addObject:temDict];
        }
    }
    
    if (assetArr.count) {
        [WKClearPhotoManager shareManager].notificationStatus = WKPhotoNotificationStatusClose;
        [WKClearPhotoManager deleteAssets:assetArr
                        completionHandler:^(BOOL success, NSError *error) {
                            if (success) {
                                [self deleteSuccessWithTemDataArr:temDataArr];
                            }
                        }];
    }
}

- (void)deleteSuccessWithTemDataArr:(NSMutableArray *)temDataArr {
    self.dataArr = temDataArr;
    [self.collectionView reloadData];
    
    [WKClearPhotoManager tipWithMessage:@"删除成功"];
    [WKClearPhotoManager shareManager].notificationStatus = WKPhotoNotificationStatusNeed;

}

#pragma mark - UICollectionViewDataSource,UICollectionViewDelegate

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return self.dataArr.count;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    NSDictionary *dict = self.dataArr[section];
    NSArray *arr = dict.allValues.lastObject;
    return arr.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    WKSimilarPhotoCell *cell =
    [collectionView dequeueReusableCellWithReuseIdentifier:@"WKSimilarPhotoCell_id"
                                              forIndexPath:indexPath];
    
    NSDictionary *dict = self.dataArr[indexPath.section];
    NSArray *arr = dict.allValues.lastObject;
    [cell bindWithModel:arr[indexPath.row]];
    cell.backgroundColor = [UIColor yellowColor];
    
    return cell;
}

-(UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    if (kind == UICollectionElementKindSectionHeader) {
        WKSimilarPhotoHeadView *headerV =  [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"WKSimilarPhotoHeadView_id" forIndexPath:indexPath];
        NSDictionary *dict = self.dataArr[indexPath.section];
        [headerV bindWithModel:dict];
        return headerV;
    }
    
    return nil;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section
{//设置段头view大小
    return CGSizeMake(0, 40);
}

#pragma mark - 懒加载

- (UICollectionView *)collectionView {
    if (!_collectionView) {
        UICollectionViewFlowLayout *layout = [UICollectionViewFlowLayout new];
        CGFloat itemCount = 4;
        CGFloat distance = 8;
        CGFloat width = self.view.frame.size.width;
        CGFloat itemWH = (width - distance * (itemCount + 1)) / itemCount - 1;
        layout.itemSize = CGSizeMake(itemWH, itemWH);
        layout.sectionInset = UIEdgeInsetsMake(distance, distance, distance, distance);
        layout.minimumLineSpacing = distance;
        layout.minimumInteritemSpacing = distance;
        _collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds
                                             collectionViewLayout:layout];
        _collectionView.dataSource = self;
        _collectionView.delegate = self;
        [_collectionView registerClass:[WKSimilarPhotoCell class]
            forCellWithReuseIdentifier:@"WKSimilarPhotoCell_id"];
        [_collectionView registerClass:[WKSimilarPhotoHeadView class]
            forSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                   withReuseIdentifier:@"WKSimilarPhotoHeadView_id"];
        _collectionView.backgroundColor = [UIColor whiteColor];
        [self.view addSubview:_collectionView];
        
        _collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _collectionView.delaysContentTouches = NO;
        if ([UIDevice currentDevice].systemVersion.floatValue >= 11.0) {
            if ([UIScreen mainScreen].bounds.size.height == 812) {
                _collectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
                CGFloat h1 = [UIApplication sharedApplication].statusBarFrame.size.height;
                CGFloat h2 = self.navigationController.navigationBar.bounds.size.height;
                _collectionView.contentInset = UIEdgeInsetsMake(h1 + h2, 0, 0, 0);
                _collectionView.scrollIndicatorInsets = UIEdgeInsetsMake(h1 + h2, 0, 0, 0);
            }
        }
        UIEdgeInsets inset = _collectionView.contentInset;
        _collectionView.contentInset = UIEdgeInsetsMake(inset.top, inset.left, 50, inset.right);
        _collectionView.scrollIndicatorInsets = _collectionView.contentInset;
    }
    return _collectionView;
}

- (NSMutableArray *)dataArr {
    if (!_dataArr) {
        _dataArr = [NSMutableArray array];
    }
    return _dataArr;
}

@end
