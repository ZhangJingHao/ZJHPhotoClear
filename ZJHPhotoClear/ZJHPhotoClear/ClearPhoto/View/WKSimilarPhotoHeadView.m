//
//  WKSimilarPhotoHeadView.m
//  WuKongClearPhotoDemo
//
//  Created by ZhangJingHao2345 on 2018/3/8.
//  Copyright © 2018年 ZhangJingHao2345. All rights reserved.
//

#import "WKSimilarPhotoHeadView.h"

@interface WKSimilarPhotoHeadView()

@property (nonatomic, weak) UILabel *nameLab;
@property (nonatomic, weak) UIButton *selectBtn;

@end

@implementation WKSimilarPhotoHeadView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUIWithFrame:frame];
    }
    return self;
}

- (void)setupUIWithFrame:(CGRect)frame {
    CGFloat nameX = 15;
    CGFloat nameW = frame.size.width * 0.5;
    CGFloat nameH = frame.size.height;
    CGRect nameF = CGRectMake(nameX, 0, nameW, nameH);
    UILabel *nameLab = [[UILabel alloc] initWithFrame:nameF];
    [self addSubview:nameLab];
    self.nameLab = nameLab;
    
//    CGFloat btnW = 100;
//    CGFloat btnX = frame.size.width - btnW;
//    UIButton *selectBtn = [[UIButton alloc] initWithFrame:CGRectMake(btnX, 0, btnW, nameH)];
//    [selectBtn setTitle:@"删除所选" forState:UIControlStateNormal];
//    [selectBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
//    [self addSubview:selectBtn];
//    self.selectBtn = selectBtn;
}

- (void)bindWithModel:(NSDictionary *)model {
    self.nameLab.text = model.allKeys.lastObject;
    
}


@end
