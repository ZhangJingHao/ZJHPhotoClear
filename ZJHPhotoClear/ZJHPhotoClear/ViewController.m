//
//  ViewController.m
//  WuKongClearPhotoDemo
//
//  Created by ZhangJingHao2345 on 2018/3/8.
//  Copyright © 2018年 ZhangJingHao2345. All rights reserved.
//

#import "ViewController.h"
#import "WKClearPhotoViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self clickClearPhoto];
}

- (IBAction)clickClearPhoto {
    WKClearPhotoViewController *vc = [WKClearPhotoViewController new];
    [self.navigationController pushViewController:vc animated:YES];
}


@end

