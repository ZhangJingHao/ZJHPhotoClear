//
//  WKSimilarPhotoCell.m
//  WuKongClearPhotoDemo
//
//  Created by ZhangJingHao2345 on 2018/3/8.
//  Copyright © 2018年 ZhangJingHao2345. All rights reserved.
//

#import "WKSimilarPhotoCell.h"

@interface WKSimilarPhotoCell ()

@property (nonatomic, weak) UIImageView *iconView;
@property (nonatomic, weak) UIButton *selectBtn;
@property (nonatomic, strong) WKPhotoInfoItem *item;

@end

@implementation WKSimilarPhotoCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUIWithFrame:frame];
    }
    return self;
}

- (void)setupUIWithFrame:(CGRect)frame {
    UIImageView *iconView = [[UIImageView alloc] initWithFrame:self.bounds];
    iconView.contentMode = UIViewContentModeScaleAspectFill;
    iconView.clipsToBounds = YES;
    [self addSubview:iconView];
    self.iconView = iconView;
    
    CGFloat selectWH = frame.size.width * 0.3;
    CGFloat selectX = frame.size.width - selectWH;
    UIButton *selectBtn = [[UIButton alloc] initWithFrame:CGRectMake(selectX, 0, selectWH, selectWH)];
    [self addSubview:selectBtn];
    self.selectBtn = selectBtn;
    [selectBtn setImage:[UIImage imageNamed:@"necessary_check_default"] forState:UIControlStateNormal];
    [selectBtn setImage:[UIImage imageNamed:@"necessary_check_selected"] forState:UIControlStateSelected];
    [selectBtn addTarget:self action:@selector(clickSelectBtn:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)bindWithModel:(WKPhotoInfoItem *)model {
    self.item = model;
    
    self.iconView.image = model.image;
    self.selectBtn.selected = model.isSelected;
}

- (void)clickSelectBtn:(UIButton *)btn {
    btn.selected = !btn.selected;
    self.item.isSelected = btn.selected;
}

@end
