//
//  WKPhotoInfoItem.h
//  WuKongClearPhotoDemo
//
//  Created by ZhangJingHao2345 on 2018/3/8.
//  Copyright © 2018年 ZhangJingHao2345. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>

@interface WKPhotoInfoItem : NSObject

@property (nonatomic, strong) PHAsset *asset;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) NSData *imageData;
@property (nonatomic, assign) NSUInteger imageSize;
@property (nonatomic, assign) BOOL isSelected;

- (instancetype)initWithDict:(NSDictionary *)dict;

@end
