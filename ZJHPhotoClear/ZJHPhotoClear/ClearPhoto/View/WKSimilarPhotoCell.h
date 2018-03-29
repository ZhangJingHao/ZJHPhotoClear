//
//  WKSimilarPhotoCell.h
//  WuKongClearPhotoDemo
//
//  Created by ZhangJingHao2345 on 2018/3/8.
//  Copyright © 2018年 ZhangJingHao2345. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WKPhotoInfoItem.h"

@interface WKSimilarPhotoCell : UICollectionViewCell

- (void)bindWithModel:(WKPhotoInfoItem *)model;

@end
