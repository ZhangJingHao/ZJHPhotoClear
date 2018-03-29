//
//  WKThinPhotoViewController.m
//  WuKongClearPhotoDemo
//
//  Created by ZhangJingHao2345 on 2018/3/8.
//  Copyright © 2018年 ZhangJingHao2345. All rights reserved.
//

#import "WKThinPhotoViewController.h"
#import "WKPhotoInfoItem.h"
#import "WKClearPhotoManager.h"
#import "MBProgressHUD.h"

@interface WKThinPhotoViewController ()

@property (nonatomic, weak) UIImageView *leftIconView;
@property (nonatomic, weak) UIImageView *rightIconView;
@property (nonatomic, strong) NSMutableArray *dataArr;
@property (nonatomic, assign) NSInteger currentIndex;
@property (nonatomic, strong) NSMutableArray *assetArr;
@property (nonatomic, weak) MBProgressHUD *hud;

@end

@implementation WKThinPhotoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"照片瘦身";
    self.view.backgroundColor = [UIColor whiteColor];

    [self setupUI];
    [self configData];
}

- (void)setupUI {
    NSArray *nameArr = @[@"优化前", @"优化后"];
    CGFloat distance = 15;
    CGFloat upX = 0;
    CGFloat upY = 100;
    CGFloat upW = (self.view.frame.size.width - 3 * distance) / 2;
    CGFloat upH = upW * 2;
    for (int i = 0; i < nameArr.count; i++) {
        upX = distance + (distance + upW) * i;
        UIView *upView = [[UIView alloc] initWithFrame:CGRectMake(upX, upY, upW, upH)];
        [self.view addSubview:upView];
        
        CGFloat labH = 50;
        UILabel *lab = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, upW, labH)];
        lab.textAlignment = NSTextAlignmentCenter;
        lab.text = nameArr[i];
        [upView addSubview:lab];
        
        UIImageView *iconView = [[UIImageView alloc] initWithFrame:CGRectMake(0, labH, upW, upH - labH)];
        iconView.contentMode = UIViewContentModeScaleAspectFit;
        iconView.backgroundColor = [UIColor lightGrayColor];
        [upView addSubview:iconView];
        if (i == 0) {
            self.leftIconView = iconView;
        } else {
            self.rightIconView = iconView;
        }
    }
    
    CGFloat tipY = upY + upH;
    CGFloat tipH = 100;
    CGFloat tipW = self.view.frame.size.width;
    UILabel *tipLab = [[UILabel alloc] initWithFrame:CGRectMake(0, tipY, tipW, tipH)];
    tipLab.text = [NSString stringWithFormat:@"%@ 可省 %@", self.thinPhotoItem.detail, self.thinPhotoItem.saveStr];
    tipLab.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:tipLab];
    
    CGFloat btnX = distance * 2;
    CGFloat btnW = self.view.frame.size.width - 2 * btnX;
    CGFloat btnH = 50;
    CGFloat btnY = self.view.frame.size.height - btnH - btnX;
    UIButton *optmizeBtn = [[UIButton alloc] initWithFrame:CGRectMake(btnX, btnY, btnW, btnH)];
    [optmizeBtn setTitle:@"立即优化" forState:UIControlStateNormal];
    optmizeBtn.backgroundColor = [UIColor orangeColor];
    [optmizeBtn addTarget:self action:@selector(clickOptimizeBtn) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:optmizeBtn];
}

- (void)configData {
    self.dataArr = [NSMutableArray arrayWithCapacity:self.thinPhotoArr.count];
    for (NSDictionary *dict in self.thinPhotoArr) {
        WKPhotoInfoItem *item = [[WKPhotoInfoItem alloc] initWithDict:dict];
        [self.dataArr addObject:item];
    }
    
    WKPhotoInfoItem *item = self.dataArr.firstObject;
//    [self testWithItem:item];
    
    [WKClearPhotoManager getOriginImageWithAsset:item.asset completionHandler:^(UIImage *result, NSDictionary *info) {
        
        NSData *data4 = UIImageJPEGRepresentation(result, 1);
        NSLog(@"JPEG data4 : %.2fMB", data4.length/1024.0/1024.0);
        
        self.leftIconView.image = result;
        [WKClearPhotoManager compressImageWithData:item.imageData
                                 completionHandler:^(UIImage *compressImg, NSUInteger compressSize) {
                                     self.rightIconView.image = compressImg;
                                 }];
    }];
}

#pragma mark - 保存图片

// 立即优化
- (void)clickOptimizeBtn {
    [WKClearPhotoManager shareManager].notificationStatus = WKPhotoNotificationStatusClose;
    self.currentIndex = 0;
    self.assetArr = [NSMutableArray array];
    
    MBProgressHUD *hud = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:hud];
    hud.mode = MBProgressHUDModeDeterminate;
    hud.label.text = @"压缩中,请稍后";
    hud.removeFromSuperViewOnHide = YES;
    [hud showAnimated:YES];
    self.hud = hud;
    
    [self getImageWithIndex:0];
}

- (void)getImageWithIndex:(NSInteger)index {
    self.currentIndex = index;
    self.hud.progress = (CGFloat)index / self.dataArr.count;
    NSLog(@"压缩中: %ld", index);
    if (index>=self.dataArr.count) {
        NSLog(@"***ZJH 压缩完成");
        self.hud.hidden = YES;
        
        [WKClearPhotoManager shareManager].notificationStatus = WKPhotoNotificationStatusNeed;
        [WKClearPhotoManager deleteAssets:self.assetArr
                        completionHandler:^(BOOL success, NSError *error) {
                            if (success) {
                                [WKClearPhotoManager tipWithMessage:@"恭喜，压缩完成！"];
                            } else {
                                NSLog(@"删除原图失败 ：%@", error);
                            }
                        }];
        return;
    }

    WKPhotoInfoItem *item = self.dataArr[index];
    [WKClearPhotoManager compressImageWithData:item.imageData
                             completionHandler:^(UIImage *compressImg, NSUInteger compresSize) {
                                 [self saveImage:compressImg];
                             }];
}

- (void)saveImage:(UIImage *)img {
    // 存储图片到"相机胶卷"
    UIImageWriteToSavedPhotosAlbum(img, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
}

// 成功保存图片到相册中, 必须调用此方法, 否则会报参数越界错误
- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo{
    if (error) {
        NSLog(@"保存失败");
    } else {
        WKPhotoInfoItem *item = self.dataArr[self.currentIndex];
        [self.assetArr addObject:item.asset];
    }
    [self getImageWithIndex:self.currentIndex+1];
}


// 获取原图data，转化为Image 大小不一致
- (void)testWithItem:(WKPhotoInfoItem *)item {
    NSLog(@"原图  data1 : %.2fMB", item.imageData.length/1024.0/1024.0);
    UIImage *img = [UIImage imageWithData:item.imageData];
    NSData *data2 = UIImageJPEGRepresentation(img, 1);
    NSLog(@"JPEG data2 : %.2fMB", data2.length/1024.0/1024.0);
    NSData *data3 = UIImagePNGRepresentation(img);
    NSLog(@"PNG  data3 : %.2fMB", data3.length/1024.0/1024.0);
}

@end
